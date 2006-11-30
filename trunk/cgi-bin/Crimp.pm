# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:        The CRIMP Team
# Project Leads:  Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                 Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:       http://crimp.sourceforge.net/

##################################################################################
# This library is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU Lesser General Public                     #
# License as published by the Free Software Foundation; either                   #
# version 2.1 of the License, or (at your option) any later version.             #
#                                                                                #
# This library is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU              #
# Lesser General Public License for more details.                                #
#                                                                                #
# You should have received a copy of the GNU Lesser General Public               #
# License along with this library; if not, write to the Free Software            #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA #
##################################################################################

package Crimp;

#constructor
sub new {
  my $class = shift;
  
  my $VER = '<!--build-date-->'; 
  my $ID = q$Id: Crimp.pm,v 2.17 2006-11-30 16:27:30 diddledan Exp $;
  my $version = (split(' ', $ID))[2];
  $version =~ s/,v\b//;
  $VER =~ s|<!--build-date-->|CVS $version|i if ($VER eq '<!--build-date-->');

  my $self = {
    version => $version,
    VER => $VER,
    id => $ID,
    PRINT_DEBUG => undef,
    PRINT_HEAD => undef,
    _IniCommands => undef,
    _RemoteHost => $ENV{'REMOTE_ADDR'},
    _ServerName =>  $ENV{'SERVER_NAME'},
    _ServerSoftware =>  $ENV{'SERVER_SOFTWARE'},
    _ServerProtocol => $ENV{'SERVER_PROTOCOL'},
    _UserAgent =>  $ENV{'HTTP_USER_AGENT'},
    _HttpRequest =>  $ENV{'REDIRECT_URL'},
    _HttpQuery =>  $ENV{'REDIRECT_QUERY_STRING'},
    _PostQuery => undef,
    _ContentType => 'text/html',
    _PageTitle => 'Powered By CRIMP',
    _ExitCode => '204',
    _ConfDebugMode => '',
    _DebugMode => 'off',
    _PageRead => '',
    _VarDirectory => '../cgi-bin/Crimp/var',
    _ErrorDirectory => '../cgi-bin/Crimp/errors',
    _HtmlDirectory => '../public_html',
    _CgiDirectory => '../cgi-bin',
    _RobotsMeta => 'index,follow',
    _KeywordsMeta => '',
    _DescriptionMeta => '',
    _DefaultHtml => '',
    _DefaultLang => 'eng',
    _DefaultProxy => '',
    _MenuDiv => '',
    _GetData => undef,
    _PostData => undef,
    _sendCookies => [],
    _receivedCookies => (),
    _ConfigMode => 'xml',
    _PluginHandles => undef,
    DisplayHtml => undef,
    Config => undef,
    FullConfig => undef,
  };
  
  bless $self, $class;
  
  $self->printdebug('CRIMP [Content Redirection Internet Management Program] (Debug View)',
                    '',
                    'Authors: The CRIMP Team',
                    'Project Leads:',
                    '&nbsp;&nbsp;&nbsp;Martin "Deadpan110" Guppy [deadpan110@users.sourceforge.net]',
                    '&nbsp;&nbsp;&nbsp;Daniel "Fremen" Llewellyn [diddledan@users.sourceforge.net]',
                    "Public Version: $self->{VER}",
                    "Internal Version: $self->{id}",
                    'http://crimp.sourceforge.net/');

  use CGI;

  eval {use CGI::Cookie;use Fcntl;use URI::Escape;};
  if ($@) {
    $self->errorPage('','500');
    $self->printdebug('Initialisation Failure','fail','Could not load all required modules:',"&nbsp;&nbsp;$@");
    return;
  }
  
  (%{$self->{_PostData}}, $self->{PostQuery}) = @{$self->parsePOSTed()};
  %{$self->{_GetData}} = $self->parseGETed();
  $self->{rceivedCookies} = $self->parseCookies();
  $self->{_HttpQuery} = join '', '?', $self->{_HttpQuery} if ($self->{_HttpQuery});
  
  $self->{_ServerProtocol} =~ s|^(http[s]?).*$|$1://|i;
  $self->{_ErrorDirectory} = '../cgi-bin/Crimp/errors';
  $self->{_DefaultLang} = 'eng';
  $self->{_DefaultHtml} = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type"/>
<title></title>
</head>
<body>
</body>
</html>';

  $self->printdebug(
    'System Variables',
    'pass',
    "ServerName: $self->{_ServerName}",
    "ServerSoftware: $self->{_ServerSoftware}"
  );

  $self->printdebug(
    'User Variables',
    'pass',
    "RemoteHost: $self->{_RemoteHost}",
    "UserAgent: $self->{_UserAgent}",
    "HttpRequest: $self->{_HttpRequest}",
    "HttpQuery: $self->{_HttpQuery}",
    "PostQuery: $self->{_PostQuery}"
  );
  
  $self->loadConfig();
  $self->applyConfig();

  my @plugins = $self->parsePlugins();

  #move DocumentTemplate to the end so that it is always called last (nasty hack I know)
  push @plugins, 'DocumentTemplate' if (@plugins = grep !/DocumentTemplate/, @plugins);
  #move MenuButtons to the end so that it is always called After DocumentTemplate
  #(Following Fremen's nasty hack)
  push @plugins, 'ButtonBar' if (@plugins = grep !/ButtonBar/, @plugins);

  %{$self->{_PluginHandles}} = $self->loadPlugins($self, 'Crimp', @plugins);

  @{$self->{_IniCommands}} = @plugins;

  return $self;
}

sub sendDocument {
  my $self = shift;
  
  #This is where we finish the document or file
  $self->ExitCode('200') if ($self->ExitCode eq '204');
  $self->ContentType('text/html') if ($self->ContentType eq '');

  &printdebug('Crimp Exit','pass',
    "RobotsMeta: $self->{_RobotsMeta}",
    "ExitCode: $self->{ExitCode}"
  );
  
  print CGI::header($self->ContentType,$self->ExitCode,$self->{_sendCookies});

  if ($self->{_DebugMode} eq 'on' && $self->{Config}->{$self->userConfig}->{DebugMode} ne 'off') {
    my $PRINT_DEBUG = join '','<div name="crimpDebugContainer" id="crimpDebugContainer"><div name="crimpDebug" id="crimpDebug">','<table class="crimpDebug">', $self->{PRINT_DEBUG}, "</table></div><div id='closeDebugBtn'><a href='#' onClick='hideDebug()'><img src='/crimp_assets/pics/close.gif' style='border: 0;' alt='close' title='close debug view' /></a></div></div>\n<script type='text/javascript'><!--\ndebugInit();\n//--></script>\n";
    $PRINT_DEBUG = "$PRINT_DEBUG<script type='text/javascript'><!--\nshowDebug();\n//--></script>\n" if ($self->queryParam('debug') eq 'on');
    $self->{DisplayHtml} =~ s|(</body>)|$PRINT_DEBUG$1|i;
  }

  $self->{DisplayHtml} =~ s|(<body>)|$1$self->{_MenuDiv}\n|i;
  $self->{DisplayHtml} =~ s|(</head>)|\n$self->{PRINT_HEAD}$1|i;

  ####################################################################
  ## CRIMP Cheat codes ##
  #######################
  $self->{DisplayHtml} =~ s/<!--VERSION-->/$self->{VER}/gi;
	my $hostname = `hostname`;
	$self->{DisplayHtml} =~ s/<!--HOSTNAME-->/$hostname/gi;
	$self->{DisplayHtml} =~ s/<!--UIDGID-->/[UID: $<; GID: $(]/gi;

  ####################################################################

  print $self->{DisplayHtml};
}

sub execute {
  my $self = shift;
  
  ##################
  ## Main Routine ##
  ##################

  #check requested versus config

  #start with requested and work backwards to root until match found
  #ie /home/news/index.html
  #   /home/news
  #   /home

  @HttpRequest = split('/',$self->{_HttpRequest});
  my $tempstr = '';
  foreach (@HttpRequest) {
    if ($_ ne '') {
      $tempstr = join '/', $tempstr, $_;
    }

    if ($self->{Config}->{$tempstr}) {
      $self->userConfig($tempstr);
    }
  }

  $self->userConfig('/') if ($self->userConfig eq '');

  $self->printdebug(
    '\'crimp.ini\' Variables',
    'pass',
    'UserConfig: '.$self->userConfig,
  );

  # RobotsMeta
  $self->{_RobotsMeta} = $self->Config('RobotsMeta') if ($self->Config('RobotsMeta'));
  # KeywordsMeta
  $self->{_KeywordsMeta} = $self->Config('KeywordsMeta') if ($self->Config('KeywordsMeta'));
  # DescriptionMeta
  $self->{_DescriptionMeta} = $self->Config('DescriptionMeta') if ($self->Config('DescriptionMeta'));
  # PageRead
  $self->{_PageRead} = $self->Config('PageRead') if ($self->Config('PageRead'));

  ####################################################################
  ## call the builtins in order ##
  ################################

  if ($self->{_PageRead} ne '') {
    $self->{DisplayHtml} = $self->PageRead($self->{_PageRead});
  }

  ####################################################################
  ## call the plugins in order ##
  ###############################

  my %executedCommands = {};
  $self->{skipRemainingPlugins} = 0;

  my $pluginname;
  foreach (split ',', $self->{Config}->{$self->userConfig}->{PluginOrder}) {
    $pluginname = join '::','Crimp',$_;
    $self->executePlugin($_, $self->{_PluginHandles}->{$pluginname}) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++) || ($self->Config($_, 'switch') eq 'off'));
  }
  foreach (split ',', $self->{Config}->{_}->{PluginOrder}) {
    $pluginname = join '::','Crimp',$_;
    $self->executePlugin($_, $self->{_PluginHandles}->{$pluginname}) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++) || ($self->Config($_, 'switch') eq 'off'));
  }
  foreach (@{$self->{_IniCommands}}) {
    $pluginname = join '::','Crimp',$_;
    $self->executePlugin($_, $self->{_PluginHandles}->{$pluginname}) if (($self->Config($_, 'switch') ne 'off') && (($_ eq 'DocumentTemplate') || (!($self->{skipRemainingPlugins} || $executedCommands{$_}++))));
  }

  #add the extra CRIMP-specific HTML headers
  $self->addHeaderContent(join('','<meta name="generator" content="CRIMP ',$self->{version},' Build ', $self->{VER},'" />'));
  $self->addHeaderContent(join('','<meta name="robots" content="',$self->{_RobotsMeta},'" />'));
  $self->addHeaderContent(join('','<meta name="keywords" content="',$self->{_KeywordsMeta},'" />')) if ($self->{_KeywordsMeta} ne '');
  $self->addHeaderContent(join('','<meta name="description" content="',$self->{_DescriptionMeta},'" />')) if ($self->{_DescriptionMeta} ne '');
  $self->addHeaderContent('<link rel="stylesheet" type="text/css" href="/crimp_assets/debug.css" />');
  $self->addHeaderContent('<script type="text/javascript" src="/crimp_assets/js/prototype/prototype.js"></script>');
  $self->addHeaderContent('<script type="text/javascript" src="/crimp_assets/js/moo/moo.fx.js"></script>');
  $self->addHeaderContent('<script type="text/javascript" src="/crimp_assets/js/moo/moo.fx.pack.js"></script>');
  $self->addHeaderContent('<script type="text/javascript" src="/crimp_assets/js/debug.js"></script>');

  #############
  ## The End ##
  #############
}

###### HELPER ROUTINES ######
sub redirectTo {
  my ($self, $url) = @_;
  return if not defined $url;
  $self->printdebug('','pass',"redirecting to $url");
  print CGI::redirect($url);
}

sub stripHtmlHeaderFooter {
	my $self = shift;
	my $html = shift;

	#parse headers storing the title of the page
	$html =~ m|<title>(.*?)</title>|si;
	my $title = $1;
	#remove everything down to <body>
	$html =~ s|.*?<body.*?>||si;
	#remove everything after </body>
	$html =~ s|</body>.*||si;
	return ($title, $html);
}

sub PageTitle {
  my ($self, $pt, $override) = @_;
  if (defined $pt) {
    if (defined $override) {
      $self->{_PageTitle} = $pt;
    } else {
      my $seperator = $self->Config('TitleSeperator') || ' - ';
      if ($self->Config('TitleOrder') eq 'forward') {
        $self->{_PageTitle} = $self->{_PageTitle}.$seperator.$pt;
      } else {
        $self->{_PageTitle} = $pt.$seperator.$self->{_PageTitle};
      }
    }
  }
  return $self->{_PageTitle};
}

sub errorPage {
	my ($self, $plugin, $errCode) = @_;
	$plugin &&= "-$plugin";
	$errCode ||= '404';

	my @errFiles = (
		"$self->{_ErrorDirectory}/$self->{_DefaultLang}/$errCode$plugin.html",
		"$self->{_ErrorDirectory}/$errCode$plugin.html",
		"$self->{_ErrorDirectory}/$self->{_DefaultLang}/$errCode.html",
		"$self->{_ErrorDirectory}/$errCode.html",
	);

	for (@errFiles) {
		if (-e $_) {
			my $content = $self->PageRead($_);
			my $title;
			($title, $content) = $self->stripHtmlHeaderFooter($content);
			$self->{DisplayHtml} = $content;
			$self->PageTitle($title);
			$self->ExitCode($errCode);
			return;
		}
	}
}

sub DefaultProxy {
  my ($self, $dp) = @_;
  $self->{_DefaultProxy} = $dp if defined $dp;
  return $self->{_DefaultProxy};
}

sub ErrorDirectory {
  my ($self, $ed) = @_;
  $self->{_ErrorDirectory} = $ed if defined $ed;
  return $self->{_ErrorDirectory};
}

sub CgiDirectory {
  my ($self, $cd) = @_;
  $self->{_CgiDirectory} = $cd if defined $cd;
  return $self->{_CgiDirectory};
}

sub VarDirectory {
  my ($self, $vd) = @_;
  $self->{_VarDirectory} = $vd if defined $vd;
  return $self->{_VarDirectory};
}

sub HtmlDirectory {
  my ($self, $hd) = @_;
  $self->{_HtmlDirectory} = $hd if defined $hd;
  return $self->{_HtmlDirectory};
}

sub HttpRequest {
  my $self = shift;
  return $self->{_HttpRequest};
}

sub ContentType {
  my ($self, $ct) = @_;
  $self->{_ContentType} = $ct if defined $ct;
  return $self->{_ContentType};
}

sub ExitCode {
  my ($self, $ec) = shift;
  $self->{_ExitCode} = $ec;
  return $self->{_ExitCode};
}

sub addCookie {
  my ($self, $cookie) = @_;
  return if not defined $cookie;
  push @{$self->{_sendCookies}}, $cookie;
  $self->printdebug('','pass','Adding Cookie')
}

sub getCookie {
	my ($self, $cookiename) = @_;
	return $self->{_receivedCookies}->{$cookiename};
}

sub userConfig {
  my ($self, $userConfig) = @_;
  $self->{_UserConfig} = $userConfig if defined $userConfig;
  return $self->{_UserConfig};
}

sub queryParam {
  #return the query parameter requested, favouring POST
  my ($self, $parameter) = @_;
  
  return $self->{_PostData}->{$parameter} if $self->{_PostData}->{$parameter};
  return $self->{_GetData}->{$parameter} if $self->{_GetData}->{$parameter};
  return undef;
}

sub Config {
	#return the configuration for the specified key from the crimp.ini file
	my ($self, $plugin, $key, @base) = @_;
	$key ||= 'value';

	if ($self->{_ConfigMode} eq 'ini') {
		return $self->{Config}->{$self->userConfig}->{$key} if $self->{Config}->{$self->userConfig}->{$key};
		return $self->{Config}->{_}->{$key} if $self->{Config}->{_}->{$key};
	}
	if (@base) {
		foreach(@base) {
			return $_->{plugin}->{$plugin}->{$key} if $_->{plugin}->{$plugin}->{$key};
			return $_->{$plugin} if $_->{$plugin};
		}
	}
	return $self->{Config}->{$self->userConfig}->{plugin}->{$plugin}->{$key} if $self->{Config}->{$self->userConfig}->{plugin}->{$plugin}->{$key};
	return $self->{Config}->{$self->userConfig}->{$plugin} if $self->{Config}->{$self->userConfig}->{$plugin};
	return $self->{Config}->{_}->{plugin}->{$plugin}->{$key} if $self->{Config}->{_}->{plugin}->{$plugin}->{$key};
	return $self->{Config}->{_}->{$plugin} if $self->{Config}->{_}->{$plugin};
	return $self->{FullConfig}->{$key} if $self->{FullConfig}->{$key};
	return undef;
}

sub addHeaderContent {
	my $self = shift;
	my $new_header = shift;
	$self->{PRINT_HEAD} = join '',$self->{PRINT_HEAD},$new_header,"\n";
}

sub addPageContent {
	my $self = shift;
  
	my $PageContent = shift;
	my $PageLocation = shift; #(top / bottom / null = bottom)
	my $pagehtml = '';

	$self->{DisplayHtml} = $self->{_DefaultHtml} if not defined $self->{DisplayHtml};

	if (($PageLocation eq 'top') && ($self->{DisplayHtml} =~ m/<!--startPageContent-->/)) {
		$self->printdebug('','','Adding PageContent (top)');
		$self->{DisplayHtml} =~ s|(<!--startPageContent-->)|$1\n$PageContent\n\n|;
	} elsif ($self->{DisplayHtml} =~ m/(<!--endPageContent-->)/) {
		$self->printdebug('','',"Adding PageContent");
		$pagehtml = join("\n",'<br />',$PageContent,'<!--endPageContent-->');
		$self->{DisplayHtml} =~ s|(<!--endPageContent-->)|<br />\n$PageContent\n$1|;
	} else {
		$self->printdebug('','',"Creating PageContent");
		$pagehtml = join("\n","\n",
			'<div id="crimpPageContent">',
			'<!--startPageContent-->',
			$PageContent,
			'<!--endPageContent-->',
			"</div>\n");
		$self->{DisplayHtml} =~ s/(<body>)/$1$pagehtml/i;
	}
	return 1;
}

sub addMenuContent {
	my $self = shift;
  
	my $MenuContent = shift;
	my $MenuLocation = shift; #(top / bottom / null = bottom)
	my $menuhtml = '';
	if (!$self->{DisplayHtml}){
		$self->printdebug('','warn',"Cannot add MenuContent to an empty page");
		return 1;
	}

	if (($MenuLocation eq 'top') && ($self->{DisplayHtml} =~ m/<!--startMenuContent-->/)) {
		$self->printdebug('','','Adding MenuContent (top)');
		$self->{DisplayHtml} =~ s|(<!--startMenuContent-->)|$1\n$menuhtml\n<br />\n|;
	} elsif ($self->{DisplayHtml} =~ m/(<!--endMenuContent-->)/){
		$self->printdebug('','','Adding MenuContent (bottom)');
		$self->{DisplayHtml} =~ s|(<!--endMenuContent-->)|<br />\n$MenuContent\n$1|;
	} else {
		$self->printdebug('','',"Creating MenuContent");
		$menuhtml = join("\n","\n",
			'<div id="crimpMenuContent">',
			'<!--startMenuContent-->',
			$MenuContent,
			'<!--endMenuContent-->',
			"</div>\n");	
		$self->{DisplayHtml} =~ s/<body>/<body>$menuhtml/i;
	}
	return 1;
}

###### END HELPER ROUTINES ######

sub applyConfig {
  my $self = shift;
  
  #switch to debug mode if set in crimp.ini
  $self->{_ConfDebugMode} = $self->{Config}->{_}->{DebugMode};
  if ($self->{_DebugMode} ne 'on') {
    if (($self->{Config}->{_}->{DebugMode} eq 'page') && ($self->queryParam('debug') eq 'on')) {
      $self->{_DebugMode} = 'on';
    } else {
      $self->{_DebugMode} = $self->{Config}->{_}->{DebugMode};
    }
  }
  
  $self->ErrorDirectory($self->Config('ErrorDirectory')) if $self->Config('ErrorDirectory');
  $self->HtmlDirectory($self->Config('HtmlDirectory')) if $self->Config('HtmlDirectory');
  $self->CgiDirectory($self->Config('CgiDirectory')) if $self->Config('CgiDirectory');
  $self->DefaultProxy($self->Config('DefaultProxy')) if $self->Config('DefaultProxy');
  $self->PageTitle($self->Config('SiteTitle'), 1) if $self->Config('SiteTitle');
}

sub loadConfig {
	my $self = shift;

	if (-e 'crimp.xml') {
		eval {use XML::Simple};
		$self->printdebug('CRIMP Configuration', 'fail', 'XML::Simple module error', '&nbsp;&nbsp;'.$@) if ($@);
		my $xmlConfig = new XML::Simple(ForceArray => 1, ContentKey => 'value');
		eval {$self->{FullConfig} = $xmlConfig->XMLin('crimp.xml')};
		$self->printdebug('CRIMP Configuration', 'fail', 'Could not parse configuration file:', '&nbsp;&nbsp;'.$@) if ($@);
		$self->{Config} = $self->{FullConfig}->{section};
		$self->{_ConfigMode} = 'xml';
		return;
	}
	if (-e 'crimp.ini') {
		eval {use Config::Tiny};
		my $iniConfig = Config::Tiny->new();
		$self->{Config} = $iniConfig->read('crimp.ini');
		$self->{_ConfigMode} = 'ini';
		return;
	}

	$self->errorPage('','500');
	$self->printdebug('Configuration Failure','fail','Check for existence of either crimp.ini or crimp.xml file in the ../cgi-bin/');
}

sub beep {
  my $self = shift;

	($beep[4],$beep[3],$beep[2],$beep[1]) = split('.',$ENV{'SERVER_ADDR'});
	($beep[5],$beep[6],$beep[7],$beep[8]) = split('.',$self->{_RemoteHost});

	for ($i=1;$i<=8;$i++){
		$note =($beep[$i]+25)*10;
		$tune = "$tune -f $note -l 100 ";
		if ($i < 8){$tune = "$tune -n ";}
	}
  
	return `beep $tune`;
}

sub parsePlugins {
  my $self = shift;
  my $module = shift;

  $module ||= 'Crimp';
  my $dir = $module;
  $dir =~ s|::|/|g;
  
  opendir(DIR, "$dir") or $self->printdebug("$module Plugins Dir", 'fail', "Could not open the plugins dir for reading $!");
  rewinddir(DIR);
  my @plugins = readdir(DIR);
  closedir(DIR);

  my @inicmds;
  foreach (@plugins) {
    # is the file we found a 'dot' file (.something - meaning hidden)?
    # if not, check it ends in '.pm'
    if ( ( !( $_ =~ m/^\.+/ ) ) && ( $_ =~ m/\.pm$/ ) ) {
      #remove the extension
      $_ =~ s/\.pm$//;
      #add it to the list
      push @inicmds, $_;
    }
  }

  if ( ! @inicmds ) {
	$level = 'warn';
	$level = 'fail' if ( $module eq 'Crimp' );
	$self->printdebug("$module Plugins", $level, 'There appear to be no plugins in the plugin directory.');
  }
  else {
    # print Available plugins to debug (so many per line)
    my $inicount = 0;
    foreach (@inicmds) {
      if ($inicount == 0) {
        $iniout = $_;
      } else {
        if ($inicount % 7 == 0) {
          $iniout = join('<br/>&nbsp;&nbsp;&nbsp;&nbsp;',$iniout,$_);
        } else {
          $iniout = join(',',$iniout,$_);
        }
      }
      $inicount++;
    }
    $self->printdebug("Available Plugins ($module)", 'pass', $iniout);
  }
  return @inicmds;
}

sub parseCookies {
	my $self = shift;

	my %cookies = fetch CGI::Cookie();
	my @keys = keys %cookies;
	foreach (@keys) {
		my $key = $_;
		my $value = $cookies{$key};
		$key =~ s/([^\\])\+/$1 /g;
		$key = uri_unescape($key);
		
		$value =~ s/([^\\])\+/$1 /g;
		$value = uri_unescape($value);
		my $junk;
		($value, $junk) = split(';', $value);
		$self->{_receivedCookies}->{$key} = $value;
	}
	my @newkeys = keys %{$self->{_receivedCookies}};
	my $n = $#newkeys + 1;
	$self->printdebug('Cookie Initialisation','pass',"Found $n cookies", 'Cookie Names:', '&nbsp;&nbsp;'.join(",\n&nbsp;&nbsp;", @newkeys));
}

sub parseGETed {
  my $self = shift;
  
  my @TempArray = split /&/, $self->{_HttpQuery};
  my %GetQuery;
  my $n = 0;
  foreach (@TempArray) {
    my ($name, $value) = split /=/;
    $name =~ s/([^\\])\+/$1 /g;
    $name = uri_unescape($name);
    $value =~ s/([^\\])\+/$1 /g;
    $value = uri_unescape($value);
    $GetQuery{$name} = $value;
    $n++;
  }
  
  $self->printdebug('GET Query Initialisation', 'pass', "Found $n parameters");
  return %GetQuery;
}

sub parsePOSTed {
  my $self = shift;
  
  read(STDIN, $PostQueryString, $ENV{'CONTENT_LENGTH'});
  my @TempArray = split /&/, $PostQueryString;
  my %PostQuery;
  my $n = 0;
  foreach my $item (@TempArray) {
    my ($name, $value) = split /=/, $item;
    $name =~ s/([^\\])\+/$1 /g;
    $name = uri_unescape($name);
    $value =~ s/([^\\])\+/$1 /g;
    $value = uri_unescape($value);
    $PostQuery{$name} = $value;
    $n++;
  }
  
  $self->printdebug('POSTed Query Initialisation','pass',"Found $n parameters");
  return [%PostQuery, $PostQueryString];
}

####################################################################

sub loadPlugins {
	my $self = shift;
	my $passmeon = shift;
	my $moduleName = shift;
	$moduleName ||= 'Crimp';
	my @plugins = @_;

	my $count = $#plugins + 1;
	$self->printdebug("Module Initialisation ($moduleName)",'',"Preloading $count plugins");
	my %handles;
	for (@plugins) {
		my $pluginname = join '::',$moduleName,$_;
		eval "use $pluginname;";
		if ($@) { $self->printdebug('','warn',"&nbsp;&nbsp;Failed loading '$pluginname' plugin:","&nbsp;&nbsp;&nbsp;&nbsp;$@"); next; }
		eval {$handles{$pluginname} = $pluginname->new($passmeon);};
		if ($@) { $self->printdebug('','warn',"&nbsp;&nbsp;Failed Loading '$pluginname' plugin:","&nbsp;&nbsp;&nbsp;&nbsp;$@"); next; }
		$self->printdebug('','pass',"&nbsp;&nbsp;Successfully loaded '$pluginname' plugin");
	}
	return %handles;
}

####################################################################
sub executePlugin {
	my $self = shift;
	my $plugin = shift;
	my $handle = shift;
	my @configBases = @_;

	if ($self->Config($plugin, undef, @configBases) || $self->Config($plugin, 'switch', @configBases) eq 'on') {
		$self->printdebug('Executing Plugin','',"<b>($plugin)</b>");
		$self->{$plugin} = $self->Config($plugin, undef, @configBases);

		eval { $handle->execute() };
		$self->printdebug('', 'warn', 'Plugin failed to execute:', "&nbsp;&nbsp;$@") if ($@);
		return;
	}
}

####################################################################
sub printdebug {
	my $self = shift;
	my $mssge = shift;
	my $stats = shift;
	my $solut = '';
	my $logger = '';
	my $exit = 0;
	
	while (my $extra = shift) {
		if ($solut eq '' && $mssge eq '') { $solut = "&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>"; }
		else { $solut = "$solut<br/>&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>"; }
		$logger = join ', ',$logger,$extra;
	}
	
	if ($stats eq 'pass') { $stats='[<span style="color: #0f0;">PASS</span>]' }
	if ($stats eq 'warn') { $stats='[<span style="color: #fc3;">WARN</span>]' }
	if ($stats eq 'fail') { $stats='[<span style="color: #f00;">FAIL</span>]'; $exit = 1;}
	
	if (($solut ne '') && ($mssge ne '')) { $mssge="<span style='color: #ccc;'><b>&#8226;</b> $mssge $solut</span>"; }
	if ($mssge eq '') { $mssge = $solut; }
	$self->{PRINT_DEBUG} = join '', $self->{PRINT_DEBUG},'<tr><td align="left" valign="top" class="crimpDebugMsg"><pre class="crimpDebug">',$mssge,'</pre></td><td align="right" valign="bottom" class="crimpDebugStatus"><pre class="crimpDebug"><span style="color: #fff;">',$stats,'</span></pre></td></tr>';
	
	if ($exit) {
		#Call Multi lang 500 - Server Error Page
		print CGI::header('text/html', 500);
		my $FAIL_DEBUG = join '','<div name="crimpDebug" id="crimpDebug">','<table width="100%" border="0" cellpadding="0" cellspacing="0" bgcolor="#000000">', $self->{PRINT_DEBUG}, "</table></div>\n";
		$self->errorPage('','500');
		#readd header and footer
		$self->{DisplayHtml} = "<html><head><title></title></head><body>$self->{DisplayHtml}</body></html>";
		$self->{DisplayHtml} =~ s|(</body>)|$FAIL_DEBUG$1|i;
		print $self->{DisplayHtml};
		exit 1;
	}
}

####################################################################
sub PageRead {
  my $self = shift;
  my $filename = shift;
  $self->printdebug('','',
                    '(<b>(PageRead - BuiltIn Module)</b>',
                    "&nbsp;&nbsp;File: $filename");

  if ( -f $filename ) {
    sysopen (FILE,$filename,O_RDONLY) || $self->printdebug('', 'fail', 'Couldnt open file for reading', "file: $filename", "error: $!");
    @FileRead=<FILE>;
    close(FILE);
    $self->printdebug('','pass',"Returning content from $filename"); 
    return "@FileRead";
  }

  $filename = join '/', $self->{_ErrorDirectory}, '404.html';
  $self->printdebug('', 'warn', "&nbsp;&nbsp;File <$filename> does not exist",
                    "&nbsp;&nbsp;&nbsp;&nbsp;Using $self->{_ErrorDirectory}/404.html instead");
  $self->ExitCode('404');

  $newhtml = <<ENDEOF;
<h1>404 - Page Not Found</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
ENDEOF

  $FileRead = $self->{_DefaultHtml};
  $FileRead =~ s/(<body>)/$1$newhtml/i;
  $FileRead =~ s/(<title>)/${1}404 - Page Not Found/i;
  return $FileRead;
}

# Garbage Collector for lock files used by FileWrite
sub lockFileGC {
	my $self = shift;
	my $lockfile = shift;
	
	my $timeout = 60; #seconds
	if ($@) { $self->printdebug('','warn','Lock File Garbage Collection Failed.',$@); }
	
	my $FileDate = (stat($lockfile))[9];
	if ($FileDate > 0) {
		my $now = time();
		my $diff = $now - $FileDate;
		if ($diff > $timeout) { $self->printdebug('','pass',"Lock File $lockfile expunged ($now - $FileDate = $diff ( > $timeout ))"); unlink($lockfile); }
	}
}

####################################################################
sub FileRead {
  my $self = shift;
	my $filename=shift;
	my $entry=shift;
	my $string=shift;
	my $fileopen = join '/',$self->VarDirectory,$filename;

	$self->printdebug('','',"FileRead: [$filename] $entry");

	if ( -f $fileopen ) {
		sysopen (FILE,$fileopen,O_RDONLY) || $self->printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
		@FileRead=<FILE>;
		close(FILE);
			
		if (@FileRead) {
			foreach (@FileRead) {
				chop($_) if $_ =~ /\n$/;
				($FileEntry,$FileString) = split(/\|\|/,$_);				
				return($FileString) if ($FileEntry eq $entry);
			}
		}
	}
	return ($self->FileWrite($filename,$entry,$string));
}

####################################################################
sub FileWrite {
  my $self = shift;
	my $filename=shift;
	my $entry=shift;
	my $string=shift;
  my $try = shift;
	my $filelock = join '/',$self->VarDirectory,'lock',$filename;
	$self->lockFileGC($filelock);
	my $fileopen = join '/',$self->VarDirectory,$filename;
	
	sysopen(LOCKED,$filelock, O_WRONLY | O_EXCL | O_CREAT) or return $self->RetryWait($filename,$entry,$string,$try||0);
  $self->printdebug('','',"FileWrite: [$filename] $entry");#Keep on one line
	if ( -f $fileopen ) {
		sysopen (FILE,$fileopen,O_RDONLY) || $self->printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
		@FileRead=<FILE>;
		close(FILE);
		
		if (@FileRead) {
      my $flag=0;
			foreach $line (@FileRead) {
				chop($line) if $line =~ /\n$/;
				($FileEntry,$FileString) = split(/\|\|/,$line);
				
				if ($FileEntry eq $entry) {
					print LOCKED "$entry||$string\n";
					$flag=1;
				} else {
					print LOCKED "$FileEntry||$FileString\n";
				}
			}
      print LOCKED "$entry||$string\n" if($flag == 0);
		}
	} else {
		print LOCKED "$entry||$string\n";
	}
	
	close(LOCKED);
	if (!rename($filelock, $fileopen)) {
    $self->printdebug('','fail','FileWrite: cant rename:'.$!);
    return 0;
  }
	
	return($string);
}

####################################################################
sub RetryWait {
  my $self = shift;
  my $filename=shift;
	my $entry=shift;
	my $string=shift;
  my $tries = shift;

	if ($tries > 5) {
		$self->ExitCode('500');
		$self->printdebug('','warn',"File lock in place on $filename. Write aborted.");
		return 0;
	}

	if ($tries != 0) { sleep 1; }
	$tries++;
	return $self->FileWrite($filename,$entry,$string,$tries);
}

#return a true value to indicate successful loading
1;

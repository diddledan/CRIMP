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

use CGI qw(:standard);
use Config::Tiny;
use Fcntl;
use URI::Escape;

#constructor
sub new {
  my $class = shift;
  
  my $VER = '<!--build-date-->'; 
  my $ID = q$Id: Crimp.pm,v 2.8 2006-07-15 16:58:19 diddledan Exp $;
  my $version = (split(' ', $ID))[2];
  $version =~ s/,v\b//;
  $VER =~ s|<!--build-date-->|CVS $version|i if ($VER eq '<!--build-date-->');
  
  my $self = {
    version => $version,
    VER => $VER,
    id => $ID,
    PRINT_DEBUG => undef,
    PRINT_HEAD => undef,
    _PostQuery => undef,
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
    _cookies => [],
    DisplayHtml => undef,
    Config => undef,
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
  
  (%{$self->{_PostData}}, $self->{PostQuery}) = @{$self->parsePOSTed()};
  %{$self->{_GetData}} = $self->parseGETed();
  $self->{_HttpQuery} = join '', '?', $self->{_HttpQuery} if ($self->{_HttpQuery});
  
  @{$self->{_IniCommands}} = $self->parsePlugins();
  
  $self->{_ServerProtocol} =~ s|^(http[s]?).*$|\1://|i;
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
  
  print header($self->ContentType,$self->ExitCode,$self->{_cookies});

  if ($self->{_DebugMode} eq 'on') {
    my $PRINT_DEBUG = join '','<div name="crimpDebugContainer" id="crimpDebugContainer"><div name="crimpDebug" id="crimpDebug">','<table class="crimpDebug">', $self->{PRINT_DEBUG}, "</table></div><div id='closeDebugBtn'><a href='#' onClick='hideDebug()'><img src='/crimp_assets/pics/close.gif' style='border: 0;' alt='close' title='close debug view' /></a></div></div>\n<script type='text/javascript'><!--\ndebugInit();\n//--></script>\n";
    $PRINT_DEBUG = "$PRINT_DEBUG<script type='text/javascript'><!--\nshowDebug();\n//--></script>\n" if ($self->queryParam('debug') eq 'on');
    $self->{DisplayHtml} =~ s|(</body>)|$PRINT_DEBUG\1|i;
  }

  $self->{DisplayHtml} =~ s|(<body>)|\1$self->{_MenuDiv}\n|i;
  $self->{DisplayHtml} =~ s|(</head>)|\n$self->{PRINT_HEAD}\1|i;

  ####################################################################
  ## CRIMP Cheat codes ##
  #######################
  $self->{DisplayHtml} =~ s/<!--VERSION-->/$self->{VER}/gi;

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
  if ($self->{Config}->{$self->userConfig}->{RobotsMeta} ne '') {
    $self->{_RobotsMeta} = $self->{Config}->{$self->userConfig}->{RobotsMeta};
  } elsif ($self->{Config}->{_}->{RobotsMeta} ne '') {
    $self->{_RobotsMeta} = $self->{Config}->{_}->{RobotsMeta};
  }
  
  # KeywordsMeta
  if ($self->{Config}->{$self->userConfig}->{KeywordsMeta} ne '') {
    $self->{_KeywordsMeta} = $self->{Config}->{$self->userConfig}->{KeywordsMeta};
  } elsif ($self->{Config}->{_}->{KeywordsMeta} ne '') {
    $self->{_KeywordsMeta} = $self->{Config}->{_}->{KeywordsMeta};
  }

  # DescriptionMeta
  if ($self->{Config}->{$self->userConfig}->{DescriptionMeta} ne '') {
    $self->{_DescriptionMeta} = $self->{Config}->{$self->userConfig}->{DescriptionMeta};
  } elsif ($self->{Config}->{_}->{DescriptionMeta} ne '') {
    $self->{_DescriptionMeta} = $self->{Config}->{_}->{DescriptionMeta};
  }

  # PageRead
  if ($self->{Config}->{$self->userConfig}->{PageRead} ne '') {
    $self->{_PageRead} = $self->{Config}->{$self->userConfig}->{PageRead};
  } elsif ($self->{Config}->{_}->{PageRead} ne '') {
    $self->{_PageRead} = $self->{Config}->{_}->{PageRead};
  }

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
  foreach (split ',', $self->{Config}->{$self->userConfig}->{PluginOrder}) {
    $self->executePlugin($_) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++));
  }
  foreach (split ',', $self->{Config}->{_}->{PluginOrder}) {
    $self->executePlugin($_) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++));
  }
  foreach (@{$self->{_IniCommands}}) {
    $self->executePlugin($_) if (($_ eq 'DocumentTemplate') || (!($self->{skipRemainingPlugins} || $executedCommands{$_}++)));
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
sub redirect {
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
      my $seperator = $self->{Config}->{_}->{TitleSeperator} || ' - ';
      if ($self->{Config}->{_}->{TitleOrder} eq 'forward') {
        $self->{_PageTitle} = $self->{_PageTitle}.$seperator.$pt;
      } else {
        $self->{_PageTitle} = $pt.$seperator.$self->{_PageTitle};
      }
    }
  }
  return $self->{_PageTitle};
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
  push @{$self->{_cookies}}, $cookie;
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
  
  $self->ErrorDirectory($self->{Config}->{_}->{ErrorDirectory}) if $self->{Config}->{_}->{ErrorDirectory};
  $self->HtmlDirectory($self->{Config}->{_}->{HtmlDirectory}) if $self->{Config}->{_}->{HtmlDirectory};
  $self->CgiDirectory($self->{Config}->{_}->{CgiDirectory}) if $self->{Config}->{_}->{CgiDirectory};
  $self->DefaultProxy($self->{Config}->{_}->{DefaultProxy}) if $self->{Config}->{_}->{DefaultProxy};
  $self->PageTitle($self->{Config}->{_}->{SiteTitle}, 1) if $self->{Config}->{_}->{SiteTitle};
}

sub loadConfig {
  my $self = shift;
  
  if (!-f 'Config/Tiny.pm'){
    $self->{DebugMode => 'on'};
    $self->printdebug(
        'Crimp Files not found',
        'fail',
        'Please check the following files exist in the cgi-bin directory',
        'Config/Tiny.pm'
    );
  }

  $self->{Config} = Config::Tiny->new();
  $self->{Config} = Config::Tiny->read( 'crimp.ini' );
  
  if (!$self->{Config}) {
    $self->printdebug(
        'Crimp Files not found',
        'fail',
        'Please check the following files exist in the cgi-bin directory',
        'crimp.ini'
    );
  }
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
  
  opendir(DIR, 'Crimp') or $self->printdebug('Plugins DIR', 'fail', "Could not open the plugins' dir for reading $!");
  rewinddir(DIR);
  my @plugins = readdir(DIR);
  closedir(DIR);

  my @inicmds;
  foreach $plugin (@plugins) {
    # is the file we found a 'dot' file (.something - meaning hidden)?
    # if not, check it ends in '.pm'
    if ( ( !( $plugin =~ m/^\.+/ ) ) && ( $plugin =~ m/\.pm$/ ) ) {
      #remove the extension
      $plugin =~ s/\.pm$//;
      #add it to the list
      push @inicmds, $plugin;
    }
  }

  if (@inicmds = grep !/DocumentTemplate/, @inicmds) {
    #move DocumentTemplate to the end so that it is always called last (nasty hack I know)
    push @inicmds, 'DocumentTemplate';
  }

  if (@inicmds = grep !/ButtonBar/, @inicmds) {
    #move MenuButtons to the end so that it is always called After DocumentTemplate
    #(Following Fremen's nasty hack)
    push @inicmds, 'ButtonBar';
  }

  if ( ! @inicmds ) { $self->printdebug('Plugins', 'fail', 'There appear to be no plugins in the plugin directory.'); }
  else {
    # print Available plugins to debug (so many per line)
    my $inicount = 0;
    foreach $inicmds(@inicmds) {
      if ($inicount == 0) {
        $iniout = $inicmds;
      } else {
        if ($inicount % 7 == 0) {
          $iniout = join('<br/>&nbsp;&nbsp;&nbsp;&nbsp;',$iniout,$inicmds);
        } else {
          $iniout = join(',',$iniout,$inicmds);
        }
      }
      $inicount++;
    }
    $self->printdebug('Available Plugins', 'pass', $iniout);
  }
  return @inicmds;
}

sub parseGETed {
  my $self = shift;
  
  my @TempArray = split /&/, $self->{_HttpQuery};
  my %GetQuery;
  my $n = 0;
  foreach (@TempArray) {
    my ($name, $value) = split /=/;
    $name =~ s/([^\\])\+/\1 /g;
    $name = uri_unescape($name);
    $value =~ s/([^\\])\+/\1 /g;
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
    $name =~ s/([^\\])\+/\1 /g;
    $name = uri_unescape($name);
    $value =~ s/([^\\])\+/\1 /g;
    $value = uri_unescape($value);
    $PostQuery{$name} = $value;
    $n++;
  }
  
  $self->printdebug('POSTed Query Initialisation','pass',"Found $n parameters");
  return [%PostQuery, $PostQueryString];
}

####################################################################
sub addHeaderContent {
  my $self = shift;
	my $new_header = shift;
	$self->{PRINT_HEAD} = join '',$self->{PRINT_HEAD},$new_header,"\n";
}

####################################################################
sub addPageContent {
  my $self = shift;
  
	my $PageContent = shift;
	my $PageLocation = shift; #(top / bottom / null = bottom)
	my $pagehtml = '';

	$self->{DisplayHtml} = $self->{_DefaultHtml} if not defined $self->{DisplayHtml};

	if (($PageLocation eq 'top') && ($self->{DisplayHtml} =~ m/<!--startPageContent-->/)) {
		$self->printdebug('','','Adding PageContent (top)');
		$self->{DisplayHtml} =~ s|(<!--startPageContent-->)|\1\n$PageContent\n\n|;
	} elsif ($self->{DisplayHtml} =~ m/(<!--endPageContent-->)/) {
		$self->printdebug('','',"Adding PageContent");
		$pagehtml = join("\n",'<br />',$PageContent,'<!--endPageContent-->');
		$self->{DisplayHtml} =~ s|(<!--endPageContent-->)|<br />\n$PageContent\n\1|;
	} else {
		$self->printdebug('','',"Creating PageContent");
		$pagehtml = join("\n","\n",
			'<div id="crimpPageContent">',
			'<!--startPageContent-->',
			$PageContent,
			'<!--endPageContent-->',
			"</div>\n");
		$self->{DisplayHtml} =~ s/(<body>)/\1$pagehtml/i;
	}
	return 1;
}

####################################################################
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
		$self->{DisplayHtml} =~ s|(<!--startMenuContent-->)|\1\n$menuhtml\n<br />\n|;
	} elsif ($self->{DisplayHtml} =~ m/(<!--endMenuContent-->)/){
		$self->printdebug('','','Adding MenuContent (bottom)');
		$self->{DisplayHtml} =~ s|(<!--endMenuContent-->)|<br />\n$MenuContent\n\1|;
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

####################################################################
sub loadPlugin() {
	# this sub declared for future use once all supplied modules are using the new OO system
}

####################################################################
sub executePlugin() {
  my $self = shift;
	my $plugin = shift;
  
	if (!$self->{$plugin}) {
		if ($self->{Config}->{$self->userConfig}->{$plugin}) {
			$self->{$plugin} = $self->{Config}->{$self->userConfig}->{$plugin};
		} elsif ($self->{Config}->{_}->{$plugin}) {
			$self->{$plugin} = $self->{Config}->{_}->{$plugin};
		}
	}

	#Load Module
	if ($self->{$plugin} ne '') {
		my $absolutePlugin = join '::', 'Crimp', $plugin;
		eval "require $absolutePlugin";
		if ($@) { $self->printdebug("Module '$absolutePlugin' unable to load",'warn',$@,"Check 'crimp.ini' for the following:","&nbsp;&nbsp;$plugin = $self->{$plugin}"); }
		else {
      $myplugin = undef;
			eval { $myplugin = $absolutePlugin->new($self) };
			if ($@) { $self->printdebug("Module '$absolutePlugin'", 'warn', 'This plugin hasn\'t been upgraded yet or there was an error initialising:', $@); }
			else {
        eval { $myplugin->execute };
        $self->printdebug("Module '$absolutePlugin'", 'warn', 'Plugin failed to execute:', $@) if ($@);
      }
		}
	}
}

####################################################################
sub printdebug {
  my $self = shift;
	my $solut = '';
	my $logger = '';
	my $mssge = shift;
	my $stats = shift;
	my $exit = 0;
	
	while (my $extra = shift) {
		if ($solut eq '' && $mssge eq '') { $solut = "&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>"; }
		else { $solut = join '',$solut,'<br/>&nbsp;&nbsp;&nbsp;&nbsp;<span style="color: #ccc;">',$extra,'</span>'; }
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
    print header('text/html', 500);
    my $FAIL_DEBUG = join '','<div name="crimpDebugContainer" id="crimpDebugContainer"><div name="crimpDebug" id="crimpDebug">','<table width="100%" border="0" cellpadding="0" cellspacing="0" bgcolor="#000000">', $self->{PRINT_DEBUG}, "</table></div></div>\n";
    $self->{DisplayHtml} = $self->PageRead("Crimp/errors/500.html");
    $self->{DisplayHtml} =~ s|(</body>)|$FAIL_DEBUG\1|i;
    print $self->{DisplayHtml};
		exit 1;
	}
}

####################################################################
sub PageRead {
  my $self = shift;
  my $filename = shift;
  $self->printdebug('Module PageRead','',
                    'BuiltIn Module',
                    "File: $filename");

  if ( -f $filename ) {
    sysopen (FILE,$filename,O_RDONLY) || $self->printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
    @FileRead=<FILE>;
    close(FILE);
    $self->printdebug('','pass',"Returning content from $filename"); 
    return "@FileRead";
  }

  $filename = join '/', $self->{_ErrorDirectory}, '404.html';
  $self->printdebug('', 'warn', "File <$filename> does not exist",
                    "Using $self->{_ErrorDirectory}/404.html instead");
  $self->ExitCode('404');

  $newhtml = <<ENDEOF;
<h1>404 - Page Not Found</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
ENDEOF

  $FileRead = $self->{_DefaultHtml};
  $FileRead =~ s/(<body>)/\1$newhtml/i;
  $FileRead =~ s/(<title>)/\1404 - Page Not Found/i;
  return $FileRead;
}

# Garbage Collector for lock files used by FileWrite
sub lockFileGC {
	my $self = shift;
	my $lockfile = shift;
	
	my $timeout = 60; #seconds
	if ($@) { $self->printdebug('','warn','Lock File Garbase Collection Failed.',$@); }
	
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

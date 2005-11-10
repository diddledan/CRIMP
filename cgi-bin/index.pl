#!perl
# CRIMP - Content Redirection Internet Management Program
# Authors: The CRIMP team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@sourceforge.net>
# Version: 1.0
# Home/Docs/Licensing: http://crimp.sourceforge.net/

package Crimp;
#
# default web settings are to use local files
# with 404 error document in place
#
# config file contains file and or directory actions
# whether file exists or not
# will try and use apache config style for settings...
#
# <[file] or [directory] = "[local server path to file/directory]"
# [OPTIONS GO HERE]
# ie: *.exe's are located on a number of remote servers
#   try a random server to redirect to 
# </[file] or [directory]>
# also enable file to contain # comments
#
#Produce apache style logs

use Config::Tiny;
use CGI;
use CGI::Carp qw/ fatalsToBrowser /;
#use Fcntl; 

my $query = new CGI;
#print $query->header('text/html','200');

#our &printdebug;
#die;

&printdebug('CRIMP [Content Redirection Internet Management Program] (Debug View)');
&printdebug('Details', '', 'Authors: The CRIMP Team', 'Version: 1.0', 'http://crimp.sourceforge.net/');

########################
# BEGIN plguin parsing #
opendir(DIR, 'Crimp') or &printdebug('Plugins DIR', 'fail', "Could not open the plugins' dir for reading $!");
rewinddir(DIR);
my @plugins = readdir(DIR);
closedir(DIR);

my $inicmds = '';
foreach $plugin (@plugins) {
  # is the file we found a 'dot' file (.something - meaning hidden)?
  # if not, check it ends in '.pm'
  if ( ( $plugin{1} ne '.' ) && ( $plugin =~ m/[[\.][p][m]]?$/ ) ) {
    #remove the extension
    $plugin =~ s/[[\.][p][m]]?$//;
    #add it to the list
    $inicmds = join ';', $inicmds, $plugin;
  }
}

#move DocumentTemplate to the end so that it is always called last (nasty hack I know)
$inicmds =~ s/DocumentTemplate;//gi;
$inicmds = join ';', $inicmds, 'DocumentTemplate';
#remove extra semi-colon(s) from the beginning of the list
$inicmds =~ s/^\;*//;
#make sure that only one semi-colon seperates each plugin
$inicmds =~ s/\;+/\;/g;

if ( $inicmds eq '' ) { &printdebug('Plugins', 'fail', 'There appears to be no plugins in the plugin directory.'); }
else { &printdebug('Available Plugins', 'pass', $inicmds); }
# END plugin parsing #
######################

#DocumentTemplate;ContentDirectory;ContentType
our $crimp;
$crimp = {
    IniCommands => $inicmds,
    RemoteHost => "$ENV{'REMOTE_ADDR'}",
    ServerName =>  "$ENV{'SERVER_NAME'}",
    ServerSoftware =>  "$ENV{'SERVER_SOFTWARE'}",
    UserAgent =>  "$ENV{'HTTP_USER_AGENT'}",
    HttpRequest =>  "$ENV{'REDIRECT_URL'}",
    HttpQuery =>  "$ENV{'REDIRECT_QUERY_STRING'}",
    ExitCode => '500',
    DebugMode => 'off'
};

#use join here as it's the most efficient method of concatonating strings (Fremen)
if ($crimp->{HttpQuery}) { $crimp->{HttpQuery} = join '', '?', $crimp->{HttpQuery}; }

####################################################################
# this is a server beep (used for testing)
# Turns local and remote IP's into a tune
# gentoo users > emerge beep

$RemoteHost  = $ENV{'REMOTE_ADDR'};
$ServerHost  = $ENV{'SERVER_ADDR'};
($beep[4],$beep[3],$beep[2],$beep[1]) = split(/\./,$ServerHost);
($beep[5],$beep[6],$beep[7],$beep[8]) = split(/\./,$RemoteHost);

for ($i=1;$i<=8;$i++){
$note =($beep[$i]+25)*10;
$tune = "$tune -f $note -l 100 ";
if ($i < 8){$tune = "$tune -n ";}
}

# to activate, uncomment below
# $BEEP = `beep $tune`;

####################################################################

&printdebug(
    'System Variables',
    'pass',
    "ServerName: $crimp->{ServerName}",
    "ServerSoftware: $crimp->{ServerSoftware}"
);

&printdebug(
    'User Variables',
    'pass',
    "RemoteHost: $crimp->{RemoteHost}",
    "UserAgent: $crimp->{UserAgent}",
    "HttpRequest: $crimp->{HttpRequest}",
    "HttpQuery: $crimp->{HttpQuery}"
);

if ((!-e "crimp.ini")||(!-e "Config/Tiny.pm")){
    $crimp = {DebugMode => 'on'};
    printdebug(
        'Crimp Files not found',
        'fail',
        'Please check the following files exist in the crimp directory',
        'crimp.ini',
        'Config/Tiny.pm'
    );
}

our $Config = Config::Tiny->new();
$Config = Config::Tiny->read( 'crimp.ini' );

#switch to debug mode if set in crimp.ini
if ($crimp->{DebugMode} ne 'on'){
    if (($query->param('debug') eq 'on') && ($Config->{_}->{DebugMode} eq 'page')) {
        $crimp->{DebugMode} = 'on';
    } else {
        $crimp->{DebugMode}=$Config->{_}->{DebugMode};
    }
}

#set default values
#$crimp->{DocumentTemplate}=$Config->{_}->{DocumentTemplate};
#$crimp->{DebugMode}=$Config->{_}->{DebugMode};
#$crimp->{DebugMode}=$Config->{_}->{DebugMode};



####################################################################
## Main Routine ##
#################

#check requested versus config

#start with requested and work backwards to root until match found
#ie /home/news/index.html
#   /home/news
#   /home

@HttpRequest = split(/\//,$crimp->{HttpRequest});
my $tempstr = '';
foreach $HttpRequest (@HttpRequest){
    if ($HttpRequest ne '') {
        $tempstr = "$tempstr/$HttpRequest";
    }

    if ($Config->{$tempstr}){
        $crimp->{UserConfig}=$tempstr;
    }
}

if ($crimp->{UserConfig} eq ''){
    $crimp->{UserConfig}='/';
}

&printdebug(
    '\'crimp.ini\' Variables',
    'pass',
    "UserConfig: $crimp->{UserConfig}",
);

####################################################################
#set variables

@IniCommands = split(/\;/,$crimp->{IniCommands});

foreach $IniCommand (@IniCommands){
    if (!$crimp->{$IniCommand}) {
        if ($Config->{$crimp->{UserConfig}}->{$IniCommand}) {
            $crimp->{$IniCommand}=$Config->{$crimp->{UserConfig}}->{$IniCommand};
        } else {
            if ($Config->{_}->{$IniCommand}) {
                $crimp->{$IniCommand}=$Config->{_}->{$IniCommand};
            }
        }
    }
    #print "$IniCommands $crimp->{$IniCommands}<br>";

    #Load Module
    if ($crimp->{$IniCommand} ne ''){
        if ( !-e "Crimp/$IniCommand.pm"){
            printdebug("Module '$IniCommand' not found",'warn',"Check 'crimp.ini' for the following:","$IniCommand = $crimp->{$IniCommand}");
        }else{
            #printdebug("Module '$IniCommands' loading","pass","click here to get this file");
            require "Crimp/$IniCommand.pm";
        }
    }
}

####################################################################
## The End ##
############

if (($crimp->{ExitCode} ne '200')&&($crimp->{DisplayHtml} ne '')){
    $crimp->{ExitCode} = '200';
}

#This is where we finish the document or file
print $query->header('text/html',$crimp->{ExitCode});
&printdebug('Crimp Exit','pass',"Error code: $crimp->{ExitCode}");
if ($crimp->{DebugMode} eq 'on'){
    $PRINT_DEBUG = join '', '<table class="crimpDebug">', $PRINT_DEBUG, '</table>';
    $crimp->{DisplayHtml} =~ s/<!--DEBUG-->/$PRINT_DEBUG/g;;
}
print $crimp->{DisplayHtml};

####################################################################



#foreach $item (keys %ENV) { print "$item = $ENV{$item}\n<br>";}

####################################################################
####################################################################


sub printdebug(){
    my $solut="";
    my $mssge=shift(@_);
    my $stats=shift(@_);
    my $fatal = 0;

    #print "$Config->{_}->{Debug};";
    while (my $extra = shift) {
        $solut="$solut<br />&nbsp;&nbsp;&nbsp;&nbsp;<span style='color: #ccc;'>$extra</span>";
    }

    if ($stats eq 'pass') { $stats='[<span style="color: #0f0;">PASS</span>]' }
    if ($stats eq 'warn') { $stats='[<span style="color: #fc3;">WARN</span>]' }
    if ($stats eq 'exit') { $stats='[<span style="color: #33f;">EXIT</span>]'; $fatal = 1; }
    if ($stats eq 'fail') { $stats='[<span style="color: #f00;">FAIL</span>]'; $fatal = 1; }

    if ($solut ne '') { $mssge="<b>&#149;</b> $mssge $solut" }

    $PRINT_DEBUG = "$PRINT_DEBUG<tr><td class='crimpDebugMsg'><pre class='crimpDebug'>$mssge</pre></td><td class='crimpDebugStatus'><pre class='crimpDebug'><span style='color: #fff;'>$stats</span></pre></td></tr>";
    #
    #<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>
    if ($fatal){
        print $query->header('text/html',$crimp->{ExitCode});
        print $PRINT_DEBUG;
        exit;
        #crimp_display("debug");
        #print "META <meta http-equiv='refresh' content='30;URL=../cgi-bin/crimp.pl?mode=config'>";
        #print "<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>";
    }
}

#REALLY THE END#

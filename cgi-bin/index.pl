#!/usr/bin/perl


# Crimp
# Author: Martin Guppy <deadpan110@yooniks.com>
# Version: 1.0
# Home/Docs/Licensing: http://ind-network.co.uk/apps/crimp/

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
#		try a random server to redirect to 
#</[file] or [directory]>
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

#DocumentTemplate;ContentDirectory;ContentType
our $crimp;
$crimp = {

IniCommands => "FrameRedirect;VirtualRedirect;ContentType;ContentDirectory;DocumentTemplate",
				
				RemoteHost => "$ENV{'REMOTE_ADDR'}",
				ServerName =>  "$ENV{'SERVER_NAME'}",
				ServerSoftware =>  "$ENV{'SERVER_SOFTWARE'}",
				UserAgent =>  "$ENV{'HTTP_USER_AGENT'}",
				HttpRequest =>  "$ENV{'REDIRECT_URL'}",
				HttpQuery =>  "$ENV{'REDIRECT_QUERY_STRING'}",
 				ExitCode => "500",
				DebugMode => "off",
				
		
				
 
    };

if ($crimp->{HttpQuery}){$crimp->{HttpQuery} = "?$crimp->{HttpQuery}";}





####################################################################
#this is a server beep (used for testing)
$RemoteHost  = $ENV{'REMOTE_ADDR'};
#$RemoteHost  = "0.255.128.168";
$ServerHost  = $ENV{'SERVER_ADDR'};
($beep[4],$beep[3],$beep[2],$beep[1]) = split(/\./,$ServerHost);
($beep[5],$beep[6],$beep[7],$beep[8]) = split(/\./,$RemoteHost);


#$tune ="beep";
for ($i=1;$i<=8;$i++){
$note =($beep[$i]+25)*10;
$tune = "$tune -f $note -l 100 ";
if ($i < 8){$tune = "$tune -n ";}
}
#$BEEP = `beep $tune`;
#$BEEP = `beep`;
####################################################################

&printdebug("CRIMP [content redirection internet management program] (Debug View)");
&printdebug("Details","","Author: Martin Guppy [deadpan110\@gmail.com]","Version: 1.0","Home/Docs/Licensing: http://ind-network.co.uk/apps/crimp/");

&printdebug(
	"System Variables",
	"pass",
	
	"ServerName: $crimp->{ServerName}",
	"ServerSoftware: $crimp->{ServerSoftware}"
	);

&printdebug(
	"User Variables",
	"pass",
	
	"RemoteHost: $crimp->{RemoteHost}",
	"UserAgent: $crimp->{UserAgent}",
	"HttpRequest: $crimp->{HttpRequest}"
	);



if ((!-e "crimp.ini")||(!-e "Config/Tiny.pm")){
$crimp = {DebugMode => 'on',};
printdebug(
	"Crimp Files not found",
	"warn",

	"Please check the following files exist in the crimp directory"
	);
}


our $Config = Config::Tiny->new();
$Config = Config::Tiny->read( 'crimp.ini' );



#switch to debug mode if set in crimp.ini
if ($crimp->{DebugMode} ne "on"){

#$crimp={DebugMode => "$Config->{_}->{DebugMode}"};
$crimp->{DebugMode}=$Config->{_}->{DebugMode};
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
#	/home


@HttpRequest = split(/\//,$crimp->{HttpRequest});

foreach $HttpRequest (@HttpRequest){




if ($HttpRequest ne "") {
$tempstr = "$tempstr/$HttpRequest";
}



if ($Config->{$tempstr}){
$crimp->{UserConfig}=$tempstr;
}

}


if ($crimp->{UserConfig} eq ""){
$crimp->{UserConfig}="/";
}

&printdebug(
	"'crimp.ini' Variables",
	"pass",

	"UserConfig: $crimp->{UserConfig}",



	);

####################################################################
#set variables

@IniCommands = split(/\;/,$crimp->{IniCommands});

foreach $IniCommands (@IniCommands){

if (!$crimp->{$IniCommands}){

	if ($Config->{$crimp->{UserConfig}}->{$IniCommands}){
	$crimp->{$IniCommands}=$Config->{$crimp->{UserConfig}}->{$IniCommands};
	}
	else{
		if ($Config->{_}->{$IniCommands}){
			$crimp->{$IniCommands}=$Config->{_}->{$IniCommands};
			}
	}
}
#print "$IniCommands $crimp->{$IniCommands}<br>";

#Load Module
if ($crimp->{$IniCommands} ne ""){

		if ( !-e "Crimp/$IniCommands.pm"){
			printdebug("Module '$IniCommands' not found","warn","Check 'crimp.ini' for the following:","$IniCommands = $crimp->{$IniCommands}");
			}
		else{
		#	printdebug("Module '$IniCommands' loading","pass","click here to get this file");
			require "Crimp/$IniCommands.pm";
			}
}	


}
####################################################################
## The End ##
############

if (($crimp->{ExitCode} ne "200")&&($crimp->{DisplayHtml} ne "")){
$crimp->{ExitCode} = "200";
}


#This is where we finish the document or file

print $query->header('text/html',$crimp->{ExitCode});

printdebug("Crimp Exit","pass","Error code: $crimp->{ExitCode}");
			
print "$crimp->{DisplayHtml}";




####################################################################
if ($crimp->{DebugMode} eq "on"){
print "<br>$PRINT_DEBUG";
}

#foreach $item (keys %ENV) { print "$item = $ENV{$item}\n<br>";}


####################################################################




####################################################################


sub printdebug(){

my $solut="";
my $mssge=shift(@_);
my $stats=shift(@_);
my $extra=shift(@_);



#print "$Config->{_}->{Debug};";
while ($extra){
$solut="$solut<br>&nbsp;&nbsp;&nbsp;&nbsp;<font color='#CCCCCC'>$extra</font>";
$extra=shift(@_);
}

if ($stats eq "pass"){$stats="<pre><font color='#FFFFFF'>[<font color='#00FF00'>PASS</font>]</font></pre>"}
if ($stats eq "warn"){$stats="<pre><font color='#FFFFFF'>[<font color='#FFCC33'>WARN</font>]</font></pre>"}
if ($stats eq "exit"){$stats="<pre><font color='#FFFFFF'>[<font color='#3333FF'>EXIT</font>]</font></pre>";$quits=1;}
if ($stats eq "fail"){
$quits=1;
$stats="<pre><font color='#FFFFFF'>[<font color='#FF0000'>FAIL</font>]</font></pre>"}

if ($solut ne ""){$mssge="<b>&#149;</b> $mssge $solut"}

$PRINT_DEBUG = "$PRINT_DEBUG<table width='100%' border='0' cellspacing='0' cellpadding='0' bgcolor='#000000' align='center'><tr><td align='left' valign='top'><font color='#FFFFFF'><pre>$mssge</pre></font></td><td align='right' valign='top'>$stats</td></tr></table>";
#
#<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>
if ($quits){
crimp_display("debug");
#print "META <meta http-equiv='refresh' content='30;URL=../cgi-bin/crimp.pl?mode=config'>";
#print "<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#CCCCCC'><td align='left' valign='top'><h6><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>Powered by Crimp &copy;2004 IND-Web.com</font></h6><td align='right' valign='top'><font face='Verdana, Arial, Helvetica, sans-serif' size='1'><b>admin</b></font></td></tr><tr bgcolor='#000000'><td colspan='2'>$PRINT_DEBUG</td></tr></table>";

}
}



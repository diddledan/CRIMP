#Crimp Module Virtual Redirect
#our $crimp;

#parse url and remove the config file section $crimp->{UserConfig}
if ($crimp->{DisplayHtml} ne "" ){
  &printdebug("Module 'VirtualRedirect'","warn", "DisplayHtml has already been filled with content");
}

@HttpRequest = split(/\//,$crimp->{HttpRequest});

my $path = '';
foreach $HttpRequest (@HttpRequest){
  #print "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
  if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
}

#print "path : $path<br>";
#print "<BASE href='http://test.co.uk$crimp->{UserConfig}'>";

use LWP::UserAgent;
$ua = LWP::UserAgent->new;

if ($use_proxy){
  &printdebug("Using proxy server");
  #$ua->proxy(http => "http://$use_proxy");
}

$ua->agent("Mozilla/4.0 (crimp user $crimp->{RemoteHost}\@$crimp->{ServerName})"); # pretend we are very capable browser
$ua->timeout("30");

#$crimp->{HttpRequest}
$req = HTTP::Request->new(GET => "$crimp->{VirtualRedirect}$path$crimp->{HttpQuery}");
$req->header('Accept' => '*/*');
$res = $ua->request($req);

if ($res->is_success) {
#printdebug("File exists on remote server");



&printdebug("Module 'VirtualRedirect'","pass","Started With: $crimp->{VirtualRedirect}","Fetching the following content:","$crimp->{VirtualRedirect}$path$crimp->{HttpQuery}","REM: This url needs fixing by removing config entry from url");

$crimp->{DisplayHtml}= $res->content;


####################################################################
# not working yet... should correct links and images here
# Change ServerName to ServerName/Userconfig
$testing="$crimp->{ServerName}$crimp->{UserConfig}";
&printdebug("Correct Links","warn","Work in progress","Change all occurences of $crimp->{ServerName} to $crimp->{ServerName}$crimp->{UserConfig}");
$crimp->{DisplayHtml} =~ s/$crimp->{ServerName}/$testing/gi;
####################################################################


#$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;


}

#on success
1;

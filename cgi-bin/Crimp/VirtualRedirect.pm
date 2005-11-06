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
  &printdebug("Module 'VirtualRedirect'","pass","Started With: $crimp->{VirtualRedirect}","Fetching the following content:","$crimp->{VirtualRedirect}$path$crimp->{HttpQuery}");
  $crimp->{DisplayHtml}=$res->content;
  #print $res->content;
} else {
  &printdebug("Module 'VirtualRedirect'","warn","Started With: $crimp->{VirtualRedirect}","Fetching the following content:","$crimp->{VirtualRedirect}$path$crimp->{HttpQuery}","connection error");
  $crimp->{DisplayHtml}="<span style='color: f00;'>Connection error</span>";
}

#on success
1;

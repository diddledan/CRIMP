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
  if ($crimp->{UserConfig} ne "$HttpRequest"){$path = "$path/$HttpRequest";}
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

#create a variable to hold the url we want to retreive, so that it can be
#recalled later faster than recreating it each time
#(use a join here as it's faster)
$urltoget = join '',$crimp->{VirtualRedirect},$path,$crimp->{HttpQuery};
$req = HTTP::Request->new(GET => $urltoget);
$req->header('Accept' => '*/*');
$res = $ua->request($req);

if ($res->is_success) {
#printdebug("File exists on remote server");

&printdebug("Module 'VirtualRedirect'","pass","Started With: $crimp->{VirtualRedirect}","Fetching the following content:",$urltoget);

$crimp->{DisplayHtml}= $res->content;

####################################################################
# not working yet... should correct links and images here
# Change ServerName to ServerName/Userconfig
&printdebug("Correct Links","warn","Work in progress","Change all occurences of $crimp->{ServerName} to $crimp->{ServerName}$crimp->{UserConfig}");
#foreach $display_content($crimp->{DisplayHtml}) {
#$a++;
$changeto="$crimp->{ServerName}$crimp->{UserConfig}";
$crimp->{DisplayHtml} =~ s/$crimp->{ServerName}/$changeto/gi;
#$new_content= "$new_content$display_content\n\n";
#}
#&printdebug("Correct Links","pass","Change Links and Locations","Changed $count occurences of $crimp->{ServerName} to $crimp->{ServerName}$crimp->{UserConfig}");
####################################################################

#$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;

} else {
  # the LWP::UserAgent couldn't get the document - let's tell the user why
  $crimp->{DisplayHtml} = '<span style="color: #f00;">Connection error</span>';
  &printdebug('Module \'VirtualRedirect\'', 'warn', "Could not get '$urltoget'", $res->status_line);
}

#on success
1;

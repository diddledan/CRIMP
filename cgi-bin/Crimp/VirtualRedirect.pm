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
  if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = join '/', $path, $HttpRequest;}
}
#strip off preceeding slashes, as these should be defined in the crimp.ini file
$path =~ s|^/+||;
#add on any trailing slashes that may be required - another nasty hack by Fremen
if (($crimp->{HttpRequest} =~ m|/$|) && (!($path =~ m|/$|))) { $path = join '', $path, '/'; }

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
eval {require HTML::TokeParser;};
if (!$@) {
  # check that the path doesn't contain any filenames (directories only please)
  if ($path =~ m|/[\w\-_\.]+$|) {
    $path = s|/[\w\-_\.]+$|/|;
  }
  my $token_parser = HTML::TokeParser->new(\$crimp->{DisplayHtml});
  my @image_urls;
  my @link_urls;
  my %seenimgs = {};
  while (my $token = $token_parser->get_tag('img')) {
    my $url = $token->[1]{'src'} || next;
    if (!($url =~ m|^http[s]?://|i)) { push(@image_urls, $url) unless ($seenimgs{$url}++); }
  }
  my %seenlinks = {};
  #reset token_parser
  $token_parser = HTML::TokeParser->new(\$crimp->{DisplayHtml});
  while (my $token = $token_parser->get_tag('a')) {
    my $url = $token->[1]{'href'} || next;
    if (!($url =~ m|^.+?:(//)?|i)) { push(@link_urls, $url) unless ($seenlinks{$url}++); }
  }
  
  my $i = 0;
  my $url = $crimp->{VirtualRedirect};
  $url =~ m|(^http[s]?://.+?/)|i;
  $url = $1;
  for $image_url (@image_urls) {
    my $url2 = '';
    if ($image_url =~ m|^/|) { $url2 = $url; }
    else { $url2 = join '', $crimp->{VirtualRedirect}, $path, '/'; }
    my $newimageurl = join '', $url2, $image_url;
    $newimageurl =~ s|^(http[s]?://)||i;
    my $newimageproto = $1;
    $newimageurl =~ s|/{2,}|/|g;
    $crimp->{DisplayHtml} =~ s/$image_url/$newimageproto$newimageurl/g;
    $i++;
  }
  &printdebug('Correcting Images', 'pass', "Using $url for image urls", "Converted $i image tags to point to the correct web location");
  
  my $proto = 'http://';
  if ($ENV{'SERVER_PORT'} eq '443') { $proto = 'https://'; }
  $url = join '', $proto, $crimp->{ServerName}, '/';
  my $j = 0;
  for $link_url (@link_urls) {
    if ($link_url eq '/') {
      $crimp->{DisplayHtml} =~ s|(href=['"]{1})/(['"]{1})|\1/\2|g;
    } else {
      my $newlinkurl = '';
      if ($link_url =~ m|^/.+|) {
        $crimp->{VirtualRedirect} =~ m|^(http[s]?://.*?/)|;
        if ($crimp->{VirtualRedirect} =~ m/^$1$/) {
          $newlinkurl = join '', $crimp->{UserConfig}, $link_url;
        } else {
          $newlinkurl = join '', $crimp->{VirtualRedirect}, $path, $link_url;
        }
      } elsif (!($link_url =~ m|^.+?:(//)?|)) {
          $newlinkurl = join '', $crimp->{VirtualRedirect}, $path, '/', $link_url;
      } else { $newlinkurl = $link_url; }
      $newlinkurl =~ s!^((((f|ht){1}tp[s]?)|(irc)?)://)!!i;
      my $newlinkproto = $1;
      $newlinkurl =~ s|/{2,}|/|g;
      $crimp->{DisplayHtml} =~ s/$link_url/$newlinkproto$newlinkurl/g;
    }
    $j++;
  }
  &printdebug('Correcting Links', 'pass', "Successfuly converted $j links to point to the right place.");
  #foreach $item (keys %ENV) { &printdebug("$item = $ENV{$item}"); }
} else {
  &printdebug('Correcting Images and Links', 'warn', 'Couldn\'t correct the image and link urls of this page:', $@, 'Make sure you have installed the HTML::TokeParser module');
}


#&printdebug('Correct Links','warn','Work in progress',"Change all occurences of $crimp->{ServerName} to $crimp->{ServerName}$crimp->{UserConfig}");
#foreach $display_content($crimp->{DisplayHtml}) {
#$a++;
#$changeto="$crimp->{ServerName}$crimp->{UserConfig}";
#$crimp->{DisplayHtml} =~ s/$crimp->{ServerName}/$changeto/gi;
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

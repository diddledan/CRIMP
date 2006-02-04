$ID = q$Id: VirtualRedirect.pm,v 1.20 2006-02-04 21:44:23 deadpan110 Exp $;
&printdebug('Module VirtualRedirect',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

#Crimp Module Virtual Redirect
#our $crimp;

#parse url and remove the config file section $crimp->{UserConfig}
if ($crimp->{DisplayHtml} ne '' ){
  &printdebug('','warn', 'DisplayHtml has already been filled with content');
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

if ($crimp->{DefaultProxy}){
  &printdebug('','',"Using proxy server $crimp->{DefaultProxy}");
  $ua->proxy(['http', 'ftp'], $crimp->{DefaultProxy});
}

$ua->agent("Mozilla/5.0 (CRIMP user $crimp->{RemoteHost}\@$crimp->{ServerName})"); # pretend we are very capable browser
$ua->timeout("30");

#create a variable to hold the url we want to retreive, so that it can be
#recalled later faster than recreating it each time
#(use a join here as it's faster)
$urltoget = join '',$crimp->{VirtualRedirect},$path,$crimp->{HttpQuery};
$req = HTTP::Request->new(GET => $urltoget);
$req->header('Accept' => '*/*');
$res = $ua->request($req);
$error = $res->status_line;
if ($res->is_success) {
	#printdebug("File exists on remote server");
	
	&printdebug('','pass',"Started With: $crimp->{VirtualRedirect}",'Fetching the following content:',$urltoget);
	
	my $CrimpContent = $res->content;
	#get the page title
	$CrimpContent =~ s!<title>(.*?)</title>!!is;
	$crimp->{PageTitle} = $1;
	#remove the headers
	$CrimpContent =~ s|<!DOCTYPE.*?>||is;
	$CrimpContent =~ s!<html.*?>.*?<body.*?>!!is;
	#remove the footer
	$CrimpContent =~ s!</body>.*!!is;
	
$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
$crimp->{DisplayHtml} =~ s/<title>/<title>$crimp->{PageTitle}/i;
$crimp->{DisplayHtml} =~ s/<body>/<body>$CrimpContent/i;

$crimp->{DisplayHtml} =~ s/<body>/<body><div id="crimpPageContent">\n/i;
$crimp->{DisplayHtml} =~ s|(</body>)|</div>\n\1|i;;


	
	#################################
	# BEGIN LINK / IMAGE CORRECTION #
	
	eval {require HTML::TokeParser;};
	if (!$@) {
	  # check that the path doesn't contain any filenames (directories only please)
	  if ($path =~ m!/?[\w\-_\.]+$!) {
	    $path = s!/?[\w\-_\.]+$!/!;
	  }
	  if ($path eq '') { $path = '/'; }
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
	    if ($image_url =~ m|^/.+|) { $url2 = $url; }
	    else { $url2 = join '', $crimp->{VirtualRedirect}, $path, '/'; }
	    my $newimageurl = join '', $url2, $image_url;
	    $newimageurl =~ s|^(http[s]?://)||i;
	    my $newimageproto = $1;
	    $newimageurl =~ s|/{2,}|/|g;
	    $crimp->{DisplayHtml} =~ s/$image_url/$newimageproto$newimageurl/g;
	    $i++;
	  }
	  &printdebug('', 'pass', 'Converting Image URLs', "&nbsp;&nbsp;&nbsp;&nbsp;Using $url", "&nbsp;&nbsp;&nbsp;&nbsp;Converted $i image tags to point to the correct web location");
	  
	  #my $proto = 'http://';
	  #if ($ENV{'SERVER_PORT'} eq '443') { $proto = 'https://'; }
	  #$url = join '', $proto, $crimp->{ServerName}, '/';
	  my $j = 0;
	  for $link_url (@link_urls) {
	    if ($link_url eq '/') {
	      $crimp->{VirtualRedirect} =~ m|^(http[s]?://.*?/)|;
	      my $baseurl = $1;
	      if ($crimp->{VirtualRedirect} =~ m/^$baseurl$/) {
	        $newlinkurl = $crimp->{UserConfig};
	      } else {
	        $newlinkurl = $baseurl;
	      }
	      $crimp->{DisplayHtml} =~ s|(href=['"]{1})/(['"]{1})|\1$newlinkurl\2|g;
	      
	    } else {
	      my $newlinkurl = '';
	      if ($link_url =~ m|^/.+|) {
	        $crimp->{VirtualRedirect} =~ m|^(http[s]?://.*?/)|;
	        if ($crimp->{VirtualRedirect} eq $1) {
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
	      $newlinkurl = join '', $newlinkproto, $newlinkurl;
	      $crimp->{DisplayHtml} =~ s/$link_url/$newlinkurl/g;
	    }
	    $j++;
	  }
	  &printdebug('', 'pass', 'Correcting Links', "&nbsp;&nbsp;&nbsp;&nbsp;Successfuly converted $j links to point to the right place.");
	  #foreach $item (keys %ENV) { &printdebug("$item = $ENV{$item}"); }
	} else {
	  &printdebug('', 'warn', 'Couldn\'t correct the image and link urls of this page:', $@, 'Make sure you have installed the HTML::TokeParser module');
	}
	
	# END LINK / IMAGE CORRECTION #
	###############################
	
	#$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	$crimp->{ExitCode} = '200';
} else {
  # the LWP::UserAgent couldn't get the document - let's tell the user why
	&printdebug('', 'warn', "Could not get '$urltoget':", "Error: $error");


  $crimp->{DisplayHtml} = &PageRead(join('/',$crimp->{ErrorDirectory},$crimp->{DefaultLang},'404-VirtualRedirect.html'));


  $crimp->{ExitCode} = '404';
  return 1;

}

#on success
1;

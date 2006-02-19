$ID = q$Id: AutoSitemap.pm,v 1.1 2006-02-19 18:26:28 diddledan Exp $;
&printdebug('Module AutoSitemap',
						'',
						'Authors: The CRIMP Team',
						"Version: $ID",
						'http://crimp.sourceforge.net/'
						);

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
$urltoget = $crimp->{AutoSitemap};
$req = HTTP::Request->new(GET => $urltoget);
$req->header('Accept' => '*/*');
$res = $ua->request($req);
$error = $res->status_line;
if ($res->is_success) {
  $crimp->{ContentType} = 'text/xml';
  $crimp->{DisplayHtml} = $res->content;
  $crimp->{ExitCode} = '200';
} else {
  &printdebug('','warn','LWP::Request Failed',"Error: $error");
  $crimp->{DefaultHtml} = '<br /><br /><p style="color:red;text-align:center;">Could not get the XML SiteMap</p>';
  $crimp->{ExitCode} = '404';
}

1;

$ID = q$Id: CrimpNews.pm,v 1.1 2006-01-29 15:25:56 deadpan110 Exp $;
&printdebug('Module CrimpNews',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

my $NewsLocation = "$crimp->{VarDirectory}/CrimpNews.htm";

#Check if we have news and if it needs updating

if (!-f $NewsLocation){
&printdebug('','warn',"No CrimpNews exists locally");
$CrimpNews = &NewsUpdate;
}else{
# Check File Date
use File::stat;
#use Time::localtime;

#$FileDate = ctime(stat("$NewsLocation")->mtime);
#86400 seconds in 24 hours
$ServerDate = time;
$FileDate = stat("$NewsLocation")->mtime;
if ($ServerDate gt ($FileDate + 86400)){
$CrimpNews = &NewsUpdate;
}else{ 
&printdebug('','',"Using local CrimpNews from cache");
sysopen (NEWS,$NewsLocation,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
			@CrimpNews=<NEWS>;
			close(NEWS);
			$CrimpNews = "@CrimpNews";
}
}

$CrimpNews = join('','<h1>Latest CRIMP News</h1>','<p>The latest news updated daily, directly via the <a href="http://sourceforge.net">SourceForge.net</a> CRIMP project website.</p>',$CrimpNews);
$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
$crimp->{DisplayHtml} =~ s/<title>/<title>Latest CRIMP News/i;
$crimp->{DisplayHtml} =~ s/<body>/<body>$CrimpNews/i;



sub NewsUpdate{
&printdebug('','',"Fetching CrimpNews from http://sourceforge.net");

my $urltoget = "http://sourceforge.net/export/projnews.php?group_id=118939&limit=5&show_summaries=1";

use LWP::UserAgent;
$ua = LWP::UserAgent->new;

$ua->agent("Mozilla/5.0 (CRIMP user $crimp->{RemoteHost}\@$crimp->{ServerName})"); # pretend we are very capable browser
$ua->timeout("30");

$req = HTTP::Request->new(GET => $urltoget);
$req->header('Accept' => '*/*');
$res = $ua->request($req);

if ($res->is_success) {
$CrimpNews = $res->content;
sysopen(NEWS,$NewsLocation, O_WRONLY | O_CREAT | O_TRUNC) or die;
print NEWS "$CrimpNews\n";
close(NEWS);
return ("$CrimpNews");
} else {
  # the LWP::UserAgent couldn't get the document - let's tell the user why
&printdebug('', 'warn', "Could not get '$urltoget':", "&nbsp;&nbsp;&nbsp;&nbsp;$res->status_line");
$CrimpNews = '<span style="color: #f00;">Connection error</span>';
return("$CrimpNews");
}

}

1;
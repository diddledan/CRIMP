package Crimp::CrimpNews;

use Fcntl;

sub new {
	my ($class,$crimp) = @_;
	my $self = { id => q$Id: CrimpNews.pm,v 1.1 2006-11-30 16:48:09 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('',
			'',
			'Authors: The CRIMP Team',
			"Version: $self->{id}",
			'http://crimp.sourceforge.net/'
			);
	
	my $NewsLocation = $self->{crimp}->VarDirectory.'/CrimpNews.htm';
	
	#Check if we have news and if it needs updating
	if (!-f $NewsLocation) {
		$self->{crimp}->printdebug('','warn','No CrimpNews exists locally');
		$CrimpNews = $self->NewsUpdate($NewsLocation);
	} else {
		# Check File Date
		eval "use File::stat";
		if (!$@) {
			my $ServerDate = time;
			my $FileDate = stat($NewsLocation)->mtime;
			
			if ($ServerDate > ($FileDate + 86400)) {
				$CrimpNews = $self->NewsUpdate($NewsLocation);
			} else { 
				$self->{crimp}->printdebug('','','Using local CrimpNews from cache');
				sysopen (NEWS,$NewsLocation,O_RDONLY) || $self->{crimp}->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
				@CrimpNews=<NEWS>;
				close(NEWS);
				$CrimpNews = "@CrimpNews";
			}
		} else {
			$self->{crimp}->printdebug('','warn','Could not load File::Stat perl module:','&nbsp;&nbsp;'.$@);
			$CrimpNews = '<br /><br /><p style="color: #f00; text-align: center;"><em>WARNING</em>Could not determine file age,
				refetching from sourceforge server...<br /><small>(Please check the debug view)</small></p><br /><br />'.$self->NewsUpdate($NewsLocation);
		}
	}
		
	$CrimpNews = join('','<h1>Latest CRIMP News</h1>','<p>The latest news updated daily, directly via the <a href="http://sourceforge.net">SourceForge.net</a> CRIMP project website.</p>',$CrimpNews);
	$self->{crimp}->addPageContent($CrimpNews);
}

sub NewsUpdate {
	my $self = shift;
	my $NewsLocation = shift;
	
	$self->{crimp}->printdebug('','','Fetching CrimpNews from http://sourceforge.net');
	
	my $urltoget = 'http://sourceforge.net/export/projnews.php?group_id=118939&limit=5&show_summaries=1&flat=0';
	
	use LWP::UserAgent;
	$ua = LWP::UserAgent->new;
	
	if ($self->{crimp}->DefaultProxy) {
		$self->{crimp}->printdebug('','','Using proxy server '.$self->{crimp}->DefaultProxy);
		$ua->proxy(['http', 'ftp'], $self->{crimp}->DefaultProxy);
	}
	
	$ua->agent('Mozilla/5.0 (CRIMP user '.$self->{crimp}->{_RemoteHost}.'@'.$self->{crimp}->{_ServerName}.')'); # pretend we are very capable browser
	$ua->timeout(30);
	
	$req = HTTP::Request->new(GET => $urltoget);
	$req->header('Accept' => '*/*');
	$res = $ua->request($req);
	
	if ($res->is_success) {
		$CrimpNews = $res->content;
		if (!sysopen(NEWS,$NewsLocation, O_WRONLY | O_CREAT | O_TRUNC)) {
			$self->{crimp}->printdebug('','warn','Could not open file for writing','&nbsp;&nbsp;'.$NewsLocation.': '.$!);
			return '<br /><br /><p style="color: #f00; text-align: center;">Please check the debug view. An error occurred writing the cache file.
				If this problem persists, you will have a dramatic increase in bandwidth usage.</p><br /><br />'.$CrimpNews;
		}
		print NEWS "$CrimpNews\n";
		close(NEWS);
		return $CrimpNews;
	} else {
		# the LWP::UserAgent couldn't get the document - let's tell the user why
		$self->{crimp}->printdebug('', 'warn', "Could not get '$urltoget':", "&nbsp;&nbsp;&nbsp;&nbsp;$res->status_line");
		$CrimpNews = '<span style="color: #f00;">Connection error</span>';
		return $CrimpNews;
	}
}

1;

package Crimp::SideBar::rssTitles;

sub new {
	my ($class, $sidebar) = @_;
	my $self = {
		sidebar => $sidebar,
		crimp => $sidebar->{crimp},
		id => q$Id: rssTitles.pm,v 1.1 2006-07-31 22:03:09 diddledan Exp $,
	};

	bless $self, $class;

	use XML::RSS;
	use LWP::UserAgent;

	return $self;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	my $sidebar = $self->{sidebar};

	$ua = LWP::UserAgent->new;
	
	if ($crimp->DefaultProxy){
		$crimp->printdebug('','','Using proxy server: '.$crimp->DefaultProxy);
		$ua->proxy(['http', 'ftp'], $crimp->DefaultProxy);
	}
	
	$ua->agent('Mozilla/5.0 (CRIMP user '.$crimp->{_RemoteHost}.'@'.$crimp->{_ServerName}.')'); # pretend we are very capable browser
	$ua->timeout(30);

	$urltoget = $sidebar->Config('rssTitles');
	$req = HTTP::Request->new(GET => $urltoget);
	$req->header('Accept' => '*/*');
	$res = $ua->request($req);
	$error = $res->status_line;
	if (!$res->is_success) {
		$crimp->printdebug('','warn','Could not successfully retreive the RSS document:',"&nbsp;&nbsp;$error");
		return;
	}

	my $rss = new XML::RSS;
	$rss->parse($res->content);
	my $count = 0;
	my $content = '';
	foreach my $item (@{$rss->{'items'}}) {
		$content .= "<li><a href='$item->{'link'}'>$item->{'title'}</a></li>" if $count++ <= 5;
	}
	$sidebar->addToSideBar($content);
}

1;

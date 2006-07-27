package Crimp::AutoSitemap;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: AutoSitemap.pm,v 2.2 2006-07-27 23:12:04 diddledan Exp $, crimp => $crimp, };
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
	
	eval "use LWP::UserAgent";
	if ($@) {
		$self->{crimp}->printdebug('','warn','Could not load LWP::UserAgent','&nbsp;&nbsp;'.$@);
		return;
	}
	
	$ua = LWP::UserAgent->new;
	
	if ($self->{crimp}->DefaultProxy) {
		$self->{crimp}->printdebug('','','Using proxy server '.$self->{crimp}->DefaultProxy);
		$ua->proxy(['http', 'ftp'], $self->{crimp}->DefaultProxy);
	}

	$ua->agent('Mozilla/5.0 (CRIMP user '.$self->{crimp}->{_RemoteHost}.'@'.$self->{crimp}->{_ServerName}.')'); # pretend we are very capable browser
	$ua->timeout(30);
	
	$req = HTTP::Request->new(GET => $self->{crimp}->{AutoSitemap});
	$req->header('Accept' => '*/*');
	$res = $ua->request($req);
	$error = $res->status_line;
	if ($res->is_success) {
		$self->{crimp}->ContentType('text/xml');
		$self->{crimp}->{DisplayHtml} = $res->content;
		$self->{crimp}->ExitCode('200');
	} else {
		&printdebug('','warn','LWP::Request Failed',"Error: $error");
		$crimp->{DisplayHtml} = '<br /><br /><p style="color:red;text-align:center;">Could not get the XML SiteMap</p>';
		$crimp->{ExitCode} = '404';
	}
}

1;

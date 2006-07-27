package Crimp::VirtualRedirect;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: VirtualRedirect.pm,v 2.1 2006-07-27 23:12:07 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};

	$crimp->printdebug('',
		'',
		'Authors: The CRIMP Team',
		"Version: $self->{id}",
		'http://crimp.sourceforge.net/');
	
	#parse url and remove the config file section $crimp->{UserConfig}
	@HttpRequest = split(/\//,$crimp->{HttpRequest});
	my $path = '';
	foreach (@HttpRequest) {
		$path = join('/', $path, $_) if ($crimp->userConfig ne "/$_");
	}
	
	#strip off preceeding slashes, as these should be defined in the crimp.ini file
	$path =~ s|^/+||;
	#add on any trailing slashes that may be required - another nasty hack by Fremen
	if (($crimp->HttpRequest =~ m|/$|) && (!($path =~ m|/$|))) { $path = join '', $path, '/'; }
	
	eval "use LWP::UserAgent";
	if ($@) {
		$crimp->printdebug('','warn','Could not load LWP::UserAgent:','&nbsp;&nbsp;'.$@);
		return;
	}
	
	$ua = LWP::UserAgent->new;
	
	if ($crimp->DefaultProxy){
		$crimp->printdebug('','','Using proxy server '.$crimp->DefaultProxy);
		$ua->proxy(['http', 'ftp'], $crimp->DefaultProxy);
	}
	
	$ua->agent('Mozilla/5.0 (CRIMP user '.$crimp->{_RemoteHost}.'@'.$crimp->{_ServerName}.')'); # pretend we are very capable browser
	$ua->timeout(30);
	
	#create a variable to hold the url we want to retreive, so that it can be
	#recalled later. faster than recreating it each time
	#(use a join here as it's faster)
	$urltoget = join '',$crimp->{VirtualRedirect},$path,$crimp->{_HttpQuery};
	$req = HTTP::Request->new(GET => $urltoget);
	$req->header('Accept' => '*/*');
	$res = $ua->request($req);
	$error = $res->status_line;
	if ($res->is_success) {
		$crimp->printdebug('','pass',"Started With: $crimp->{VirtualRedirect}",'Fetching the following content:','&nbsp;&nbsp;'.$urltoget);
		
		my $CrimpContent = $res->content;
		
		#################################
		# BEGIN LINK / IMAGE CORRECTION #
		
		eval "require HTML::TokeParser";
		if (!$@) {
			# check that the path doesn't contain any filenames (directories only please)
			$path = s!/[\w\-_\.]+$!/! if ($path =~ m!/[\w\-_\.]+$!);
			$path ||= '/';
			
			my $token_parser = HTML::TokeParser->new(\$CrimpContent);
			my @image_urls;
			my @link_urls;
			my %seenimgs = {};
			while (my $token = $token_parser->get_tag('img')) {
				my $url = $token->[1]{'src'} || next;
				if (!($url =~ m|^http[s]?://|i)) { push(@image_urls, $url) unless ($seenimgs{$url}++); }
			}
			my %seenlinks = {};
			#reset token_parser
			$token_parser = HTML::TokeParser->new(\$CrimpContent);
			while (my $token = $token_parser->get_tag('a')) {
				my $url = $token->[1]{'href'} || next;
				if (!($url =~ m|^.+?:(//)?|i)) { push(@link_urls, $url) unless ($seenlinks{$url}++); }
				elsif ($url =~ m|^$crimp->{VirtualRedirect}|i) { push(@link_urls, $url) unless ($seenlinks{$url}++); }
			}
			
			my $i = 0;
			my $baseurl = $crimp->{VirtualRedirect};
			$baseurl =~ m|^(http[s]?://.+?)[/]?|i;
			$baseurl = $1;
			for $image_url (@image_urls) {
				my $newbaseurl='';
				if ($image_url =~ m|^/.+|) { $newbaseurl = $baseurl; }
				else { $newbaseurl = join '', $crimp->{VirtualRedirect}, $path, '/'; }
				my $newimageurl = join '', $newbaseurl, $image_url;
				$newimageurl =~ s|^(http[s]?://)||i;
				my $newimageproto = $1;
				$newimageurl =~ s|/{2,}|/|g;
				$CrimpContent =~ s/(<img.*?src=['"]?)$image_url(["']?.*?>)/\1$newimageproto$newimageurl\2/g;
				$i++;
			}
			
			$crimp->printdebug('', 'pass', 'Converting Image URLs', "&nbsp;&nbsp;&nbsp;&nbsp;Using $url", "&nbsp;&nbsp;&nbsp;&nbsp;Converted $i unique image tags to point to the correct web location");
			
			my $j = 0;
			$crimp->{VirtualRedirect} =~ m|^(http[s]?://.*?)[/]?|;
			my $baseurl = $1;
			for $link_url (@link_urls) {
				my $newlinkurl = '';
				my $protocol = $crimp->{_ServerProtocol};
				if (!($url =~ m|^.+?:(//)?|i)) {
					if ($link_url =~ m|^/.*|) {
						# we need to determine if the link is within our control or not.
						# currently all we do is rewrite if the VirtualRedirect Config value is just the base domain.
						if ($crimp->{VirtualRedirect} =~ m|^$baseurl(.?)$|) { $newlinkurl = join '/',$crimp->userConfig,$link_url; }
						else {
							# check it falls within the VirtualRedirect subtree, and rewrite if so, else set to "$baseurl$link_url"
							$newlinkurl = join '', $baseurl, $link_url;
						}
					} else { $newlinkurl = join '/', $crimp->userConfig, $link_url; }
				} else {
					$newlinkurl = $link_url;
					$newlinkurl =~ s|$crimp->{VirtualRedirect}||i;
					$newlinkurl = join '/', $crimp->userConfig, $newlinkurl;
				}
				
				$newlinkurl =~ s!^(http[s]?://)!!i;
				my $newlinkproto = $1;
				$newlinkurl =~ s|/+|/|g;
				$link_url =~ s|\?|\\\?|gi;
				$newlinkurl = join '', $newlinkproto, $newlinkurl if ($newlinkproto =~ m!^(http[s]?://)!i);
				$CrimpContent =~ s/(<a.*?href=['"]?)$link_url(['"]?.*?>)/\1$newlinkurl\2/g;
				$j++;
			}
			
			$crimp->printdebug('', 'pass', 'Correcting Links', "&nbsp;&nbsp;&nbsp;&nbsp;Successfuly converted $j unique links to point to the right place.");
		} else {
			&printdebug('', 'warn', 'Couldn\'t correct the image and link urls of this page:', $@, 'Make sure you have installed the HTML::TokeParser module');
		}

		# END LINK / IMAGE CORRECTION #
		###############################
		
		#get the page title
		$CrimpContent =~ s!<title>(.*?)</title>!!is;
		$crimp->PageTitle($1);
		#remove the headers
		$CrimpContent =~ s|<!DOCTYPE.*?>||is;
		$CrimpContent =~ s!<html.*?>.*?<body.*?>!!is;
		#remove the footer
		$CrimpContent =~ s!</body>.*!!is;
		
		$crimp->addPageContent($CrimpContent);
		$crimp->ExitCode('200');
	} else {
		# the LWP::UserAgent couldn't get the document - let's tell the user why
		$crimp->printdebug('', 'warn', "Could not get '$urltoget':", "Error: $error");
		$crimp->{DisplayHtml} = &PageRead(join('/',$crimp->{ErrorDirectory},$crimp->{DefaultLang},'404-VirtualRedirect.html'));
		$crimp->ExitCode('404');
	}
}

#on successful loading
1;

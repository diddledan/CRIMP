#package declaration (needed - should be Crimp::Something where Something is the name of the file minus the extension)
package Crimp::ContentDirectory;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: ContentDirectory.pm,v 2.2 2006-07-27 23:12:04 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
	return $self;
}

#execute subroutine (needed - this one does the actual work)
sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	$crimp->printdebug('',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);

	@HttpRequest = split(/\//,$crimp->{_HttpRequest});

	foreach (@HttpRequest) {
		$path = "$path/$_" if ($crimp->userConfig ne "/$_");
	}

	$path = '/index.html' if ($path eq '');

	#check for directory here if it is then use $path
	#make sure the requested file is _NOT_ a directory (Fremen)
	my $requested = join('',$crimp->{ContentDirectory}, $path);
	if ( -d $requested ) { $requested = join '/', $requested, 'index.html'; }
	$crimp->printdebug('', '', "File: $requested");

	# Use error page
	if (( !-f $requested )||( -d $requested )||( !-r $requested)) {
		$crimp->printdebug('', 'warn', 'Couldnt open file for reading', "Error: $!");

		$crimp->errorPage('ContentDirectory', '404');

		# finish execution of this sub;
		return;
	}

	if (( -e $requested ) && ( !-d $requested )) {
		sysopen (FILE,$requested,O_RDONLY) || $crimp->printdebug('', 'warn', 'Couldnt open file for reading', "file: $requested", "error: $!");
		@display_content=<FILE>;
		close(FILE);
		
		if (@display_content) {
			my $newcontent = '';
			$newcontent = $newcontent.$_ foreach (@display_content);

			my ($title, $content) = $crimp->stripHtmlHeaderFooter($newcontent);
			$crimp->PageTitle($title) if $title;
			$crimp->addPageContent($content);
			
			####
			
			$crimp->ExitCode('200') if ($crimp->ExitCode ne '404');
		} else {
			$crimp->printdebug('','warn','The file handle is invalid. This should not happen.');
		}
	} else {
		$crimp->addPageContent('Could not get the requested content. Please check the link and try again.');
		if (!-e $requested) {
			$crimp->printdebug('','warn',"$requested does not exist.");
		} else {
			$crimp->printdebug('','warn',"$requested is a directory.");
		}
	}
}

1;

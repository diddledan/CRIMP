#package declaration (needed - should be Crimp::Something where Something is the name of the file minus the extension)
package Crimp::ContentDirectory;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: ContentDirectory.pm,v 2.1 2006-07-15 16:27:57 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
	return $self;
}

#execute subroutine (needed - this one does the actual work)
sub execute {
	my $self = shift;
	$self->{crimp}->printdebug('Module ContentDirectory',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);

	@HttpRequest = split(/\//,$self->{crimp}->{_HttpRequest});

	foreach (@HttpRequest) {
		$path = "$path/$_" if ($self->{crimp}->userConfig ne "/$_");
	}

	$path = '/index.html' if ($path eq '');

	#check for directory here if it is then use $path
	#make sure the requested file is _NOT_ a directory (Fremen)
	my $requested = join('',$self->{crimp}->{ContentDirectory}, $path);
	if ( -d $requested ) { $requested = join '/', $requested, 'index.html'; }
	$self->{crimp}->printdebug('', '', "File: $requested");

	# Use error page
	if (( !-f $requested )||( -d $requested )||( !-r $requested)) {
		$self->{crimp}->printdebug('', 'warn', 'Couldnt open file for reading', "Error: $!");

		my $content = $self->{crimp}->PageRead(join('/',$self->{crimp}->{_ErrorDirectory},$self->{crimp}->{_DefaultLang},'404-ContentDirectory.html'));
		my $title = '';
		($title, $content) = $self->{crimp}->stripHtmlHeaderFooter($content);
		$self->{crimp}->PageTitle($title);
		$self->{crimp}->addPageContent($content);
		$self->{crimp}->ExitCode('404');

		# finish execution of this sub;
		return;
	}

	if (( -e $requested ) && ( !-d $requested )) {
		sysopen (FILE,$requested,O_RDONLY) || $self->{crimp}->printdebug('', 'warn', 'Couldnt open file for reading', "file: $requested", "error: $!");
		@display_content=<FILE>;
		close(FILE);
		
		if (@display_content) {
			my $newcontent = '';
			$newcontent = $newcontent.$_ foreach (@display_content);

			my ($title, $content) = $self->{crimp}->stripHtmlHeaderFooter($newcontent);
			$self->{crimp}->PageTitle($title) if $title;
			$self->{crimp}->addPageContent($content);
			
			####
			
			$self->{crimp}->ExitCode('200') if ($self->{crimp}->ExitCode ne '404');
		} else {
			$self->{crimp}->printdebug('','warn','The file handle is invalid. This should not happen.');
		}
	} else {
		$self->{crimp}->addPageContent('Could not get the requested content. Please check the link and try again.');
		if (!-e $requested) {
			$self->{crimp}->printdebug('','warn',"$requested does not exist.");
		} else {
			$self->{crimp}->printdebug('','warn',"$requested is a directory.");
		}
	}
}

1;

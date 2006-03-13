package Crimp::RandomContent;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: RandomContent.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	$self->{crimp}->printdebug('Module RandomContent',
			'',
			'Authors: The CRIMP Team',
			"Version: $self->{id}",
			'http://crimp.sourceforge.net/'
			);
	
	if(!$self->{crimp}->{RandomContent} =~ m/\.txt$/) {
		$self->{crimp}->printdebug('','warn',"File extension must be *.txt");
		return;
	}
	
	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{RandomContent}");
	
	my $file = join '/', $self->{crimp}->VarDirectory, $self->{crimp}->{RandomContent}
	if ( -f $file ) {
		srand(time);
		sysopen (FILE,$file,O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $file", "error: $!");
		@FileRead=<FILE>;
		close(FILE);
		
		$NbLines = @FileRead;
		$Phrase = $FileRead[int rand $NbLines];
		
		if (!defined $self->{crimp}->{DisplayHtml} || $self->{crimp}->{DisplayHtml} eq '') {
			$self->{crimp}->{RandomContent} =~ s/\.txt$//;
			$self->{crimp}->{DisplayHtml} = $self->{crimp}->{_DefaultHtml};
		}
		my $newhtml = "<div id=\"crimpRandomContent\">\n$Phrase\n</div>";
		
		$self->{crimp}->{DisplayHtml} =~ s/<body>/<body>$newhtml/i;
	} else {
		$self->{crimp}->printdebug('','',"$self->{crimp}->{RandomContent} does not exist!");
	}
}

1;

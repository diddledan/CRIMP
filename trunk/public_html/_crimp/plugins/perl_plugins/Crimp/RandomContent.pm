# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2007 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: RandomContent.pm,v 1.5 2007-04-29 23:22:32 diddledan Exp $
#
# This file is Licensed under the LGPL.

package Crimp::RandomContent;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: RandomContent.pm,v 1.5 2007-04-29 23:22:32 diddledan Exp $, crimp => $crimp, };
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

	if(!$self->{crimp}->{RandomContent} =~ m/\.txt$/) {
		$self->{crimp}->printdebug('','warn',"File extension must be *.txt");
		return;
	}

	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{RandomContent}");

	my $file = join '/', $self->{crimp}->VarDirectory, $self->{crimp}->{RandomContent};
	if ( -f $file ) {
		srand(time);
		sysopen (FILE,$file,O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $file", "error: $!");
		@FileRead=<FILE>;
		close(FILE);

		$NbLines = @FileRead;
		$Phrase = $FileRead[int rand $NbLines];

		my $newhtml = "<div id='crimpRandomContent'>\n$Phrase\n</div>";

		$self->{crimp}->addReplacement('(<body>)', "\$1$newhtml", 'i');
	} else {
		$self->{crimp}->printdebug('','',"$self->{crimp}->{RandomContent} does not exist!");
	}
}

1;

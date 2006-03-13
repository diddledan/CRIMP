package Crimp::SiteMenu;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: SiteMenu.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module SiteMenu',
		'',
		'Authors: The CRIMP Team',
		"Version: $self->{id}",
		'http://crimp.sourceforge.net/');
	
	my $where = $self->{crimp}->{SiteMenu};
	if (sysopen(FILE,join('/',$self->{crimp}->VarDirectory,$where),O_RDONLY)) {
		my @file = <FILE>;
		close(FILE);
		$self->{crimp}->addMenuContent("@file", 'top');
		
		$self->{crimp}->printdebug('', 'pass', 'Created Site Menu from file:',join('','&nbsp;&nbsp;',$where));
	} else {
		$self->{crimp}->printdebug('', 'warn', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
	}
}

1;

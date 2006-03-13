package Crimp::BreadCrumbs;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: BreadCrumbs.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module BreadCrumbs',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);
	
	$self->{crimp}->printdebug('','','Started With: '.$self->{crimp}->{BreadCrumbs});
	
	my $BreadLink = '';
	my $BreadCrumbs = "<a href='/$BreadLink'>home</a>";
	
	@HttpRequest = split(/\//,$self->{crimp}->HttpRequest);
	foreach (@HttpRequest) {
		if ($_ ne '' && $_ ne 'index.html'){
		
		$BreadLink = "$BreadLink/$_";
		$_ =~ s/(\.html){1}$//;
		$BreadCrumbs = "$BreadCrumbs - <a href='$BreadLink'>$_</a>";
		}
	}
	
	if (	($self->{crimp}->{BreadCrumbs} eq 'top')
				|| ($self->{crimp}->{BreadCrumbs} eq 'bottom')
				|| ($self->{crimp}->{BreadCrumbs} eq 'both')	) {
		
		if (($self->{crimp}->{BreadCrumbs} eq 'top') || ($self->{crimp}->{BreadCrumbs} eq 'both')) {
			$newhtml = "<div id='crimpBreadCrumbs'><b>Location: $BreadCrumbs</b><br/></div>";
			$self->addBreadCrumbs($newhtml, 'top');
			$self->{crimp}->printdebug('','pass','BreadCrumbs inserted at the top of the page');
		}
		if (($self->{crimp}->{BreadCrumbs} eq 'bottom') || ($self->{crimp}->{BreadCrumbs} eq 'both')) {
			$newhtml = "<div id='crimpBreadCrumbsbottom'><br/><b>Location: $BreadCrumbs</b></div>";
			$self->addBreadCrumbs($newhtml, 'bottom');
			$self->{crimp}->printdebug('','pass','BreadCrumbs inserted at the bottom of the page');
		}
	} else {
		$self->{crimp}->printdebug('','warn','BreadCrumbs neets to be set with \'top\', \'bottom\' or \'both\'');
	}
}

sub addBreadCrumbs {
	my ($self, $html, $location) = @_;
	return if not defined $location;
	$self->{crimp}->{DisplayHtml} =~ s|(<body.*?>)|\1$html|is if ($location eq 'top');
	$self->{crimp}->{DisplayHtml} =~ s|(</body>)|$html\1|i if ($location eq 'bottom');
}

1;

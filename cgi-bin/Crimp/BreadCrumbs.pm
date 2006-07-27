package Crimp::BreadCrumbs;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: BreadCrumbs.pm,v 2.1 2006-07-27 23:12:04 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	
	$crimp->printdebug('',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);
	
	$crimp->printdebug('','','Started With: '.$crimp->{BreadCrumbs});
	
	my $BreadLink = '';
	my $BreadCrumbs = "<a href='/$BreadLink'>home</a>";
	
	@HttpRequest = split(/\//,$crimp->HttpRequest);
	foreach (@HttpRequest) {
		if ($_ ne '' && $_ ne 'index.html'){
		
		$BreadLink = "$BreadLink/$_";
		$_ =~ s/(\.html){1}$//;
		$BreadCrumbs = "$BreadCrumbs - <a href='$BreadLink'>$_</a>";
		}
	}
	
	if (	($crimp->{BreadCrumbs} eq 'top')
				|| ($crimp->{BreadCrumbs} eq 'bottom')
				|| ($crimp->{BreadCrumbs} eq 'both')	) {
		
		if (($crimp->{BreadCrumbs} eq 'top') || ($crimp->{BreadCrumbs} eq 'both')) {
			$newhtml = "<div id='crimpBreadCrumbs'><b>Location: $BreadCrumbs</b><br/></div>";
			$self->addBreadCrumbs($newhtml, 'top');
			$crimp->printdebug('','pass','BreadCrumbs inserted at the top of the page');
		}
		if (($crimp->{BreadCrumbs} eq 'bottom') || ($crimp->{BreadCrumbs} eq 'both')) {
			$newhtml = "<div id='crimpBreadCrumbsbottom'><br/><b>Location: $BreadCrumbs</b></div>";
			$self->addBreadCrumbs($newhtml, 'bottom');
			$crimp->printdebug('','pass','BreadCrumbs inserted at the bottom of the page');
		}
	} else {
		$crimp->printdebug('','warn','BreadCrumbs neets to be set with \'top\', \'bottom\' or \'both\'');
	}
}

sub addBreadCrumbs {
	my ($self, $html, $location) = @_;
	my $crimp = $self->{crimp};
	return if not defined $location;
	$crimp->{DisplayHtml} =~ s|(<body.*?>)|\1$html|is if ($location eq 'top');
	$crimp->{DisplayHtml} =~ s|(</body>)|$html\1|i if ($location eq 'bottom');
}

1;

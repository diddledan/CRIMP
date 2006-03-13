package Crimp::ButtonBar;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: ButtonBar.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module ButtonBar',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);
	
	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{ButtonBar}");
	
	my $help ="#";
	my $view = "#";
	my $edit = "#";
	my $querystring = $self->{crimp}->{_HttpQuery};
	$querystring =~ s|debug=.*?(&)?||i;
	$querystring = join('', '?', $querystring) if not $querystring =~ m|^\?|;
	$querystring = join('', $querystring, '&') if $querystring =~ m|^\?.+|;
	my $debug = join '', $self->{crimp}->HttpRequest, ${querystring}, 'debug=on#crimpDebug';
	
	@ButtonBar = <<ENDEOF;
<a href="<!--help-->"><img
 src="/crimp_assets/ButtonBar/$self->{crimp}->{ButtonBar}/pics/help.gif" alt="Help"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--view-->"><img
 src="/crimp_assets/ButtonBar/$self->{crimp}->{ButtonBar}/pics/view.gif" alt="View"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--edit-->"><img
 src="/crimp_assets/ButtonBar/$self->{crimp}->{ButtonBar}/pics/edit.gif" alt="Edit"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--debug-->"><img
 src="/crimp_assets/ButtonBar/$self->{crimp}->{ButtonBar}/pics/debug.gif" alt="Debug"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a>
ENDEOF
	
	if ($self->{crimp}->{ButtonBar} eq 'Default') {
		$self->{crimp}->printdebug('','pass','Using Default ButtonBar');
	} else {
		# Use a Custom ButtonBar
		my $requested = "$self->{crimp}->HtmlDirectory/crimp_assets/ButtonBar/$self->{crimp}->{ButtonBar}/style.htm";
		if ( -f $requested ) {
			sysopen (FILE,$requested,O_RDONLY) || $self->{crimp}->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
			$self->{crimp}->printdebug('','pass',"Using $self->{crimp}->{ButtonBar} ButtonBar");
			@ButtonBar=<FILE>;
			close(FILE);
		} else {
			$self->{crimp}->printdebug('','warn',"$self->{crimp}->{ButtonBar} ButtonBar does not exist",'Using Default ButtonBar');	
		}
	}
	
	# Put it all together
	
	$self->{crimp}->{DisplayHtml} =~ s/<!--BUTTONBAR-->/@ButtonBar/gi;
	$self->{crimp}->{DisplayHtml} =~ s/<!--help-->/$help/gi;
	$self->{crimp}->{DisplayHtml} =~ s/<!--view-->/$view/gi;
	$self->{crimp}->{DisplayHtml} =~ s/<!--edit-->/$edit/gi;
	$self->{crimp}->{DisplayHtml} =~ s/<!--debug-->/$debug/gi;
}

1,

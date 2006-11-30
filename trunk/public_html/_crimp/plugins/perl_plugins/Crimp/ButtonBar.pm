package Crimp::ButtonBar;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: ButtonBar.pm,v 1.1 2006-11-30 16:48:09 diddledan Exp $, crimp => $crimp };
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
	
	$crimp->printdebug('','',"Started With: $crimp->{ButtonBar}");
	
	my $help ="#";
	my $view = "#";
	my $edit = "#";
	my $querystring = $crimp->{_HttpQuery};
	$querystring =~ s|debug=.*?(&)?||i;
	$querystring = join('', '?', $querystring) if not $querystring =~ m|^\?|;
	$querystring = join('', $querystring, '&') if $querystring =~ m|^\?.+|;
	my $debug = join '', $crimp->HttpRequest, $querystring, 'debug=on#crimpDebug';
	
	@ButtonBar = <<ENDEOF;
<a href="<!--help-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/help.gif" alt="Help"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--view-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/view.gif" alt="View"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--edit-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/edit.gif" alt="Edit"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--debug-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/debug.gif" alt="Debug"
 style="border: 0px solid ; width: 26px; height: 25px;" onClick="showDebug(); return false;"/></a>
ENDEOF
	
	if ($crimp->{ButtonBar} eq 'Default') {
		$crimp->printdebug('','pass','Using Default ButtonBar');
	} else {
		# Use a Custom ButtonBar
		my $requested = $crimp->HtmlDirectory."/crimp_assets/ButtonBar/$crimp->{ButtonBar}/style.htm";
		if ( -f $requested ) {
			sysopen (FILE,$requested,O_RDONLY) || $crimp->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
			$crimp->printdebug('','pass',"Using $crimp->{ButtonBar} ButtonBar");
			@ButtonBar=<FILE>;
			close(FILE);
		} else {
			$crimp->printdebug('','warn',"$crimp->{ButtonBar} ButtonBar does not exist",'Using Default ButtonBar');	
		}
	}
	
	# Put it all together
	
	$crimp->{DisplayHtml} =~ s/<!--BUTTONBAR-->/@ButtonBar/gi;
	$crimp->{DisplayHtml} =~ s/<!--help-->/$help/gi;
	$crimp->{DisplayHtml} =~ s/<!--view-->/$view/gi;
	$crimp->{DisplayHtml} =~ s/<!--edit-->/$edit/gi;
	$crimp->{DisplayHtml} =~ s/<!--debug-->/$debug/gi;
}

1,

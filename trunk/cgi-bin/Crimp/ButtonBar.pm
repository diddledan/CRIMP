$ID = q$Id: ButtonBar.pm,v 1.3 2006-01-31 03:48:09 deadpan110 Exp $;
&printdebug('Module ButtonBar',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

&printdebug('','',"Started With: $crimp->{ButtonBar}");

my $help ="#";
my $view = "#";
my $edit = "#";
my $debug = "$crimp->{HttpRequest}?debug=on#crimpDebug";


@ButtonBar = <<ENDEOF;
<a href="<!--help-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/help.gif" alt="Help"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--view-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/view.gif" alt="View"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--edit-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/edit.gif" alt="Edit"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--debug-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/debug.gif" alt="Debug"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a>
ENDEOF


if ($crimp->{ButtonBar} eq "Default"){
&printdebug('','pass',"Using Default ButtonBar");
}else{
# Use a Custom ButtonBar
my $requested = "$crimp->{HtmlDirectory}/crimp_assets/ButtonBar/$crimp->{ButtonBar}/style.htm";
if ( -f $requested ) {
		sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
			&printdebug('','pass',"Using $crimp->{ButtonBar} ButtonBar");
			@ButtonBar=<FILE>;
			close(FILE);
	}else{
&printdebug('','warn',"$crimp->{ButtonBar} ButtonBar does not exist","Using Default ButtonBar");	
			}
	}

# Put it all together

$crimp->{DisplayHtml} =~ s/<!--BUTTONBAR-->/@ButtonBar/gi;
$crimp->{DisplayHtml} =~ s/<!--help-->/$help/gi;
$crimp->{DisplayHtml} =~ s/<!--view-->/$view/gi;
$crimp->{DisplayHtml} =~ s/<!--edit-->/$edit/gi;
$crimp->{DisplayHtml} =~ s/<!--debug-->/$debug/gi;

	
1,
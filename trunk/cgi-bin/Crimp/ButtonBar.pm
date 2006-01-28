$ID = q$Id: ButtonBar.pm,v 1.1 2006-01-28 15:51:06 deadpan110 Exp $;
&printdebug('Module ButtonBar',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

&printdebug('','',"Started With: $crimp->{ButtonBar}");

$help ="#";
$view = "#";
$edit = "#";
$debug = "$crimp->{HttpRequest}?debug=on";

if ($crimp->{ButtonBar} eq "Default"){

$ButtonBar = <<ENDEOF;
<a href="$help"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/help.gif" alt="Help"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="$view"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/view.gif" alt="View"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="$edit"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/edit.gif" alt="Edit"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="$debug"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/debug.gif" alt="Debug"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a>
ENDEOF

}


else{
#Error check here and tell the user within debug to set HtmlDirectory in crimp.ini

require "$crimp->{HtmlDirectory}/crimp_assets/ButtonBar/$crimp->{ButtonBar}/style.pm";
}
	
$crimp->{DisplayHtml} =~ s/<!--BUTTONBAR-->/$ButtonBar/gi;
	
1,
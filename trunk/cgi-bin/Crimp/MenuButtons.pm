$ID = q$Id: MenuButtons.pm,v 1.2 2006-01-26 18:08:45 deadpan110 Exp $;
&printdebug('Module MenuButtons',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);



my $MenuButtons = <<ENDEOF;
<a href="#"><img
 src="/crimp_assets/ButtonBar/help.gif"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="#"><img
 src="/crimp_assets/ButtonBar/view.gif"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="#"><img
 src="/crimp_assets/ButtonBar/edit.gif"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="$crimp->{HttpRequest}?debug=on"><img
 src="/crimp_assets/ButtonBar/debug.gif"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a>
ENDEOF


#$template =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
$crimp->{DisplayHtml} =~ s/<!--MENU_BUTTONS-->/$MenuButtons/gi;
	
1,
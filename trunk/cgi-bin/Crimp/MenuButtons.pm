$ID = q$Id: MenuButtons.pm,v 1.1 2006-01-26 17:35:22 deadpan110 Exp $;
&printdebug('Module MenuButtons',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);



my $MenuButtons = <<ENDEOF;
<a href="#"><img
 src="/crimp_assets/ButtonBar/help.gif" alt="Help" width="26" height="25"
 style="border: 0px solid ; width: 26px; height: 26px;"/>
</a>
<a href="#"><img
 src="/crimp_assets/ButtonBar/view.gif" alt="Text View" width="26" height="25"
 style="border: 0px solid ; width: 26px; height: 26px;"/>
</a>
<a href="#"><img
 src="/crimp_assets/ButtonBar/edit.gif" alt="Editor" width="26" height="25"
 style="border: 0px solid ; width: 26px; height: 26px;"/>
</a>
<a href="$crimp->{HttpRequest}?debug=on"><img
 src="/crimp_assets/ButtonBar/debug.gif" alt="Debug View" width="26" height="25"
 style="border: 0px solid ; width: 26px; height: 26px;"/>
</a>
ENDEOF


#$template =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
$crimp->{DisplayHtml} =~ s/<!--MENU_BUTTONS-->/$MenuButtons/gi;
	
1,
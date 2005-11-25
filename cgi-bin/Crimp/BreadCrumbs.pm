$ID = q$Id: BreadCrumbs.pm,v 1.5 2005-11-18 20:15:22 ind-network Exp $;
&printdebug('Module BreadCrumbs',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

&printdebug("","","Started With: $crimp->{BreadCrumbs}");

my $BreadLink = "http://$crimp->{ServerName}";
my $BreadCrumbs = "<a href='$BreadLink'>home</a>";

@HttpRequest = split(/\//,$crimp->{HttpRequest});

foreach $HttpRequest (@HttpRequest){

	if ($HttpRequest ne '' && $HttpRequest ne "index.html"){

		$BreadLink = "$BreadLink/$HttpRequest";
		$HttpRequest =~ s/(\.html){1}$//;
		$BreadCrumbs = "$BreadCrumbs - <a href='$BreadLink'>$HttpRequest</a>";
	}

}

if (($crimp->{BreadCrumbs} eq "top") || ($crimp->{BreadCrumbs} eq "bottom") || ($crimp->{BreadCrumbs} eq "both")){

	if (($crimp->{BreadCrumbs} eq "top") || ($crimp->{BreadCrumbs} eq "both")){
		$crimp->{DisplayHtml}="<b>Location: $BreadCrumbs</b><br>$crimp->{DisplayHtml}";
		&printdebug("","pass","BreadCrumbs inserted at the top of the page");
	}

	if (($crimp->{BreadCrumbs} eq "bottom") || ($crimp->{BreadCrumbs} eq "both")){
		$crimp->{DisplayHtml}="$crimp->{DisplayHtml}<br><b>Location: $BreadCrumbs</b>";
		&printdebug("","pass","BreadCrumbs inserted at the bottom of the page");
	}

}else{
	&printdebug("","warn","BreadCrumbs neets to be set with 'top', 'bottom' or 'both'");
}

1, 
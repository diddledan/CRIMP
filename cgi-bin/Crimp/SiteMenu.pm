$ID = q$Id: SiteMenu.pm,v 1.6 2006-02-07 19:11:07 deadpan110 Exp $;
&printdebug('Module SiteMenu',
	'',
	'Authors: The CRIMP Team',
	"Version: $ID",
	'http://crimp.sourceforge.net/');
	
	# $crimp->{SiteMenu} should be a separate div to $crimp->{MenuList}


my $where = $crimp->{SiteMenu};
if (sysopen(FILE,join('/',$crimp->{VarDirectory},$where),O_RDONLY)) {
	my @file = <FILE>;
	close(FILE);
	&addMenuContent("@file");
#	my $newMenu = '';

#	$newMenu = "$newMenu$_\n" foreach (@file);

#	$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, $newMenu;
	&printdebug('', 'pass', 'Created Site Menu from file:',join('','&nbsp;&nbsp;',$where));
} else {
	&printdebug('', 'warn', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
}

#if ($crimp->{MenuList}) {
#	#$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, '<ul>';
#	foreach my $linkElement (@{$crimp->{MenuList}}) {
#		$crimp->{MenuDiv} = join '', $crimp->{MenuDiv},$linkElement,'<br/>';
#	}
#	#$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, '</ul>';
#} else {
#	&printdebug('','warn','Called without a set of links specified by any previous module');
#}

#$crimp->{MenuDiv} = join '', '<div id="crimpFileList">', $crimp->{MenuDiv}, '</div>' if $crimp->{MenuDiv};
#$crimp->{DisplayHtml} =~ s|(<body>)|\1$crimp->{MenuDiv}|i;



1;
$ID = q$Id: SiteMenu.pm,v 1.3 2006-01-18 16:22:30 diddledan Exp $;
&printdebug('Module SiteMenu',
	'',
	'Authors: The CRIMP Team',
	"Version: $ID",
	'http://crimp.sourceforge.net/');

my $where = $crimp->{SiteMenu};
if (sysopen(FILE,join('/',$crimp->{VarDirectory},$where),O_RDONLY)) {
	my @file = <FILE>;
	my $newMenu = '';

	$newMenu = "$newMenu$_\n" foreach (@file);

	$crimp->{SiteMenu} = join '', $crimp->{SiteMenu}, $newMenu;
	&printdebug('', 'pass', 'Created Site Menu from file:',join('','&nbsp;&nbsp;',$where));
} else {
	&printdebug('', 'warn', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
}

my $FileList = '';
if ($crimp->{MenuList}) {
	$FileList = join '', $_, '<br/>' foreach (@{$crimp->{MenuList}});
	$FileList = join '', '<div id="crimpFileList">', $FileList, '</div>' if $FileList;
	&printdebug('','pass','Created crimpFileList div');
} else {
	&printdebug('','warn','Called without a set of links specified by any previous module');
}

$crimp->{DisplayHtml} =~ s|(<body>)|\1$crimp->{SiteMenu}$FileList|i;

1;
$ID = q$Id: SiteMenu.pm,v 1.1 2006-01-09 19:58:47 diddledan Exp $;
&printdebug('Module LinkList',
	'',
	'Authors: The CRIMP Team',
	"Version: $ID",
	'http://crimp.sourceforge.net/');

my $where = $crimp->{SiteMenu};
if (sysopen(FILE,join('/',$crimp->{VarDirectory},$where),O_RDONLY)) {
	my @file = <FILE>;
	my $newMenu = '';

	$newMenu = "$newMenu$_\n" foreach (@file);

	$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, $newMenu;
	&printdebug('', 'pass', 'Created Site Menu from file:',join('','&nbsp;&nbsp;',$where));
} else {
	&printdebug('', 'warn', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
}

if ($crimp->{MenuList}) {
	$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, '<ul>';
	foreach my $linkElement (@{$crimp->{MenuList}}) {
		$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, '<li>', $linkElement, '</li>';
	}
	$crimp->{MenuDiv} = join '', $crimp->{MenuDiv}, '</ul>';
} else {
	&printdebug('','warn','Called without a set of links specified by any previous module');
}

$crimp->{MenuDiv} = join '', '<div id="crimpFileList">', $crimp->{MenuDiv}, '</div>' if $crimp->{MenuDiv};
$crimp->{DisplayHtml} =~ s|(<body>)|\1$crimp->{MenuDiv}|i;

1;
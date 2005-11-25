$ID = q$Id: FileList.pm,v 1.6 2005-11-25 09:50:02 ind-network Exp $;
&printdebug('Module FileList',
				'',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/'
				);

&printdebug('','',"Started With: $crimp->{FileList}");

my $DirList = '<b>Directories</b><br />';
my $FileList = '<b>Documents</b><br />';
my $DirCount = 0;
my $FileCount = 0;
my $DirLayout = '<br />';

#Depends on ContentDirectory
if ($crimp->{ContentDirectory} ne '') {
	if ($crimp->{FileList} eq 'horizontal') { $DirLayout = ' | '; }
	
	my $FileDir = $crimp->{ContentDirectory};

	my @HttpRequest = split(/\//,$crimp->{HttpRequest});
	my $BaseUrl = $crimp->{UserConfig};
	
	foreach my $HttpRequest (@HttpRequest) {
		if (-d "$FileDir/$HttpRequest") {
			$FileDir = join '/', $FileDir, $HttpRequest;
			$BaseUrl = join '/', $BaseUrl, $HttpRequest;
		}
	}
	&printdebug('','', join(': ', 'FileDir', $FileDir));
	&printdebug('','', join(': ', 'BaseUrl (before sanitisation)', $BaseUrl));

	if (( -d $FileDir )){

	
	opendir(DIR, $FileDir) or &printdebug('', 'fail', "Could not open the current directory for reading $!");
	rewinddir(DIR);
	my @DirChk = readdir(DIR);
	closedir(DIR);
	foreach $DirChk (@DirChk) {
		if (($DirChk ne ".")&&($DirChk ne "..")&&($DirChk ne "index.html")&&($DirChk ne "CVS")){
			if (-d "$FileDir/$DirChk") {
				$DirCount ++;
				$newurl = join '/', $BaseUrl, $DirChk;
				$newurl =~ s!/{2,}!/!g;
				if ($DirCount == 1) {
					$DirList="$DirList<a href='$newurl'>$DirChk</a>";
				} else {
					$DirList="$DirList$DirLayout<a href='$newurl'>$DirChk</a>";
				}
			} else {
				$FileCount ++;
				$DirChk =~ s/(\.html){1}$//;
				$newurl = join '/', $BaseUrl, $DirChk;
				$newurl =~ s!/{2,}!/!g;
				if ($FileCount == 1) {
					$FileList="$FileList<a href='$newurl'>$DirChk</a>";
				} else {
					$FileList="$FileList$DirLayout<a href='$newurl'>$DirChk</a>";
				}
			}
		}
	}
	
	&printdebug('','pass',"Directories found: $DirCount");
	&printdebug('','pass',"Documents found: $FileCount");
	
	$newhtml = '<div id="crimpFileList">';
	if ($DirCount ne 0) { $newhtml = join '', $newhtml, $DirList, '<br /><br />'; }
	if ($FileCount ne 0) { $newhtml = join '', $newhtml, $FileList, '<br /><br />'; }
	$newhtml = join '', $newhtml, '</div>';
	$crimp->{DisplayHtml} = join '', $newhtml, $crimp->{DisplayHtml};

}else{
&printdebug('', 'warn', 'Couldn\'t open directory for listing');
}



}else{
	&printdebug('','warn','This module depends on the ContentDirectory module');
}


1; 

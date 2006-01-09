$ID = q$Id: FileList.pm,v 1.13 2006-01-09 16:22:11 diddledan Exp $;
&printdebug('Module FileList',
				'',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/'
				);

&printdebug('','',"Started With: $crimp->{FileList}");

my $DirList = '<b>Directories</b><br />&nbsp;&nbsp;&nbsp;';
my $FileList = '<b>Documents</b><br />&nbsp;&nbsp;&nbsp;';
my $DirLayout = '<br />&nbsp;&nbsp;&nbsp;';
my $DirCount = 0;
my $FileCount = 0;


#Depends on ContentDirectory
if ($crimp->{ContentDirectory} ne '') {
	$DirList = '<b>Directories:</b>';
	$FileList = '<b>Documents:</b>';
	
	if ($crimp->{FileList} eq 'horizontal') { 
		$DirLayout = ' | ';
		$DirList = join '', $DirList, ' ';
		$FileList = join '', $FileList, ' ';
	} else {
		$DirLayout = '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
		$DirList = join '', $DirList, '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
		$FileList = join '', $FileList, '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	}
	
	my $FileDir = $crimp->{ContentDirectory};

	my @HttpRequest = split(/\//,$crimp->{HttpRequest});
	my $BaseUrl = '';
	
	foreach my $HttpRequest (@HttpRequest) {
		if (-d "$FileDir/$HttpRequest") {
			$FileDir = join '/', $FileDir, $HttpRequest;
			$BaseUrl = join '/', $BaseUrl, $HttpRequest;
		}
	}

	$BaseUrl =~ s!/{2,}!/!g;
	$BaseUrl = join '/', $crimp->{UserConfig}, $BaseUrl unless $BaseUrl =~ m!$crimp->{UserConfig}!;
	&printdebug('','', join(': ', 'FileDir', $FileDir));
	&printdebug('','', join(': ', 'BaseUrl (before sanitisation)', $BaseUrl));

	#my $CheckUrl = join '','../', $crimp->{HttpRequest};

	if (( -d $FileDir )){

	
	opendir(DIR, $FileDir) or &printdebug('', 'fail', "Could not open the current directory for reading $!");
	rewinddir(DIR);
	my @DirChk = readdir(DIR);
	closedir(DIR);
	foreach $DirChk (@DirChk) {
		if (($DirChk ne '.') && ($DirChk ne '..') && ($DirChk ne 'index.html') && ($DirChk ne 'CVS')){
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
				$newurl = join '', $newurl,'.html';
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
	
	if ( ($DirCount + $FileCount) != 0 ){
		$newhtml = '<div id="crimpFileList">';
		if ($DirCount != 0) { $newhtml = join '', $newhtml, $DirList, '<br />'; }
		if ($FileCount != 0) { $newhtml = join '', $newhtml, $FileList, '<br />'; }
		$newhtml = join '', $newhtml, '</div>';
		
		 $crimp->{DisplayHtml} =~ s/<body>/<body>$newhtml/i;
		# $crimp->{DisplayHtml} = join '', $newhtml, $crimp->{DisplayHtml};
	}
}else{
&printdebug('', 'warn', 'Couldn\'t open directory for listing');
}



}else{
	&printdebug('','warn','This module depends on the ContentDirectory module');
}


1; 

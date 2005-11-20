$ID = q$Id: FileList.pm,v 1.3 2005-11-20 22:16:34 diddledan Exp $;
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
	
	@HttpRequest = split(/\//,$crimp->{HttpRequest});
	
	foreach $HttpRequest (@HttpRequest) {
		if (-d "$FileDir/$HttpRequest") {
			$FileDir = "$FileDir/$HttpRequest";
		}
	}
	
	opendir(DIR, $FileDir) or &printdebug('', 'fail', "Could not open the current directory for reading $!");
	rewinddir(DIR);
	my @DirChk = readdir(DIR);
	closedir(DIR);
	foreach $DirChk (@DirChk) {
		if (($DirChk ne ".")&&($DirChk ne "..")&&($DirChk ne "index.html")){
			if (-d "$FileDir/$DirChk") {
				$DirCount ++;
				if ($DirCount == 1) {
					$DirList="$DirList<a href='$crimp->{HttpRequest}/$DirChk'>$DirChk</a>";
				} else {
					$DirList="$DirList$DirLayout<a href='$crimp->{HttpRequest}/$DirChk'>$DirChk</a>";
				}
			} else {
				$FileCount ++;
				$DirChk =~ s/(\.html){1}$//;
				if ($FileCount == 1) {
					$FileList="$FileList<a href='$crimp->{HttpRequest}/$DirChk.html'>$DirChk</a>";
				} else {
					$FileList="$FileList$DirLayout<a href='$crimp->{HttpRequest}/$DirChk.html'>$DirChk</a>";
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
	&printdebug('','warn','This module depends on the ContentDirectory module');
}


1; 

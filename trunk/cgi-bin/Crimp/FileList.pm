&printdebug('Module FileList',
			'',
			'Authors: The CRIMP Team',
			'Version: 1.0',
			'http://crimp.sourceforge.net/'
			);

&printdebug("","","Started With: $crimp->{FileList}");

my $DirList = "<b>Directories</b><br>";
my $FileList = "<b>Documents</b><br>";
my $DirCount = 0;
my $FileCount = 0;
my $DirLayout = "<br>";
#Depends on ContentDirectory
if ($crimp->{ContentDirectory} ne ""){

if ($crimp->{FileList} eq "horizontal"){$DirLayout = " | ";}

my $FileDir = $crimp->{ContentDirectory};

@HttpRequest = split(/\//,$crimp->{HttpRequest});

foreach $HttpRequest (@HttpRequest){

	if (-d "$FileDir/$HttpRequest"){
		$FileDir = "$FileDir/$HttpRequest";
	}

}

opendir(DIR, $FileDir) or &printdebug('', 'fail', "Could not open the current directory for reading $!");
rewinddir(DIR);
my @DirChk = readdir(DIR);
closedir(DIR);
foreach $DirChk (@DirChk){
	if (($DirChk ne ".")&&($DirChk ne "..")&&($DirChk ne "index.html")){
		if (-d "$FileDir/$DirChk"){
			$DirCount ++;
			if ($DirCount eq '1'){
			$DirList="$DirList<a href='$crimp->{HttpRequest}/$DirChk'>$DirChk</a>";
			}else{
			$DirList="$DirList$DirLayout<a href='$crimp->{HttpRequest}/$DirChk'>$DirChk</a>";
			}
		}else{
			$FileCount ++;
			$DirChk =~ s/(\.html){1}$//;
			if ($FileCount eq '1'){
			$FileList="$FileList<a href='$crimp->{HttpRequest}/$DirChk.html'>$DirChk</a>";
			}else{
			$FileList="$FileList$DirLayout<a href='$crimp->{HttpRequest}/$DirChk.html'>$DirChk</a>";
			}
		}
	}
}

&printdebug("","pass","Directories found: $DirCount");
&printdebug("","pass","Documents found: $FileCount");

if ($DirCount ne 0){$crimp->{DisplayHtml}="$DirList</b><br><br>$crimp->{DisplayHtml}";}
if ($FileCount ne 0){$crimp->{DisplayHtml}="$FileList</b><br><br>$crimp->{DisplayHtml}";}


}else{
&printdebug("","warn","This module depends on the ContentDirectory module");
}


1; 

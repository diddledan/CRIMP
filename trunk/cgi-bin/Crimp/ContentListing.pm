$ID = q$Id: ContentListing.pm,v 1.1 2005-11-29 20:32:16 deadpan110 Exp $;
&printdebug('Module ContentListing',
				'',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/'
				);

&printdebug('','',"Started With: $crimp->{ContentListing}");

use File::stat;
use Time::localtime;

my $DirLayout = '<br />';
my $DirCount = 0;
my $FileCount = 0;
my $DownloadFile = "";
my $FileType = "unknown";
my $FileDate = "unknown";
my $FileSize = "unknown";

my $lock = 0;

my $FileServed = &FileRead("ContentListing","$crimp->{UserConfig}","0");
&printdebug('','',"FileCount: $FileServed");



&printdebug('','',"ExitCode: $crimp->{ExitCode}");




if ($crimp->{DisplayHtml} ne "" ){
	&printdebug("","warn", "DisplayHtml has already been filled with content");
}else{


my $FileDir = $crimp->{ContentListing};

	my @HttpRequest = split(/\//,$crimp->{HttpRequest});
	my $BaseUrl = '';
	
	foreach my $HttpRequest (@HttpRequest) {
		if (-d "$FileDir/$HttpRequest") {
			$FileDir = join '/', $FileDir, $HttpRequest;
			$BaseUrl = join '/', $BaseUrl, $HttpRequest;
		}
		if (($HttpRequest ne "")&&(grep /.download/, $HttpRequest)){
		$DownloadFile = $HttpRequest;
		$DownloadFile =~ s/(\.download){1}$//;
		}		
	}

	$BaseUrl =~ s!/{2,}!/!g;
	$BaseUrl = join '/', $crimp->{UserConfig}, $BaseUrl unless $BaseUrl =~ m!$crimp->{UserConfig}!;
	&printdebug('','', join(': ', 'FileDir', $FileDir));
	&printdebug('','', join(': ', 'BaseUrl (before sanitisation)', $BaseUrl));
	
	

	
		
		if ($DownloadFile ne ""){
			&printdebug('','', join(': ', 'DownloadFile', $DownloadFile));
			$FileServed ++;
			&FileWrite("ContentListing","$crimp->{UserConfig}",$FileServed);

			#close;
			if ($crimp->{ExitCode} ne "500"){
				print 'Status: 302 Moved', "\r\n", "Location: $BaseUrl$DownloadFile", "\r\n\r\n";

			}

		}



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
					$DirList="$DirList<tr><td><img src='/icons/small/dir.gif' alt='[DIR]'/></td><td><a href='$newurl'>$DirChk</a></td><td>&nbsp;</td><td>&nbsp;</td><tr>";
				}
			} else {
				$FileCount ++;
				
				$DirChk =~ s/(\.html){1}$//;
				$newurl = join '/', $BaseUrl, $DirChk;
				$newurl =~ s!/{2,}!/!g;
				
				$newurl = join '', $newurl,'.download';
				$FileType = $DirChk;
				

				$FileDate = ctime(stat("$FileDir/$DirChk")->mtime);
				$FileSize = -s "$FileDir/$DirChk";
				$FileSize = int(1+$FileSize/10.24);
				$FileSize = $FileSize/100;


if($FileType =~ m/.patch/){
$FileType = "<img src='/icons/small/patch.gif' alt='[Patch]'>";
}

if($FileType =~ m/.gif|.jpg|.png|.bmp|.ico/){
$FileType = "<img src='/icons/small/image.gif' alt='[Image]'>";
}

if($FileType =~ m/.mp3|.wav|.ogg/){
$FileType = "<img src='/icons/small/sound.gif' alt='[Audio]'>";
}

if($FileType =~ m/.mov|.avi|.mpg|.ram/){
$FileType = "<img src='/icons/small/movie.gif' alt='[Movie]'>";
}

if($FileType =~ m/.txt|.rtf|.html/){
$FileType = "<img src='/icons/small/text.gif' alt='[Text]'>";
}

if($FileType =~ m/.doc|.pdf|.odt/){
$FileType = "<img src='/icons/small/doc.gif' alt='[Document]'>";
}

if($FileType =~ m/.tar/){
$FileType = "<img src='/icons/small/tar.gif' alt='[Archive]'>";
}

if($FileType =~ m/.sum/){
$FileType = "<img src='/icons/small/key.gif' alt='[Checksum]'>";
}

if($FileType =~ m/.bz2|.gz|.zip|.rpm/){
$FileType = "<img src='/icons/small/compressed.gif' alt='[Compressed]'>";
}

if($FileType =~ m/.bin|.exe/){
$FileType = "<img src='/icons/small/binary.gif' alt='[Binary]'>";
}

if ($FileType eq $DirChk){
$FileType = "<img src='/icons/small/unknown.gif' alt='[Unknown]'>";
}


$FileList="$FileList<tr><td>$FileType</td><td><a href='$newurl'>$DirChk</a></td><td>$FileDate</td><td>$FileSize Kb</td></tr>";
								
			}
		}
	}
	
	&printdebug('','pass',"Directories found: $DirCount");
	&printdebug('','pass',"Documents found: $FileCount");
	
	$BaseUrl =~ s!/{2,}!/!g;
	$crimp->{PageTitle} = "$BaseUrl";
	
		$newhtml = <<ENDEOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type">
  <title>Index of $BaseUrl</title>
</head>
<body>

<h1>Index of $BaseUrl</h1>
<pre>
<table style='width: 90%; margin-left: auto; margin-right: auto;;'
 border='0' cellpadding='1' cellspacing='1'>
<tbody>
<tr>
<th style="width: 20px;text-align: left;">&nbsp;</th>
<th style="text-align: left;">File Name</th><th style="width: 20%; text-align: left;">Last Modified Date</th><th style="width: 10%; text-align: left;">File Size</th></tr>
<tr>
<td><img src='/icons/small/back.gif' alt='[DIR]'></td><td><a href='../'>Parent Directory</a></td><td>&nbsp;</td><td>&nbsp;</td></tr>
	
	
ENDEOF
	
		if ($DirCount ne 0) { $newhtml = join '',$newhtml,"$DirList"; }
		if ($FileCount ne 0) { $newhtml = join '', $newhtml, "$FileList"; }
		$newhtml = join '', $newhtml, "</tbody></table></pre><br />Number of files served : $FileServed<br /><br />";
		$crimp->{DisplayHtml} = join '', $newhtml, $crimp->{DisplayHtml},"</body></html>";
		
		
		
		

}else{
&printdebug('', 'warn', 'Couldn\'t open directory for listing');
}



}



1;

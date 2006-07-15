package Crimp::ContentListing;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: ContentListing.pm,v 2.5 2006-07-15 16:45:25 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module ContentListing',
		'',
		'Authors: The CRIMP Team',
		"Version: $ID",
		'http://crimp.sourceforge.net/');
	
	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{ContentListing}");
	
	eval "use Time::localtime";
	if ($@) {
		$self->{crimp}->printdebug('','warn','Could not load necessary modules for this plugin:','&nbsp;&nbsp;'.$@);
		return;
	}
	
	my $DirLayout = '<br />';
	my $DirCount = 0;
	my $FileCount = 0;
	my $DownloadFile = '';
	my $FileType = "unknown";
	my $FileDate = "unknown";
	my $FileSize = "unknown";
	
	my $lock = 0;
	
	my $FileServed = $self->{crimp}->FileRead('ContentListing',$self->{crimp}->userConfig,'0');
	$self->{crimp}->printdebug('','',"FileCount: $FileServed");
	$self->{crimp}->printdebug('','','ExitCode: '.$self->{crimp}->ExitCode);
	
	my $FileDir = $self->{crimp}->{ContentListing};
	
	my @HttpRequest = split(/\//,$self->{crimp}->HttpRequest);
	my $BaseUrl = '';
	
	foreach (@HttpRequest) {
		if (-d "$FileDir/$_") {
			$FileDir = join '/', $FileDir, $_;
			$BaseUrl = join '/', $BaseUrl, $_;
		}
		if (($_ ne '') && (grep /.download/, $_)){
			$DownloadFile = $_;
			$DownloadFile =~ s/\.download$//;
		}
	}
	
	$BaseUrl = join '/', $self->{crimp}->userConfig, $BaseUrl unless $BaseUrl =~ m!$self->{crimp}->userConfig!;
	$BaseUrl =~ s!/{2,}!/!g;
	$self->{crimp}->printdebug('','', join(': ', 'FileDir', $FileDir));
	$self->{crimp}->printdebug('','', join(': ', 'BaseUrl', $BaseUrl));
	
	if ($DownloadFile ne ''){
		$self->{crimp}->printdebug('','', join(': ', 'DownloadFile', $DownloadFile));
		$FileServed++;
		$self->{crimp}->FileWrite('ContentListing',$self->{crimp}->userConfig,$FileServed);
		
		#close;
		$self->{crimp}->redirect("$BaseUrl/$DownloadFile") if ($self->{crimp}->ExitCode ne '500');
		return;
	}
	
	if ( !-d $FileDir ) {
		$self->{crimp}->printdebug('', 'warn', 'Configured file is _NOT_ a directory. Bailing out.');
		return;
	}
	
	opendir(DIR, $FileDir) or $self->{crimp}->printdebug('', 'fail', "Could not open the current directory for reading $!");
	rewinddir(DIR);
	my @DirChk = readdir(DIR);
	closedir(DIR);
	foreach $file (@DirChk) {
		if (($file ne '.') && ($file ne '..') && ($file ne 'index.html') && ($file ne 'CVS')) {
			if (-d "$FileDir/$file") {
				$DirCount++;
				$newurl = join '/', $BaseUrl, $file;
				$newurl =~ s!/{2,}!/!g;
				if ($DirCount > 0) {
					$DirList="$DirList<tr><td><img src='/icons/small/dir.gif' alt='[DIR]'/></td><td><font size='-1'><a href='$newurl'>$file</a></font></td><td>&nbsp;</td><td>&nbsp;</td></tr>\n";
				}
			} else {
				$FileCount++;
				
				$file =~ s/\.html$//;
				$newurl = join '/', $BaseUrl, $file;
				$newurl =~ s!/{2,}!/!g;
				
				$newurl = join '', $newurl,'.download';
				$FileType = $file;
				
				my $myfile = join '/', $FileDir, $file;
				$FileDate = ctime((stat($myfile))[9]);
				$FileSize = int(1+(-s $myfile)/10.24)/100;
				
				# should really use given/when statements here - I'll do that when I get around to it (Fremen)
				if($FileType =~ m/(\.patch)$/) {
					$FileType = "<img src='/icons/small/patch.gif' alt='[Patch]'/>";
				} elsif($FileType =~ m/(\.gif|\.jpg|\.png|\.bmp|\.ico)$/) {
					$FileType = "<img src='/icons/small/image.gif' alt='[Image]'/>";
				} elsif($FileType =~ m/(\.mp3|\.wav|\.ogg)$/) {
					$FileType = "<img src='/icons/small/sound.gif' alt='[Audio]'/>";
				} elsif($FileType =~ m/(\.mov|\.avi|\.mpg|\.ram)$/) {
					$FileType = "<img src='/icons/small/movie.gif' alt='[Movie]'/>";
				} elsif($FileType =~ m/(\.txt|\.rtf|\.html)$/) {
					$FileType = "<img src='/icons/small/text.gif' alt='[Text]'/>";
				} elsif($FileType =~ m/(\.doc|\.pdf|\.odt)$/) {
					$FileType = "<img src='/icons/small/doc.gif' alt='[Document]'/>";
				} elsif($FileType =~ m/(\.tar)$/) {
					$FileType = "<img src='/icons/small/tar.gif' alt='[Archive]'/>";
				} elsif($FileType =~ m/(\.sum|md5sum|\.md5)$/) {
					$FileType = "<img src='/icons/small/key.gif' alt='[Checksum]'/>";
				} elsif($FileType =~ m/(\.bz2|\.gz|\.zip|\.rpm)$/) {
					$FileType = "<img src='/icons/small/compressed.gif' alt='[Compressed]'/>";
				} elsif($FileType =~ m/(\.bin|\.exe)$/) {
					$FileType = "<img src='/icons/small/binary.gif' alt='[Binary]'/>";
				} elsif ($FileType eq $file) {
					$FileType = "<img src='/icons/small/unknown.gif' alt='[Unknown]'/>";
				}
				
				$FileList="$FileList<tr><td>$FileType</td><td><font size='-1'><a href='$newurl'>$file</a></font></td><td style='text-align: right;'><font size='-1'>$FileDate</font></td><td style='text-align: right;'><font size='-1'>$FileSize Kb</font></td></tr>\n";
			}
		}
	}
	
	$self->{crimp}->printdebug('','pass',"Directories found: $DirCount");
	$self->{crimp}->printdebug('','pass',"Documents found: $FileCount");
	
	$BaseUrl =~ s!/{2,}!/!g;
	$BaseUrl =~ m!.*/(.+?)/?$!;
	$dirname = $1;
	$self->{crimp}->PageTitle($BaseUrl);
	
	$newhtml = "<h1>Index of $dirname</h1>
<table style='width: 90%; margin-left: auto; margin-right: auto;' border='0' cellpadding='1' cellspacing='1'>
	<tbody>
	<tr>
		<th style='width: 20px;text-align: left;'>&nbsp;</th>
		<th style='text-align: left;'>File Name</th>
		<th style='text-align: right;'>Last Modified Date</th>
		<th style='text-align: right;'>File Size</th>
	</tr>
	<tr>
		<td><img src='/icons/small/back.gif' alt='[DIR]'/></td>
		<td><font size='-1'><a href='../'>Parent Directory</a></font></td>
		<td>&nbsp;</td><td>&nbsp;</td>
	</tr>";
	
	$newhtml = join '',$newhtml,"$DirList\n" if ($DirCount != 0);
	$newhtml = join '', $newhtml, "$FileList\n" if ($FileCount != 0);
	
	$newhtml = join '', $newhtml, "</tbody></table><br />Number of files served : $FileServed<br /><br />";
	
	$self->{crimp}->addPageContent($newhtml);
}

1;

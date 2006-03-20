package Crimp::FileList;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: FileList.pm,v 2.1 2006-03-20 00:49:19 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
	return $self;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module FileList',
				'',
				'Authors: The CRIMP Team',
				'Version: '.$self->{id},
				'http://crimp.sourceforge.net/'
				);
	
	$self->{crimp}->printdebug('','','Started With: '.$self->{crimp}->{FileList});
	
	my $DirList = '<b>Directories</b><br />&nbsp;&nbsp;&nbsp;';
	my $FileList = '<b>Documents</b><br />&nbsp;&nbsp;&nbsp;';
	my $DirLayout = '<br />&nbsp;&nbsp;&nbsp;';
	my $DirCount = 0;
	my $FileCount = 0;
	
	
	#Depends on ContentDirectory
	if (defined $self->{crimp}->{ContentDirectory}) {
		$DirList = '<b>Directories:</b>';
		$FileList = '<b>Documents:</b>';
		
		if ($self->{crimp}->{FileList} eq 'horizontal') { 
			$DirLayout = ' | ';
			$DirList = join '', $DirList, ' ';
			$FileList = join '', $FileList, ' ';
		} else {
			$DirLayout = '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
			$DirList = join '', $DirList, '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
			$FileList = join '', $FileList, '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
		}
		
		my $FileDir = $self->{crimp}->{ContentDirectory};
		
		my @HttpRequest = split(/\//,$self->{crimp}->HttpRequest);
		my $BaseUrl = '';
		
		foreach (@HttpRequest) {
			if (-d "$FileDir/$_") {
				$FileDir = join '/', $FileDir, $_;
				$BaseUrl = join '/', $BaseUrl, $_;
			}
		}
		
		$BaseUrl = join '/', $self->{crimp}->userConfig, $BaseUrl unless $BaseUrl =~ m!$self->{crimp}->userConfig!;
		$BaseUrl =~ s!/{2,}!/!g;
		$self->{crimp}->printdebug('','', join(': ', 'FileDir', $FileDir));
		$self->{crimp}->printdebug('','', join(': ', 'BaseUrl', $BaseUrl));
		
		if (( -d $FileDir )) {
			opendir(DIR, $FileDir) or $self->{crimp}->printdebug('', 'warn', 'Could not open the current directory for reading:',$!);
			rewinddir(DIR);
			my @DirChk = readdir(DIR);
			closedir(DIR);
			
			foreach my $file (@DirChk) {
				if (($file ne '.') && ($file ne '..') && ($file ne 'index.html') && ($file ne 'CVS')) {
					if (-d "$FileDir/$file") {
						$DirCount ++;
						$newurl = join '/', $BaseUrl, $file;
						$newurl =~ s!/{2,}!/!g;
						$DirList = join '', $DirList, $DirLayout if ($DirCount != 1);
						$DirList = "$DirList<a href='$newurl'>$file</a>\n";
					} elsif ($file =~ m/.html$/) {
						$FileCount ++;
						$file =~ s/(\.html){1}$//;
						$newurl = join '/', $BaseUrl, $file;
						$newurl =~ s!/{2,}!/!g;
						$newurl = join '', $newurl,'.html';
						$FileList = join '', $FileList, $DirLayout if ($FileCount != 1);
						$FileList="$FileList<a href='$newurl'>$file</a>\n";
					}
				}
			}
			
			$self->{crimp}->printdebug('','pass',"Directories found: $DirCount");
			$self->{crimp}->printdebug('','pass',"Documents found: $FileCount");
			
			my $newhtml = '';
			if ( ($DirCount + $FileCount) != 0 ) {
				$newhtml = join('', $newhtml, $DirList) if ($DirCount != 0);
				$newhtml = join('', $newhtml, '<br />') if (($DirCount != 0) && ($FileCount != 0));
				$newhtml = join('', $newhtml, $FileList) if ($FileCount != 0);
				
				$self->{crimp}->addMenuContent($newhtml);
			}
		} else {
			$self->{crimp}->printdebug('', 'warn', 'Couldn\'t open directory for listing');
		}
	} else {
		$self->{crimp}->printdebug('','warn','This module depends on the ContentDirectory module');
	}
}


1; 

$ID = q$Id: ContentDirectory.pm,v 1.14 2005-11-28 21:42:52 deadpan110 Exp $;
&printdebug('Module ContentDirectory',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

@HttpRequest = split(/\//,$crimp->{HttpRequest});

foreach $HttpRequest (@HttpRequest){
	#printdebug "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
	if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
}

if ($path eq '') { $path = '/index.html'; }

if ($crimp->{DisplayHtml} ne "" ){
	&printdebug("","warn", "DisplayHtml has already been filled with content");
}else{
	#check for directory here if it is then use $path
	#make sure the requested file is _NOT_ a directory (Fremen)
	my $requested = join('',$crimp->{ContentDirectory}, $path);
	if ( -d $requested ) { $requested = join '/', $requested, 'index.html'; }
	#my $requested = "$crimp->{HomeDirectory}$crimp->{ContentDirectory}$path";


# Use error page
if (( !-e $requested )||( -d $requested )){
&printdebug('', 'warn', 'Couldn\'t open file for reading',
				 "file: $requested",
				 "error: $!",
				 "Using $crimp->{ErrorDirectory}/404.html for content"
				 );

$requested = join '/', $crimp->{ErrorDirectory}, '404.html';
$crimp->{ExitCode} = '404';

}



#
#sysopen (FILE,$crimp->{DocumentTemplate}, O_RDONLY) or &printdebug('','Warn',"Template $crimp->{DocumentTemplate} not found");
#		@template_content=<FILE>;
#		#$SIZE=@LINES;
#		$status = 'pass';
#		close(FILE);
#		if (@template_content) {
#			my $new_content = '';
#				foreach $template_line(@template_content) {
#		  		$new_content = join '', $new_content, $template_line;
#			}
#		


   if (( -e $requested ) && ( !-d $requested )) {
		sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
		
		
			@display_content=<FILE>;
			close(FILE);
			
		if (@display_content) {	
			my $new_content='';
			
			####
			foreach $display_content(@display_content) {
				$new_content= join '', $new_content, $display_content;
			}
			
			
			$crimp->{DisplayHtml} = $new_content;
			
			####
if	($crimp->{ExitCode} ne '404'){$crimp->{ExitCode} = '200';}

			&printdebug('','pass',"DisplayHtml filled with content from '$requested'");
			#$crimp->{DisplayHtml}=@display_content;
		} else {
			&printdebug('','warn','The file handle is invalid. This should not happen.');
		}
	} else {
		$crmip->{DisplayHtml} = 'Could not get the requested content. Please check the link and try again.';
		if (!-e $requested) {
			&printdebug('','warn',"$requested does not exist.");
		} else {
			&printdebug('','warn',"$requested is a directory.");
		}
	}
}

1;
&printdebug('Module ContentDirectory',
			'',
			'Authors: The CRIMP Team',
			'Version: 1.0',
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
	if ( -d $requested ) {$requested = "$requested/index.html";}
#my $requested = "$crimp->{HomeDirectory}$crimp->{ContentDirectory}$path";

#&printdebug("$crimp->{HomeDirectory}","","$requested");

   if ( !-e $requested ) {$crimp->{ExitCode} = '404'; }
   if ( -d $requested ) { $crimp->{ExitCode} = '404'; }
	sysopen (FILE,"$requested",O_RDONLY) || &printdebug("", 'warn', "Couldn't open file for reading", "file: $requested", "error: $!");
	
    @display_content=<FILE>;
    close(FILE);
    
    my $new_content='';
    
    ####
    foreach $display_content(@display_content) {
        $new_content= "$new_content$display_content";
    }
    
	#remove xml header if present
	$new_content =~ s|<\?xml.*?\?>||i;
	#remove doctype if present
	$new_content =~ s|<!DOCTYPE.*?>||i;
	#remove headers storing the title of the page
	$new_content =~ s|<title>(.*?)</title>||si;
	
	$crimp->{PageTitle} = $1;
	if ($crimp->{PageTitle} eq ''){
	&printdebug("","warn","The Page has no title");
	}else{
	&printdebug("","pass","PageTitle: $crimp->{PageTitle}");
	}
	
	#strip from <html> down to the opening <body> tag
	$new_content =~ s|<html.*?>.*?<body>||si;
	#remove the closing </body> tag and any cruft after - alas, that's nothing to do with the dogshow
	$new_content =~ s|</body>.*||si;
    
    $crimp->{DisplayHtml} = $new_content;
    
    ####
  #  $crimp->{ExitCode} = '200';
   &printdebug("","pass","DisplayHtml filled with content: $requested");
    #$crimp->{DisplayHtml}=@display_content;
}

1;
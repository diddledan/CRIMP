@HttpRequest = split(/\//,$crimp->{HttpRequest});

foreach $HttpRequest (@HttpRequest){
    #printdebug "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
    if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
}

if ($path eq '') { $path = '/index.html'; }

if ($crimp->{DisplayHtml} ne "" ){
    &printdebug("Module 'ContentDirectory'","warn", "DisplayHtml has already been filled with content");
}else{
    #check for directory here if it is then use $path
    #make sure the requested file is _NOT_ a directory (Fremen)
    if ( -d join('', $crimp->{ContentDirectory}, $path) ) { &printdebug("Module 'ContentDirectory'", 'fail', "$crimp->{ContentDirectory}$path is a directory. I cannot open this."); }
    sysopen (FILE,"$crimp->{ContentDirectory}$path",O_RDONLY) or &printdebug("Module 'ContentDirectory'", 'fail', "Couldn't open file for reading", "file: $crimp->{ContentDirectory}$path", "error: $!");
    @display_content=<FILE>;
    close(FILE);
    
    my $new_content='';
    
    ####
    foreach $display_content(@display_content) {
        $new_content= "$new_content$display_content\n\n";
    }
    
    $crimp->{DisplayHtml} = $new_content;
    
    ####
    &printdebug("Module 'ContentDirectory'","pass","Started With: $crimp->{ContentDirectory}");
    #$crimp->{DisplayHtml}=@display_content;
}

1;
#

my $new_content="";



@HttpRequest = split(/\//,$crimp->{HttpRequest});
$a=0;

foreach $HttpRequest (@HttpRequest){
#printdebug "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
$a++;
}




if ($crimp->{DisplayHtml} ne "" ){&printdebug("Module 'ContentDirectory'","warn",
		"DisplayHtml has already been filled with content"
	);
}
else{



#check for directory here if it is then use &$path
sysopen (FILE,"$crimp->{ContentDirectory}$path", O_RDONLY) or die @_;
@display_content=<FILE>;
#$SIZE=@LINES;
$status = "pass";
close(FILE);


####
foreach $display_content(@display_content) {
#printdebug ("parsing template $a ");
$a++;

#chop($template_content) if $line =~ /\n$/;

#

#while ($display_content =~ /<!--PAGE_CONTENT-->/gi){
#printdebug ("Putting Page into Template");
#$template_content =~ s//$crimp->{DisplayHtml}/g;;
#}


$new_content= "$new_content$display_content\n\n";
    
}


$crimp->{DisplayHtml} = $new_content;
####







&printdebug("Module 'ContentDirectory'","pass","Started With: $crimp->{ContentDirectory}");

#$crimp->{DisplayHtml}=@display_content;

}



1;
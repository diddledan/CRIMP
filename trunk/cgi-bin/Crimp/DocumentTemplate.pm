#language pack

my $new_content="";

@HttpRequest = split(/\//,$crimp->{HttpRequest});
$a=0;

foreach $HttpRequest (@HttpRequest){
#print "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
$a++;
}



sysopen (FILE,"$crimp->{DocumentTemplate}", O_RDONLY) or exit;
@template_content=<FILE>;
#$SIZE=@LINES;
$status = "pass";
close(FILE);


$a=1;
foreach $template_content(@template_content) {
#printdebug ("parsing template $a ");
$a++;

#chop($template_content) if $line =~ /\n$/;

#

while ($template_content =~ /<!--PAGE_CONTENT-->/gi){
#printdebug ("Putting Page into Template");
$template_content =~ s//$crimp->{DisplayHtml}/g;;
}

$new_content= "$new_content$template_content\n\n";
    
}


$crimp->{DisplayHtml} = $new_content;






&printdebug("Module 'DocumentTemplate'","$status","Started With: $crimp->{DocumentTemplate}");


1;







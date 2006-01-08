$ID = q$Id: RandomContent.pm,v 1.1 2006-01-08 15:30:17 deadpan110 Exp $;
&printdebug('Module RandomContent',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
			


if($crimp->{RandomContent} =~ m/(.txt)$/){

	&printdebug('','',"Started With: $crimp->{RandomContent}");

}
else{

	&printdebug('','warn',"File extension must be *.txt");

}

if ( -f "$crimp->{VarDirectory}/$crimp->{RandomContent}" ){

	srand(time);
	sysopen (FILE,"$crimp->{VarDirectory}/$crimp->{RandomContent}",O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
		@FileRead=<FILE>;
		close(FILE);

	$NbLines = @FileRead;
	$Phrase = $FileRead[int rand $NbLines];

if ($crimp->{DisplayHtml} eq ""){

$crimp->{RandomContent} =~ s/(\.txt){1}$//;


$crimp->{DisplayHtml} = <<ENDEOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type"/>
<title>$crimp->{RandomContent}</title>
</head>
<body>
$Phrase
</body>
</html>

	
ENDEOF

}
else{

$newhtml = "<div id=\"crimpRandomContent\">\n$Phrase\n</div>";

}


#$crimp->{DisplayHtml} = "$newhtml\n$crimp->{DisplayHtml}";

$crimp->{DisplayHtml} =~ s/<body>/<body>$newhtml/i;


}
else{
&printdebug('','',"$crimp->{RandomContent} does not exist!");
}

1;
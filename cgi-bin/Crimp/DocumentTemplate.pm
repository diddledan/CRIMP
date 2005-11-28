$ID = q$Id: DocumentTemplate.pm,v 1.10 2005-11-28 19:44:45 deadpan110 Exp $;
&printdebug('Module DocumentTemplate',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
			
&printdebug('',$status,"Started With: $crimp->{DocumentTemplate}");

my $blankTemplate = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><!--TITLE--></title>
</head>
<body>
<!--PAGE_CONTENT-->
</body></html>';

#only parse the template if this is an html or xhtml page
if (($crimp->{ContentType} eq 'text/html') || ($crimp->{ContentType} eq 'text/xhtml+xml')) {
	# This should also be set within the query string '?DocumentTemplate=[none|off]'
	if (($crimp->{DocumentTemplate} eq 'none') || ($crimp->{DocumentTemplate} eq 'off')) {
		&printdebug('','pass','A blank template is being used');
		&insertContent($blankTemplate);
	} else {
		@HttpRequest = split(/\//,$crimp->{HttpRequest});
		foreach $HttpRequest (@HttpRequest){
			#print "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
			if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
		}
	
		sysopen (FILE,$crimp->{DocumentTemplate}, O_RDONLY) or &printdebug('','Warn',"Template $crimp->{DocumentTemplate} not found");
		@template_content=<FILE>;
		#$SIZE=@LINES;
		$status = 'pass';
		close(FILE);
		if (@template_content) {
			my $new_content = '';
				foreach $template_line(@template_content) {
		  		$new_content = join '', $new_content, $template_line;
			}
		
			#printdebug ("Putting Page into Template");
			
			&insertContent($new_content);
		} else {
			&printdebug('','warn','Template file does not contain any content, using default blank template.');
			&insertContent($blankTemplate);
		}
	}
} else {
	&printdebug('', 'pass', "Skipped module for ContentType: $crimp->{ContentType}");
}

sub insertContent {
	my $template = shift;


			#remove xml header if present
			$crimp->{DisplayHtml} =~ s|<\?xml.*?\?>||i;
			#remove doctype if present
			$crimp->{DisplayHtml} =~ s|<!DOCTYPE.*?>||i;
			#remove headers storing the title of the page
			$crimp->{DisplayHtml} =~ s|<title>(.*?)</title>||si;
			
			$crimp->{PageTitle} = $1;
			if ($crimp->{PageTitle} eq ''){
				&printdebug('','warn','The Page has no title');
			}else{
				&printdebug('','pass',"PageTitle: $crimp->{PageTitle}");
			}
			
			#strip from <html> down to the opening <body> tag
			$crimp->{DisplayHtml} =~ s|<html.*?>.*?<body>||si;
			#remove the closing </body> tag and any cruft after - alas, that's nothing to do with the dogshow
			$crimp->{DisplayHtml} =~ s|</body>.*||si;
			
	
	$template =~ s/<!--TITLE-->/$crimp->{PageTitle} - $Config->{_}->{SiteTitle}/gi;
	$template =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
	if ($crimp->{PageTitle} ne ""){
$crimp->{PageTitle} = join '', ' - ', $crimp->{PageTitle};
$crimp->{DisplayHtml} =~ s|(</title>)|$crimp->{PageTitle}\1|i;;
}
	
	$crimp->{DisplayHtml} = $template;
}

1;
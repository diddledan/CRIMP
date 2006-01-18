$ID = q$Id: DocumentTemplate.pm,v 1.14 2006-01-18 16:26:12 diddledan Exp $;
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
<title>'.$Config->{_}->{SiteTitle}.'</title>
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
	$crimp->{DisplayHtml} =~ s|<\?xml.*?\?>||si;
	#remove doctype if present
	$crimp->{DisplayHtml} =~ s|<!DOCTYPE.*?>||si;
	#remove headers storing the title of the page
	$crimp->{DisplayHtml} =~ s|<title>(.*?)</title>||si;
	#if we insert content then this is important
	$crimp->{PageTitle} = $1;
	
	#strip from <html> down to the opening <body> tag
	$crimp->{DisplayHtml} =~ s|<html.*?>.*?<body>||si;
	#remove the closing </body> tag and any cruft after - alas, that's nothing to do with the dogshow
	$crimp->{DisplayHtml} =~ s|</body>.*||si;
	
	if ($crimp->{PageTitle} eq '') {
		&printdebug('','warn','The Page has no title');
	} else {
		&printdebug('','pass',"PageTitle: $crimp->{PageTitle}");
		$crimp->{PageTitle} = join '', ' - ', $crimp->{PageTitle};
		$template =~ s|(</title>)|$crimp->{PageTitle}\1|i;;
	}
	
	$template =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
	$crimp->{DisplayHtml} = $template;
}

1;
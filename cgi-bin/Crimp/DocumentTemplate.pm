$ID = q$Id: DocumentTemplate.pm,v 1.9 2005-11-25 16:20:45 diddledan Exp $;
&printdebug('Module DocumentTemplate',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

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
			&printdebug('',$status,"Started With: $crimp->{DocumentTemplate}");
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
	$template =~ s/<!--TITLE-->/$crimp->{PageTitle} - $Config->{_}->{SiteTitle}/gi;
	$template =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
	$crimp->{DisplayHtml} = $template;
}

1;
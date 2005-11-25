$ID = q$Id: DocumentTemplate.pm,v 1.8 2005-11-25 08:13:09 ind-network Exp $;
&printdebug('Module DocumentTemplate',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

# This should also be set within the query string '?DocumentTemplate=[none|off]'
if (($crimp->{DocumentTemplate} eq 'none')||($crimp->{DocumentTemplate} eq 'off')){
	&printdebug("","pass","The template has been disabled");
}else{

#only parse the template if this is an html or xhtml page
	if (($crimp->{ContentType} eq 'text/html') || ($crimp->{ContentType} eq 'text/xhtml+xml')) {
		@HttpRequest = split(/\//,$crimp->{HttpRequest});
		foreach $HttpRequest (@HttpRequest){
		  #print "$crimp->{HttpRequest} :: $HttpRequest :: $crimp->{UserConfig}<br>";
		  if ($crimp->{UserConfig} ne "/$HttpRequest"){$path = "$path/$HttpRequest";}
		}
	
		sysopen (FILE,$crimp->{DocumentTemplate}, O_RDONLY) or &printdebug("","Warn","Template $crimp->{DocumentTemplate} not found");
		@template_content=<FILE>;
	#$SIZE=@LINES;
		$status = 'pass';
		close(FILE);
		if (@template_content){
			my $new_content = '';
				foreach $template_line(@template_content) {
		  		$new_content = join '', $new_content, $template_line;
				}
	
	#printdebug ("Putting Page into Template");
			$new_content =~ s/<!--TITLE-->/$crimp->{PageTitle} - $Config->{_}->{SiteTitle}/gi;
			$new_content =~ s/<!--PAGE_CONTENT-->/$crimp->{DisplayHtml}/gi;
	
			$crimp->{DisplayHtml} = $new_content;
		}
		
		&printdebug("","$status","Started With: $crimp->{DocumentTemplate}");
	} else {
		&printdebug('', 'pass', "Skipped module for ContentType: $crimp->{ContentType}");
	}
}

1;
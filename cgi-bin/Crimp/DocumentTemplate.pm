package Crimp::DocumentTemplate;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: DocumentTemplate.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
	return $self;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module DocumentTemplate',
				'',
				'Authors: The CRIMP Team',
				"Version: $self->{id}",
				'http://crimp.sourceforge.net/'
				);
	
	if (-e $self->{crimp}->{DocumentTemplate}) {
		$self->{crimp}->printdebug('','pass',"Started With: $self->{crimp}->{DocumentTemplate}");
	} else {
		$self->{crimp}->printdebug('','warn','Template file does not exist, using default empty template');
		$self->{crimp}->{DocumentTemplate} = 'none';
	}

	my $blankTemplate = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	<title>'.$self->{crimp}->{Config}->{_}->{SiteTitle}.'</title>
	</head>
	<body>
	<!--PAGE_CONTENT-->
	</body></html>';

	#only parse the template if this is an html or xhtml page
	if (($self->{crimp}->ContentType eq 'text/html') || ($self->{crimp}->ContentType eq 'text/xhtml+xml')) {
		# This should also be set within the query string '?DocumentTemplate=[none|off]'
		## see $self->{crimp}->queryParam('DocumentTemplate') :-) Fremen
		if (($self->{crimp}->{DocumentTemplate} eq 'none') || ($self->{crimp}->{DocumentTemplate} eq 'off')) {
			#this should not be needed and will eventually be replaced with return 1;
			$self->{crimp}->printdebug('','pass','A blank template is being used');
			$self->insertContent($blankTemplate);
		} else {
			sysopen (FILE,$self->{crimp}->{DocumentTemplate}, O_RDONLY) or $self->{crimp}->printdebug('','warn',"Template $self->{crimp}->{DocumentTemplate} not found");
			@template_content=<FILE>;
			close(FILE);
			
			if (@template_content) {
				my $template = '';
				foreach (@template_content) {
					$template = "$template$_";
				}
				
				$self->insertContent($template);
			} else {
				$self->{crimp}->printdebug('','warn','Template file does not contain any content, using default blank template.');
				$self->insertContent($blankTemplate);
			}
		}
	} else {
		$self->{crimp}->printdebug('', 'pass', "Skipped module for ContentType: $crimp->{ContentType}");
	}
}

sub insertContent {
	my $self = shift;
	my $template = shift;

	#remove xml header if present
	$self->{crimp}->{DisplayHtml} =~ s|<\?xml.*?\?>||si;
	#remove doctype if present
	$self->{crimp}->{DisplayHtml} =~ s|<!DOCTYPE.*?>||si;
	#remove headers storing the title of the page
	$self->{crimp}->{DisplayHtml} =~ s|<title>(.*?)</title>||si;
	#if we insert content then this is important
	my $pageTitle = $1;
	
	#strip from <html> down to the opening <body> tag
	$self->{crimp}->{DisplayHtml} =~ s|<html.*?>.*?<body.*?>||si;
	#remove the closing </body> tag and any cruft after - alas, that's nothing to do with the dogshow
	$self->{crimp}->{DisplayHtml} =~ s|</body>.*||si;
	
	if ($pageTitle eq '') {
		$self->{crimp}->printdebug('','warn','The Page has no title');
	} else {
		$self->{crimp}->printdebug('','pass','PageTitle: '.$pageTitle);
		$template =~ s|(</title>)|$pageTitle\1|i;;
	}
	
	$template =~ s/<!--PAGE_CONTENT-->/$self->{crimp}->{DisplayHtml}/gi;
	
	$self->{crimp}->{DisplayHtml} = $template;
}

1;

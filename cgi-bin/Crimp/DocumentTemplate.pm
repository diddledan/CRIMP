package Crimp::DocumentTemplate;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: DocumentTemplate.pm,v 2.2 2006-07-27 23:12:04 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
	return $self;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	
	$crimp->printdebug('',
				'',
				'Authors: The CRIMP Team',
				"Version: $self->{id}",
				'http://crimp.sourceforge.net/'
				);

	#only parse the template if this is an html or xhtml page
	unless (($crimp->ContentType eq 'text/html') || ($crimp->ContentType eq 'text/xhtml+xml')) {
		$crimp->printdebug('', 'pass', "Skipped module for ContentType: $crimp->{ContentType}");
		return;
	}
	
	$templatePath = join '/', $crimp->Config('TemplateDir'), $crimp->{DocumentTemplate};
	if (-e $templatePath) {
		$crimp->printdebug('','pass',"Started With: $templatePath");
	} else {
		$crimp->printdebug('','warn',"Template file ($templatePath) does not exist, using default empty template");
		$crimp->{DocumentTemplate} = 'none';
	}

	my $blankTemplate = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	<title></title>
	</head>
	<body>
	<!--PAGE_CONTENT-->
	</body></html>';

	# This should also be set within the query string '?DocumentTemplate=[none|off]'
	## see $crimp->queryParam('DocumentTemplate') :-) Fremen
	if (($crimp->{DocumentTemplate} eq 'none') || ($crimp->{DocumentTemplate} eq 'off')) {
		#this should not be needed and will eventually be replaced with return 1;
		$crimp->printdebug('','pass','A blank template is being used');
		$self->insertContent($blankTemplate);
	} else {
		sysopen (FILE,$templatePath, O_RDONLY) or $crimp->printdebug('','warn',"Template $templatePath not found");
		@template_content=<FILE>;
		close(FILE);
		
		if (@template_content) {
			my $template = '';
			foreach (@template_content) {
				$template = "$template$_";
			}
			
			$self->insertContent($template);
		} else {
			$crimp->printdebug('','warn','Template file does not contain any content, using default blank template.');
			$self->insertContent($blankTemplate);
		}
	}
}

sub insertContent {
	my $self = shift;
	my $crimp = $self->{crimp};
	my $template = shift;

	my ($null,$content) = $crimp->stripHtmlHeaderFooter($crimp->{DisplayHtml});
	my $pageTitle = $crimp->PageTitle();
	if ($pageTitle eq '') {
		$crimp->printdebug('','warn','The Page has no title');
	} else {
		$crimp->printdebug('','pass','PageTitle: '.$pageTitle);
		$template =~ s|(</title>)|$pageTitle\1|i;;
	}
	
	$template =~ s/<!--PAGE_CONTENT-->/$content/gi;
	
	$crimp->{DisplayHtml} = $template;
}

1;

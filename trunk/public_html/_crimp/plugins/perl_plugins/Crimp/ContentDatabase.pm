package Crimp::ContentDatabase;

use DBI;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: ContentDatabase.pm,v 1.1 2006-11-30 16:48:09 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
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

	#get the configuration values
	$db_type = $crimp->Config('ContentDatabase','DBType');
	$db_db = $crimp->Config('ContentDatabase','DBName');
	$db_host = $crimp->Config('ContentDatabase','DBHost');
	$db_user = $crimp->Config('ContentDatabase','DBUser');
	$db_pass = $crimp->Config('ContentDatabase','DBPass');
	$db_table = $crimp->{ContentDatabase};

	#connect to the database
	my $dbh;
	eval {$dbh = DBI->connect("DBI:$db_type:database=$db_db:host=$db_host", $db_user, $db_pass, {'RaiseError' => 1, 'PrintError' => 0});};
	if ($@) {
		$crimp->printdebug('','warn','Could not connect to database:',"&nbsp;&nbsp;$@");
		$crimp->errorPage('ContentDatabase', '500');
		return;
	}

	#get the path to pull out of the database
	my @HttpRequest = split '/', $crimp->HttpRequest;
	my $path = '';
	foreach (@HttpRequest){
		$path = join('/', $path, $_) if $crimp->userConfig ne "/$_";
	}

	#strip all preceeding slashes (/)
	$path =~ s|^/+||;
	#make sure the path is _ALWAYS_ set - 'root' = the base page for the section
	$path ||= 'root';

	#prepare the query
	$sth = $dbh->prepare("SELECT content FROM `$db_table` WHERE path='$path' LIMIT 1");
	#execute the query in an eval block so that we can catch any errors
	eval {$sth->execute()};

	#this stuff should speak for itself
	if ($@) {
		$crimp->errorPage('ContentDatabase', '500');
		$crimp->printdebug('', 'warn', 'Could not query the content for this page:', $@);
		return;
	}

	if (!$sth->rows) {
		$crimp->errorPage('ContentDatabase', '404');
		$crimp->printdebug('', 'warn', 'The database returned no results');
		return;
	}

	$ref = $sth->fetchrow_hashref();
	my $content = '';
	if (substr($ref->{'content'}, 0, 5) ne '#PERL') {
		($title,$content) = $crimp->stripHtmlHeaderFooter($ref->{'content'});
		$crimp->printdebug('', 'pass', 'Content retreived from database and sent to the templating engine.');
		$crimp->ExitCode('200');
		$crimp->PageTitle($title);
		$crimp->addPageContent($content);
		return;
	}

	#evaluate the code from the database
	eval $ref->{'content'};
	if ($@) {
		$crimp->errorPage('ContentDatabase', '500');
		$crimp->printdebug('', 'warn', 'Errors running the script from the database for this page:', $@);
		return;
	}

	if ($content eq '') {
		$content = 'Nothing to display....';
		$crimp->printdebug('', 'warn', 'The code from the database failed to return any content.');
		return;
	}
}

# this sub is for creating a link that references to the correct location on the web
# for a virtual directory's sub elements. This was developed so that the perl code
# in the database can create links to other sections within the database.
# You pass to it a relative url (eg. fremen/blog) and it outputs the full _local_ url
# to that resource (eg. /crimp/virtual/dir/fremen/blog).
sub makelink {
	my $self = shift;
	#get relative url
	my $link = shift;
	#join it with the url to the root of the section
	$link = join '/', $crimp->{UserConfig}, $link;
	#remove double+ slashes that may have creeped in
	$link =~ s!/{2,}!/!g;
	#return it to the calling code
	return $link;
}

1;

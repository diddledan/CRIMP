package Crimp::ContentDatabase;

sub new {
  my ($class, $crimp) = @_;
  my $self = { id => q$Id: ContentDatabase.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp, };
  bless $self, $crimp;
}

sub execute {
  my $self = shift;
  
  $self->{crimp}->printdebug('Module ContentDatabase',
			'',
			'Authors: The CRIMP Team',
			"Version: $self->{id}",
			'http://crimp.sourceforge.net/'
			);
  
  eval "use DBI";
  if ($@) {
    $self->{crimp}->printdebug('','warn','DBI Module unable to load:','&nbsp;&nbsp;'.$@);
    return;
  }
  
  
  #get the configuration values
  $db_type = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBType};
  $db_db = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBName};
  $db_table = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBTable};
  $db_host = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBHost};
  $db_user = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBUserName};
  $db_pass = $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{DBUserPass};
  
  #connect to the database
  my $dbh = DBI->connect("DBI:$db_type:database=$db_db:host=$db_host", $db_user, $db_pass, {'RaiseError' => 1, 'PrintError' => 0});
  
  #get the path to pull out of the database
  my @HttpRequest = split '/', $self->{crimp}->HttpRequest;
  my $path = '';
  foreach (@HttpRequest){
    if ($self->{crimp}->userConfig ne "/$_") { $path = join '/', $path, $_; }
  }
  
  #strip all preceeding slashes (/)
  $path =~ s|^/+||;
  #make sure the path is _ALWAYS_ set - 'root' = the base page for the section
  $path ||= 'root'
  
  #prepare the query
  $sth = $dbh->prepare("SELECT content,title FROM `$db_table` WHERE path='$path' LIMIT 1");
  #execute the query in an eval block so that we can catch any errors
  eval {$sth->execute()};
  
  #this stuff should speak for itself
  if (!$@) {
    if ($sth->rows) {
      $ref = $sth->fetchrow_hashref();
      my $content = '';
      if (substr($ref->{'content'}, 0, 5) eq '#PERL') {
        #evaluate the code from the database
        eval $ref->{'content'};
        if (!$@) {
          if ($content ne '') {
            $self->{crimp}->printdebug('', 'pass', 'Successfully parsed the content from the database.');
          } else {
            $content = 'Nothing to display....';
            $self->{crimp}->printdebug('', 'warn', 'The code from the database failed to return any content.');
          }
        } else {
          $content = 'ERROR evaluating page content';
          $self->{crimp}->printdebug('', 'warn', 'Errors running the script from the database for this page:', $@);
        }
      } else {
        $content = $ref->{'content'};
        $self->{crimp}->printdebug('', 'pass', 'Content retreived from database and sent to the templating engine.'); 
      }
      $self->{crimp}->ExitCode('200');
      $self->{crimp}->PageTitle($ref->{'title'});
      $self->{crimp}->addPageContent($content);
    } else {
      $self->{crimp}->addPageContent('Error 404, not found.');
      $self->{crimp}->ExitCode('404');
      $self->{crimp}->printdebug('', 'warn', 'The database returned no results, hence we are at a 404 state.');
    }
  } else {
    $self->{crimp}->addPageContent('<span style="color: #f00;">Database Error</span>');
    $self->{crimp}->printdebug('', 'warn', 'Could not query the content for this page:', $@);
  }
}
  
# this sub is for creating a link that references to the correct location on the web
# for a virtual directory's sub elements. This was developed so that the perl code
# in the database can create links to other sections within the database.
# You pass to it a relative url (eg. fremen/blog) and it outputs the full _local_ url
# to that resource (eg. /crimp/virtual/dir/fremen/blog).
sub makelink {
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

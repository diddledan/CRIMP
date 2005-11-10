use DBI;
#get the configuration values
$db_type = $Config->{$crimp->{UserConfig}}->{DBType};
$db_db = $Config->{$crimp->{UserConfig}}->{DBName};
$db_table = $Config->{$crimp->{UserConfig}}->{DBTable};
$db_host = $Config->{$crimp->{UserConfig}}->{DBHost};
$db_user = $Config->{$crimp->{UserConfig}}->{DBUserName};
$db_pass = $Config->{$crimp->{UserConfig}}->{DBUserPass};

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

#connect to the database
my $dbh = DBI->connect("DBI:$db_type:database=$db_db:host=$db_host", $db_user, $db_pass, {'RaiseError' => 1, 'PrintError' => 0});

#get the path to pull out of the database
my @HttpRequest = split '/', $crimp->{HttpRequest};
my $path = '';
foreach $HttpRequest (@HttpRequest){
  if ($crimp->{UserConfig} ne "/$HttpRequest") { $path = join '/', $path, $HttpRequest; }
}
#strip all preceeding slashes (/)
$path =~ s|^/+||;
#make sure the path is _ALWAYS_ set - 'root' = the base page for the section
if ($path eq '') { $path = 'root'; }

#prepare the query
$sth = $dbh->prepare("SELECT content FROM `$db_table` WHERE path='$path' LIMIT 1");
#execute the query in an eval block so that we can catch any errors
eval {$sth->execute();};

#this stuff should speak for itself
if (!$@) {
  if ($sth->rows) {
    $ref = $sth->fetchrow_hashref();
    my $content = '';
    #evaluate the code from the database
    eval $ref->{'content'};
    if (!$@) {
      if ($content ne '') {
        $crimp->{DisplayHtml} = $content;
        &printdebug('Module \'ContentDatabase\'', 'pass', 'Successfully parsed the content from the database.');
      } else {
        $crimp->{DisplayHtml} = 'Nothing to display....';
        &printdebug('Module \'ContentDatabase\'', 'warn', 'The code from the database failed to return any content.');
      } 
    } else {
      $crimp->{DisplayHtml} = 'ERROR evaluating page content';
      &printdebug('Module \'ContentDatabase\'', 'warn', 'Errors running the script from the database for this page:', $@);
    }
  } else {
    $crimp->{DisplayHtml} = 'Error 404, not found.';
    &printdebug('Module \'ContentDatabase\'', 'warn', 'The database returned no results, hence we are at a 404 state.');
  }
} else {
  $crimp->{DisplayHtml} = '<span style="color: #f00;">Database Error</span>';
  &printdebug('Module \'ContentDatabase\'', 'warn', 'Could not query the content for this page:', $@);
}

1;

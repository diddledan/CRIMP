$ID = q$Id: ContentDatabase.pm,v 1.11 2006-02-04 21:29:25 diddledan Exp $;
&printdebug('Module ContentDatabase',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);

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
$sth = $dbh->prepare("SELECT content,title FROM `$db_table` WHERE path='$path' LIMIT 1");
#execute the query in an eval block so that we can catch any errors
eval {$sth->execute();};

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
          &printdebug('', 'pass', 'Successfully parsed the content from the database.');
        } else {
          $content = $crimp->{DefaultHtml};
          $content =~ s/(<body>)/\1Nothing to display..../i;
          &printdebug('', 'warn', 'The code from the database failed to return any content.');
        }
      } else {
        $content = $crimp->{DefaultHtml};
        $content =~ s/(<body>)/\1ERROR evaluating page content/i;
        &printdebug('', 'warn', 'Errors running the script from the database for this page:', $@);
      }
    } else {
      $content = $ref->{'content'};
      &printdebug('', 'pass', 'Content retreived from database and sent to the templating engine.'); 
    }
    $crimp->{ExitCode} = '200';
    $crimp->{PageTitle} = $ref->{'title'};
    $crimp->{DisplayHtml} = $content;
  } else {
    $crimp->{DisplayHtml} = $crimp->{DefaultHtml};
    $crimp->{DisplayHtml} =~ s/(<body>)/\1Error 404, not found./i;
    $crimp->{ExitCode} = '404';
    &printdebug('', 'warn', 'The database returned no results, hence we are at a 404 state.');
  }
} else {
  $crimp->{DisplayHtml} = $crimp->{DefaultHtml};
  $crimp->{DisplayHtml} =~ s/(<body>)/\1<span style="color: #f00;">Database Error<\/span>/i;
  &printdebug('', 'warn', 'Could not query the content for this page:', $@);
}

#moved down here so that errors are contained within the div, also.
$crimp->{DisplayHtml} =~ s/<body>/<body><div id="crimpPageContent">\n/i;
$crimp->{DisplayHtml} =~ s|(</body>)|</div>\n\1|i;

1;

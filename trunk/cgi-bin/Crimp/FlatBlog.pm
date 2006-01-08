$ID = q$Id: FlatBlog.pm,v 1.4 2006-01-08 21:15:35 diddledan Exp $;
&printdebug('Module FlatBlog',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
			
&printdebug('','',"Started With: $crimp->{FlatBlog}");

#Default
#If no query string then show the 1st 5 entries
#If show is present in the query string then 
#	show the 5 appropriate entries starting from value of show
#If $BaseContent then search and display the single entry

use URI::Escape;


# The blog content is stored in VarDirectory to allow another module to add entries

if (-f "$crimp->{VarDirectory}/$crimp->{FlatBlog}"){}
my $requested = "$crimp->{VarDirectory}/$crimp->{FlatBlog}";

sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
@display_content=<FILE>;
close(FILE);

if (@display_content) {
	our $new_content = '';
	#how many entries per page
	my $limit = 5;
	
	####
	foreach $display_content(@display_content) {
		$new_content = join '', $new_content, $display_content;
	}
	#hacky hack to make sure that _all_ entries are available for
	# display without having an empty entry in the blog file.
	$new_content = join '', $new_content, '<h1>';
	
#	#remove xml header if present
#	$crimp->{DisplayHtml} =~ s|<\?xml.*?\?>||i;
#	#remove doctype if present
#	$crimp->{DisplayHtml} =~ s|<!DOCTYPE.*?>||i;
#	#remove headers storing the title of the page
#	$crimp->{DisplayHtml} =~ s|<title>(.*?)</title>||si;
#	#if we insert content then this is important
#	$crimp->{PageTitle} = $1;
#	
#	#strip from <html> down to the opening <body> tag
#	$crimp->{DisplayHtml} =~ s|<html.*?>.*?<body>||si;
#	#remove the closing </body> tag and any cruft after - alas, that's nothing to do with the dogshow
#	$crimp->{DisplayHtml} =~ s|</body>.*||si;
	
	#Decide what to do
	my $BaseContent = $crimp->{HttpRequest};
	$BaseContent =~ s/^$crimp->{UserConfig}\/*//;
	
	my $ShowContent = 0;
	
	my $query = new CGI;
	if ($query->param('show')) {
		#show entries
		my $offset = int($query->param('show'));
		my $offsetpluslimit = $offset + $limit;
		&printdebug('','',"Displaying entries $offset to $offsetpluslimit");
		$crimp->{DisplayHtml} = <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type"/>
  <title>Blog</title>
</head>
<body>
EOF
		&parse_blog($offset,$limit);
		if ($offset > 0) {
			my $newoffset = $offset - $limit || 0;
			$crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, " <a href='$crimp->{UserConfig}?show=$newoffset'>&lt;-- Previous Page</a> ";
		}
		if ($new_content =~ m|</h1>|i) {
			$newoffset = $offset + $limit;
			$crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, " <a href='$crimp->{UserConfig}?show=$newoffset'>Next Page --&gt;</a> ";
		}
		$crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, '</body></html>';
	} elsif($BaseContent ne '') {
		#show a single entry
		$new_content =~ m|<h1>($BaseContent)</h1>(.*?)<h1>|si;
		my $EntryTitle = $1;
		my $EntryContent = $2;
		#I amended the above to use the title specified
		# in the blog file, not the one parsed from the
		# query string. This ensures the title is displayed
		# as the author intended. (Fremen)
		
		$crimp->{DisplayHtml} = <<ENDEOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type"/>
  <title>$EntryTitle</title>
</head>
<body>
<h1><a href="$crimp->{HttpRequest}">$EntryTitle<a></h1>
$EntryContent
</body>
</html>

ENDEOF
	} else {
		#we have nothing to show so we will show the 1st 5 entries
		&printdebug('','','Displaying the latest 5 entries');
		$crimp->{DisplayHtml} = <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type"/>
  <title>Blog</title>
</head>
<body>
EOF
		&parse_blog(0,$limit);
		if ($new_content =~ m|</h1>|i) {
			 $crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, "<a href='$crimp->{UserConfig}?show=5'>Next Page --&gt;</a>";
		}
		$crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, '</body></html>';
	}
	
	&printdebug(
		'',
		'',
		"BaseContent: $BaseContent",
		"HttpQuery: $crimp->{HttpQuery}"
	);
} else {
	$crimp->{DisplayHtml} = "<span style='color: #f00;'>There are no entries in $crimp->{VarDirectory}/$crimp->{FlatBlog}</span>";
}

sub parse_blog {
	my ($offset,$limit) = @_;
	if ($offset > 0) {
		my $offset_counter = 0;
		while (($offset_counter++ < $offset) && ($new_content =~ s|<h1>.*?<h1>|<h1>|si)) {};
	}
	for (my $counter = $offset; $counter < $limit+$offset; $counter++) {
		if ($new_content =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
			my $newurl = join '/', $crimp->{UserConfig}, uri_escape($1);
			$newurl =~ s|/{2,}|/|g;
			$crimp->{DisplayHtml} = join '', $crimp->{DisplayHtml}, "
<h1><a href=\"$newurl\">$1<a></h1>
$2
";
		}
	}
}
1;
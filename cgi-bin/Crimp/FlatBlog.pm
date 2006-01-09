$ID = q$Id: FlatBlog.pm,v 1.5 2006-01-09 05:53:22 deadpan110 Exp $;
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

##################################################################################
# N O T E S
# we need to create a listing that uses the
# <div id="crimpFileList"></div>
# Entries are always outputted vertically
# my $EntryList = '<b>Entries</b><br />&nbsp;&nbsp;&nbsp;';
#
# Entries
# [Back]
#    News 6
#    News 7 <<-- Made Bold with no link to indicate currently viewed entry
#    News 8
#    News 9
#    News 10
# [Next]
#
# 
# crimp.ini Example Entry
#
# [/blog]
# PluginOrder = FlatBlog,ContentDirectory,FileList,BreadCrumbs
# BreadCrumbs = top
# ContentDirectory = ../cgi-bin/Crimp/docs
# FileList = horizontal
# FlatBlog = flatblog.html
#
# Plese note that ContentDirectory is called but not used
#
# As you can see, FlatBlog needs the following:
#

if ($crimp->{DisplayHtml} ne "" ){
&printdebug("","warn", "DisplayHtml has already been filled with content");
}

# Although i have put FileList Detection here... Appending or creating should be
# done from within the FileList Module:
#
# $crimp->{DisplayHtml} =~ s/<div id="crimpFileList">/<div id="crimpFileList">$newhtml/i;
#
# and NOT FROM HERE

if ($crimp->{FileList} ne ""){
&printdebug('','warn',"Module FileList is active... appending (see N O T E S within the source)");
}
else{
&printdebug('','warn',"Module FileList is not active... creating (see N O T E S within the source)");
}

# This could have a significant outcome on navigation by making it easier
# The Navigation should be displayed on every page which would make displaying 5
# entries at a time obsolete... so /blog would show the top entry
#
# Other Notes
# index.pl now has a $crimp->{DefaultHtml} var as it seems like its something we
# keep using again and again and again...
#
# Heh... and once again, i come along and jump all over your hard work...
# I hope you think these are good ideas Fremen M8 :))
##################################################################################



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
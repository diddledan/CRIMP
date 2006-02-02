$ID = q$Id: FlatBlog.pm,v 1.14 2006-02-02 15:49:33 deadpan110 Exp $;
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
my $BlogTitle = $crimp->{FlatBlog};
$BlogTitle =~ s|.html||i;

sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
@display_content=<FILE>;
close(FILE);

if (@display_content) {
	our $new_content = '';
	#how many entries per page
	my $limit = 5;
	my $query = new CGI;
	
	####
	foreach $display_content(@display_content) {
		$new_content = join '', $new_content, $display_content;
	}
	#hacky hack to make sure that _all_ entries are available for
	# display without having an empty entry in the blog file.


	$new_content = join '', $new_content, '<h1>';

	my $offset = 0;
	if ($query->param('show') eq 'all') {
		$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
		$crimp->{DisplayHtml} =~ s|(</title>)|$BlogTitle - Showing ALL Entries\1|i;
		while ($new_content =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
			my $EntryTitle = $1;
			my $EntryText = $2;
			my $EntryUrl = join '/',$crimp->{UserConfig}, uri_escape($EntryTitle);
			$EntryUrl =~ s|/{2,}|/|g;
			$crimp->{DisplayHtml} =~ s|(</body>)|<h1><a href="$EntryUrl">$EntryTitle</a></h1>\n$EntryText\n\1|i;
		}
	} elsif ($query->param('show') eq 'index') {
		$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
		$crimp->{DisplayHtml} =~ s|(</title>)|$BlogTitle - INDEX\1|i;
		$crimp->{DisplayHtml} =~ s|(<body>)|\1<h1>$BlogTitle Index</h1>|i;
		while ($new_content =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
			my ($title, $text) = ($1, $2);
			my $newurl = join '/', $crimp->{UserConfig}, uri_escape($title);
			$newurl =~ s|/{2,}|/|g;
			$crimp->{DisplayHtml} =~ s|(</body>)|&nbsp;&nbsp;&nbsp;<a href='$newurl'>$title</a><br />\1|i;
		}
	} else {
		#Decide what to show
		my $BaseContent = $crimp->{HttpRequest};
		$BaseContent =~ s/^$crimp->{UserConfig}\/*//;
		
		#show the single entry
		$new_content =~ m|<h1>($BaseContent)</h1>(.*?)<h1>|si;
		my $EntryTitle = $1;
		my $EntryContent = $2;
		#if the requested document doesnt exist - get the first one
		
		if (!$EntryTitle && !$EntryContent) {
			$new_content =~ m|<h1>(.*?)</h1>(.*?)<h1>|si;
			$EntryTitle = $1;
			$EntryContent = $2;
		}
		#I amended the above to use the title specified
		# in the blog file, not the one parsed from the
		# query string. This ensures the title is displayed
		# as the author intended. (Fremen)
		
		$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
		$crimp->{DisplayHtml} =~ s|(</title>)|$BlogTitle - $EntryTitle\1|i;
		my $newurl = join '/', $crimp->{UserConfig}, uri_escape($EntryTitle);
		$crimp->{DisplayHtml} =~ s|(</body>)|<h1>$EntryTitle<br/></h1>\n$EntryContent\1|i;

		#show menu entries
		push @{$crimp->{MenuList}}, '<b>Entries:</b>';
		$offset = int($query->param('show'));
		my $newoffset = $offset - $limit || 0;
		if ($offset > 0) {
			push @{$crimp->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Prev]</b></a>";
		}
		&do_blog_list($offset,$limit);
		if ($new_content =~ m|</h1>|i) {
			$newoffset = $offset + $limit;
			push @{$crimp->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Next]</b></a>";
		}
		
	}

$menu = "@{$crimp->{MenuList}}";
	&addMenuContent($menu);
	&printdebug(
		'',
		'',
		"BaseContent: $BaseContent",
		"HttpQuery: $crimp->{HttpQuery}"
	);
} else {
	$crimp->{DisplayHtml} = $crimp->{DefaultHtml};
	$crimp->{DisplayHtml} =~ s|(<body>)|\1<span style='color: #f00;'>There are no entries in $crimp->{VarDirectory}/$crimp->{FlatBlog}</span>|i;
}

sub do_blog_list {
	my ($offset,$limit) = @_;
	if ($offset > 0) {
		my $offset_counter = 0;
		while (($offset_counter++ < $offset) && ($new_content =~ s|<h1>.*?<h1>|<h1>|si)) {};
	}
	for (my $counter = $offset; $counter < $limit+$offset; $counter++) {
		if ($new_content =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
			my ($title, $text) = ($1, $2);
			my $newurl = join '/', $crimp->{UserConfig}, uri_escape($1);
			$newurl =~ s|/{2,}|/|g;
			push @{$crimp->{MenuList}}, "<br />&nbsp;&nbsp;&nbsp;&nbsp;<a href='$newurl?show=$offset'>$title</a>";
			
			#$crimp->{DisplayHtml} =~ s|(</body>)|<h1><a href="$newurl">$title<a></h1>\n$text\1|i;
		}
	}
	
}
1;
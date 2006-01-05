$ID = q$Id: FlatBlog.pm,v 1.1 2006-01-05 21:30:54 deadpan110 Exp $;
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




# The blog content is stored in VarDirectory to allow another module to add entries

if (-f "$crimp->{VarDirectory}/$crimp->{FlatBlog}"){}
my $requested = "$crimp->{VarDirectory}/$crimp->{FlatBlog}";

sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
		
		
			@display_content=<FILE>;
			close(FILE);
			
		if (@display_content) {	
			my $new_content='';
			
			####
			

			
			
			foreach $display_content(@display_content) {
				$new_content= join '', $new_content, $display_content;
			}
			
			
			$crimp->{DisplayHtml} = $new_content;
			
			
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
$BaseContent =~ s/^$crimp->{UserConfig}\///;

my $ShowContent = 0;
if (grep /show/, $crimp->{HttpQuery}) {
#show entries
}
elsif($BaseContent ne ""){
#show a single entry
	$crimp->{DisplayHtml} =~ s|<h1>$BaseContent</h1>(.*?)<h1>||si; #this does not work for the last entry
	$EntryContent = $1;

$crimp->{DisplayHtml} = <<ENDEOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta
 content="text/html; charset=ISO-8859-1"
 http-equiv="content-type"/>
  <title>$BaseContent</title>
</head>
<body>
<h1><a href=\"$crimp->{HttpRequest}\">$BaseContent<a></h1>
$EntryContent
</body>
</html>

ENDEOF

}

else{
#we have nothing to show so we will show the 1st 5 entries
}


&printdebug(
    '',
    '',
    "BaseContent: $BaseContent",
    "HttpQuery: $crimp->{HttpQuery}"
);


		}
else {
$crimp->{DisplayHtml} = "<span style='color: #f00;'>There are no entries in $crimp->{VarDirectory}/$crimp->{FlatBlog}</span>";
}

		
			
1;
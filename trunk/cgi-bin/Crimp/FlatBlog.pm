package Crimp::FlatBlog;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: FlatBlog.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp, MenuList => [] };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module FlatBlog',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
	
	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{FlatBlog}");
	
	#Default
	#If no query string then show the 1st 5 entries
	#If show is present in the query string then 
	#	show the 5 appropriate entries starting from value of show
	#If $BaseContent then search and display the single entry
	
	eval "use URI::Escape";
	if ($@) {
		$self->{crimp}->printdebug('','warn','Could not load URI::Escape:','&nbsp;&nbsp;'.$@);
		return;
	}
	
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
	
	# Although i have put FileList Detection here... Appending or creating should be
	# done from within the FileList Module:
	#
	# $crimp->{DisplayHtml} =~ s/<div id="crimpFileList">/<div id="crimpFileList">$newhtml/i;
	#
	# and NOT FROM HERE
	
	if ($crimp->{FileList} ne '') {
		$self->{crimp}->printdebug('','warn',"Module FileList is active... appending (see N O T E S within the source)");
	} else {
		$self->{crimp}->printdebug('','warn',"Module FileList is not active... creating (see N O T E S within the source)");
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
	
	$BlogFile = join '/', $self->{crimp}->VarDirectory,$self->{crimp}->{FlatBlog};
	if (!-f $BlogFile) {
		$self->{crimp}->printdebug('','warn',
			"File '$self->{crimp}->{FlatBlog}' does not exist within crimp's var-directory.",
			'var-dir currently set to: '.$self->{crimp}->VarDirectory);
		return;
	}

	my $BlogTitle = $self->{crimp}->{FlatBlog};
	$BlogTitle =~ s|.html||i;

	sysopen (FILE,$BlogFile,O_RDONLY) || $self->{crimp}->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $BlogFile", "error: $!");
	@display_content=<FILE>;
	close(FILE);

	if (@display_content) {
		$self->{new_content} = "@display_content";
		#how many entries per page
		my $limit = 5;
		
		#hacky hack to make sure that _all_ entries are available for
		# display without having an empty entry in the blog file.
		$self->{new_content} = join '', $self->{new_content}, '<h1>';
		
		my $offset = 0;
		if ($self->{crimp}->queryParam('show') eq 'all') {
			$self->{crimp}->PageTitle("$BlogTitle - Showing ALL Entries");
			while ($self->{new_content} =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
				my $EntryTitle = $1;
				my $EntryText = $2;
				my $EntryUrl = join '/',$self->{crimp}->userConfig, uri_escape($EntryTitle);
				$EntryUrl =~ s|/{2,}|/|g;
				$self->{crimp}->addPageContent("<h1><a href='$EntryUrl'>$EntryTitle</a></h1>\n$EntryText\n");
			}
		} elsif ($self->{crimp}->queryParam('show') eq 'index') {
			$self->{crimp}->PageTitle("$BlogTitle - INDEX");
			$self->{crimp}->addPageContent("<h1>$BlogTitle Index</h1>");
			while ($self->{new_content} =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si) {
				my ($title, $text) = ($1, $2);
				my $newurl = join '/', $self->{crimp}->userConfig, uri_escape($title);
				$newurl =~ s|/{2,}|/|g;
				$self->{crimp}->addPageContent("&nbsp;&nbsp;&nbsp;<a href='$newurl'>$title</a>");
			}
		} else {
			#Decide what to show
			my $BaseContent = $self->{crimp}->HttpRequest;
			my $uc = $self->{crimp}->userConfig;
			$BaseContent =~ s/^$uc\/*//;
			$BaseContent = uri_unescape($BaseContent);
			
			#show the single entry
			$self->{new_content} =~ m|<h1>($BaseContent)</h1>(.*?)<h1>|si;
			my $EntryTitle = $1;
			my $EntryContent = $2;
			#if the requested document doesnt exist - get the first one
			
			if (!$EntryTitle && !$EntryContent) {
				# redirect the user to the correct URL
				$self->{new_content} =~ m|<h1>(.*?)</h1>|si;
				$EntryTitle = uri_escape($1);
				my $redirectUrl = $self->{crimp}->userConfig;
				$redirectUrl = "$redirectUrl/$EntryTitle?show=0";
				$redirectUrl =~ s|/{2,}|/|g;
				$self->{crimp}->redirect($redirectUrl);
				return;
			}
			#I amended the above to use the title specified
			# in the blog file, not the one parsed from the
			# query string. This ensures the title is displayed
			# as the author intended. (Fremen)
			
			$self->{crimp}->PageTitle("$BlogTitle - $EntryTitle");
			my $newurl = join '/', $self->{crimp}->userConfig, uri_escape($EntryTitle);
			$self->{crimp}->addPageContent("<h1>$EntryTitle<br/></h1>\n$EntryContent");
			
			#show menu entries
			push @{$self->{MenuList}}, '<b>Entries:</b>';
			$offset = int($self->{crimp}->queryParam('show'));
			my $newoffset = $offset - $limit || 0;
			if ($offset > 0) {
				push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Prev]</b></a>";
			}
			$self->do_blog_list($offset,$limit);
			if ($self->{new_content} =~ m|</h1>|i) {
				$newoffset = $offset + $limit;
				push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Next]</b></a>";
			}
		}
		
		$menu = "@{$self->{MenuList}}";
		$self->{crimp}->addMenuContent($menu);
		$self->{crimp}->printdebug('','',
			"BaseContent: $BaseContent",
			"HttpQuery: $crimp->{HttpQuery}"
		);
	} else {
		$self->{crimp}->addPageContent('<span style="color: #f00;">There are no entries in '.$self->{crimp}->VarDirectory.'/'.$self->{crimp}->{FlatBlog}.'</span>');
	}
}

sub do_blog_list {
	my ($self,$offset,$limit) = @_;
	if ($offset > 0) {
		my $offset_counter = 0;
		while (($offset_counter++ < $offset) && ($self->{new_content} =~ s|<h1>.*?<h1>|<h1>|si)) {};
	}
	for (my $counter = 0; $counter < $limit; $counter++) {
		$self->{new_content} =~ s|<h1>(.*?)</h1>(.*?)<h1>|<h1>|si;
		if ($1 && $2) {
			my ($title, $text) = ($1, $2);
			my $newurl = join '/', $self->{crimp}->userConfig, uri_escape($1);
			$newurl =~ s|/{2,}|/|g;
			push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;&nbsp;&nbsp;<a href='$newurl?show=$offset'>$title</a>";
		}
	}
}

1;

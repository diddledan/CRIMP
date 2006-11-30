# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: FlatBlog.pm,v 1.2 2006-11-30 19:57:11 diddledan Exp $
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA

package Crimp::FlatBlog;

use URI::Escape;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: FlatBlog.pm,v 1.2 2006-11-30 19:57:11 diddledan Exp $, crimp => $crimp, MenuList => [] };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	
	$crimp->printdebug('',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
	
	$crimp->printdebug('','',"Started With: $crimp->{FlatBlog}");
	
	#Default
	#If no query string then show the 1st 5 entries
	#If show is present in the query string then 
	#	show the 5 appropriate entries starting from value of show
	#If $BaseContent then search and display the single entry
	
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
		$crimp->printdebug('','warn',"Module FileList is active... appending (see N O T E S within the source)");
	} else {
		$crimp->printdebug('','warn',"Module FileList is not active... creating (see N O T E S within the source)");
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
	
	$BlogFile = join '/', $crimp->VarDirectory,$crimp->{FlatBlog};
	if (!-f $BlogFile) {
		$crimp->printdebug('','warn',
			"File '$crimp->{FlatBlog}' does not exist within crimp's var-directory.",
			'var-dir currently set to: '.$crimp->VarDirectory);
		return;
	}

	my $BlogTitle = $crimp->{FlatBlog};
	$BlogTitle =~ s|.html||i;
	$crimp->PageTitle($BlogTitle);

	sysopen (FILE,$BlogFile,O_RDONLY) || $crimp->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $BlogFile", "error: $!");
	@display_content=<FILE>;
	close(FILE);

	if (!@display_content) {
		$crimp->addPageContent('<span style="color: #f00;">There are no entries in '.$crimp->VarDirectory.'/'.$crimp->{FlatBlog}.'</span>');
		return;
	}

	$self->{new_content} = "@display_content";
	#how many entries per page
	my $limit = 5;
	
	$self->{new_content} =~ s/<!--HEADING_LEVEL=([0-6])-->//gi;
	$heading_level = $1 || '1';
	
	#hacky hack to make sure that _all_ entries are available for
	# display without having an empty entry in the blog file.
	$self->{new_content} .= "<h$heading_level>";
	
	my $offset = 0;
	if ($crimp->queryParam('show') eq 'all') {
		$crimp->PageTitle("Showing ALL Entries");
		while ($self->{new_content} =~ s|<h$heading_level>(.*?)</h$heading_level>(.*?)(<h$heading_level>)|\3|si) {
			my $EntryTitle = $1;
			my $EntryText = $2;
			my $EntryUrl = join '/',$crimp->userConfig, uri_escape($EntryTitle);
			$EntryUrl =~ s|/{2,}|/|g;
			$crimp->addPageContent("<h$heading_level><a href='$EntryUrl'>$EntryTitle</a></h$heading_level>\n$EntryText\n");
		}
	} elsif ($crimp->queryParam('show') eq 'index') {
		$crimp->PageTitle("INDEX");
		$crimp->addPageContent("<h$heading_level>$BlogTitle Index</h$heading_level>");
		while ($self->{new_content} =~ s|<h$heading_level>(.*?)</h$heading_level>(.*?)<h$heading_level>|<h$heading_level>|si) {
			my ($title, $text) = ($1, $2);
			my $newurl = join '/', $crimp->userConfig, uri_escape($title);
			$newurl =~ s|/{2,}|/|g;
			$crimp->addPageContent("&nbsp;&nbsp;&nbsp;<a href='$newurl'>$title</a>");
		}
	} else {
		#Decide what to show
		my $BaseContent = $crimp->HttpRequest;
		my $uc = $crimp->userConfig;
		$BaseContent =~ s/^$uc\/*//;
		$BaseContent = uri_unescape($BaseContent);
		
		#show the single entry
		$self->{new_content} =~ m|<h$heading_level>($BaseContent)</h$heading_level>(.*?)<h$heading_level>|si;
		my $EntryTitle = $1;
		my $EntryContent = $2;
		#if the requested document doesnt exist - get the first one
		
		if (!$EntryTitle && !$EntryContent) {
			# redirect the user to the correct URL
			$self->{new_content} =~ m|<h$heading_level>(.*?)</h$heading_level>|si;
			$EntryTitle = uri_escape($1);
			my $redirectUrl = $crimp->userConfig;
			$redirectUrl = "$redirectUrl/$EntryTitle?show=0";
			$redirectUrl =~ s|/{2,}|/|g;
			$crimp->redirectTo($redirectUrl);
			$crimp->{skipRemainingPlugins} = 1;
		}
		#I amended the above to use the title specified
		# in the blog file, not the one parsed from the
		# query string. This ensures the title is displayed
		# as the author intended. (Fremen)
		
		$crimp->PageTitle($EntryTitle);
		my $newurl = join '/', $crimp->userConfig, uri_escape($EntryTitle);
		$crimp->addPageContent("<h$heading_level>$EntryTitle<br/></h$heading_level>\n$EntryContent");
		
		#show menu entries
		push @{$self->{MenuList}}, '<b>Entries:</b>';
		$offset = int($crimp->queryParam('show'));
		my $newoffset = $offset - $limit || 0;
		if ($offset > 0) {
			push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Prev]</b></a>";
		}
		$self->do_blog_list($offset,$limit);
		if ($self->{new_content} =~ m|</h$heading_level>|i) {
			$newoffset = $offset + $limit;
			push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;<a href='$crimp->{HttpRequest}?show=$newoffset'><b>[Next]</b></a>";
		}
	}
	
	$menu = "@{$self->{MenuList}}";
	$crimp->addMenuContent($menu);
	$crimp->printdebug('','',
		"BaseContent: $BaseContent",
		"HttpQuery: $crimp->{HttpQuery}"
	);
}

sub do_blog_list {
	my ($self,$offset,$limit) = @_;
	my $crimp = $self->{crimp};
	if ($offset > 0) {
		my $offset_counter = 0;
		while (($offset_counter++ < $offset) && ($self->{new_content} =~ s|<h$heading_level>.*?<h$heading_level>|<h$heading_level>|si)) {};
	}
	for (my $counter = 0; $counter < $limit; $counter++) {
		$self->{new_content} =~ s|<h$heading_level>(.*?)</h$heading_level>(.*?)<h$heading_level>|<h$heading_level>|si;
		if ($1 && $2) {
			my ($title, $text) = ($1, $2);
			my $newurl = join '/', $crimp->userConfig, uri_escape($1);
			$newurl =~ s|/{2,}|/|g;
			push @{$self->{MenuList}}, "<br />&nbsp;&nbsp;&nbsp;&nbsp;<a href='$newurl?show=$offset'>$title</a>";
		}
	}
}

1;

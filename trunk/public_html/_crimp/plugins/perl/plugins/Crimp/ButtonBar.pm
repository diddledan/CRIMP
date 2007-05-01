# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2007 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: ButtonBar.pm,v 1.1 2007-05-01 20:17:31 diddledan Exp $
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This file is Licensed under the LGPL.

package Crimp::ButtonBar;

sub new {
	my $class = shift;
	my $crimp = shift;
	my $self = { id => q$Id: ButtonBar.pm,v 1.1 2007-05-01 20:17:31 diddledan Exp $, crimp => $crimp };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};

	$crimp->printdebug('',
			'',
			'Authors: The CRIMP Team',
			'Version: '.$self->{id},
			'http://crimp.sourceforge.net/'
			);

	$crimp->printdebug('','',"Started With: $crimp->{ButtonBar}");

	my $help ="#";
	my $view = "#";
	my $edit = "#";
	my $querystring = $crimp->{_HttpQuery};
	$querystring ||= '?';
	$querystring =~ s|([\?&;])debug=.*?[&;]?|$1|i;
	$querystring = join('', '?', $querystring) if not $querystring =~ m|^\?|;
	$querystring = join('', $querystring, '&') if $querystring =~ m|^\?.+|;
	my $debug = join '', $crimp->HttpRequest, $querystring, 'debug=on#crimpDebug';

	$ButtonBar = <<ENDEOF;
<a href="<!--help-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/help.gif" alt="Help"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--view-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/view.gif" alt="View"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--edit-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/edit.gif" alt="Edit"
 style="border: 0px solid ; width: 26px; height: 25px;"/></a><a href="<!--debug-->"><img
 src="/crimp_assets/ButtonBar/$crimp->{ButtonBar}/pics/debug.gif" alt="Debug"
 style="border: 0px solid ; width: 26px; height: 25px;" onClick="showDebug(); return false;"/></a>
ENDEOF

	if ($crimp->{ButtonBar} eq 'Default') {
		$crimp->printdebug('','pass','Using Default ButtonBar');
	} else {
		# Use a Custom ButtonBar
		my $requested = $crimp->HtmlDirectory."/crimp_assets/ButtonBar/$crimp->{ButtonBar}/style.htm";
		if ( -f $requested ) {
			sysopen (FILE,$requested,O_RDONLY) || $crimp->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $requested", "error: $!");
			$crimp->printdebug('','pass',"Using $crimp->{ButtonBar} ButtonBar");
			my @temp=<FILE>;
			close(FILE);
			$ButtonBar = "@temp";
		} else {
			$crimp->printdebug('','warn',"$crimp->{ButtonBar} ButtonBar does not exist",'Using Default ButtonBar');
		}
	}

	# Put it all together

	$ButtonBar =~ s/<!--help-->/$help/gi;
	$ButtonBar =~ s/<!--view-->/$view/gi;
	$ButtonBar =~ s/<!--edit-->/$edit/gi;
	$ButtonBar =~ s/<!--debug-->/$debug/gi;
	$crimp->addReplacement('<!--BUTTONBAR-->',$ButtonBar,'i');
}

1;

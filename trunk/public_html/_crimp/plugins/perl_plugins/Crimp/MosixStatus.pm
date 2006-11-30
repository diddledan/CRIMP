# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: MosixStatus.pm,v 1.2 2006-11-30 19:57:11 diddledan Exp $
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

package Crimp::MosixStatus;
use strict;
use Fcntl;

sub new {
  my $class = shift;my $crimp = shift;
  my $self = bless {crimp=>$crimp, id=>q$Id: MosixStatus.pm,v 1.2 2006-11-30 19:57:11 diddledan Exp $}, $class;
  return $self;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	
	$crimp->printdebug('','',
					   'Authors: The CRIMP Team',
					   "Version: $self->{id}",
					   'http://crimp.sourceforge.net/'
					  );
	
	my $mosixpath;
	if (-e "/proc/mosix") { $mosixpath = "/proc/mosix" }
	elsif (-e "/proc/hpc") { $mosixpath = "/proc/hpc" }
	else { $crimp->printdebug('','warn','Could not find (open)mosix /proc files. Check that this machine is configured as part of the cluster.') }
	
	my @nodes = split /,/, $crimp->{MosixStatus};
	my @rows;
	push @rows, "<table style='border-collapse: collapse;'><tr><th>NodeName</th><th>ID</th><th>Is Live?</th><th>#CPUs</th><th>Speed</th><th>Free Mem</th><th>Load</th><th>Utilizability</th></tr>\n";
	for (@nodes) {
		my ($name, $id) = split /:/, $_;
		
		my ($load, $cpus, $speed, $free, $util) = ('na', 'na', 'na', 'na', 'na');
		my $isLive = 'no';
		my $style = ' style="background: #f55; color: #000;"';
		
		if (-d "$mosixpath/nodes/$id") {
			sysopen LOAD, "$mosixpath/nodes/$id/load", O_RDONLY;
			$load = <LOAD>;
			close LOAD;
			if ($load =~ m/-101/) { $load = 'na' }
			else { $isLive = 'yes' }
			
			if ($isLive eq 'yes') {
				$style = ' style="background: #5f5; color: #000;"';
				sysopen CPUS, "$mosixpath/nodes/$id/cpus", O_RDONLY;
				$cpus = <CPUS>;
				close CPUS;
				sysopen SPEED, "$mosixpath/nodes/$id/speed", O_RDONLY;
				$speed = <SPEED>;
				close SPEED;
				sysopen FREE, "$mosixpath/nodes/$id/tmem", O_RDONLY;
				$free = <FREE>;
				close FREE;
				sysopen UTIL, "$mosixpath/nodes/$id/util", O_RDONLY;
				$util = <UTIL>;
				close UTIL;
			}
		}
		
		push @rows, "<tr$style><th>$name</th><td>$id</td><td>$isLive</td><td>$cpus</td><td>$speed</td><td>$free</td><td>$load</td><td>$util\%</td></tr>\n";
	}
	push @rows, "</table>\n";
	
	if ($crimp->queryParam('CrimpMosixStatus') eq 'refresh') {
		$crimp->{DisplayHtml} = "@rows";
		$crimp->ContentType('text/xml');
		$crimp->{skipRemainingPlugins} = 1;
		return;
	}
	
	my $req = $crimp->{_HttpRequest};
	my $javascript = "
<script type='text/javascript'><!--
function mosixStatusDoIt() {
	var CrimpMosixStatusAJAX = new Ajax.Updater(
		'CrimpMosixStatus',
		'$req',
		{
			method: 'get',
			parameters: 'CrimpMosixStatus=refresh'
		});
	
	setTimeout('mosixStatusDoIt()', 10000);
}
setTimeout('mosixStatusDoIt()', 10000);
//--></script>";
	
	$crimp->addPageContent("<div id='CrimpMosixStatus'>@rows</div>$javascript");
}

1;
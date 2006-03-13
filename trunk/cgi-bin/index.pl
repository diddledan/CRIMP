#!perl
# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:        The CRIMP Team
# Project Leads:  Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                 Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:       http://crimp.sourceforge.net/

##################################################################################
# This library is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU Lesser General Public                     #
# License as published by the Free Software Foundation; either                   #
# version 2.1 of the License, or (at your option) any later version.             #
#                                                                                #
# This library is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU              #
# Lesser General Public License for more details.                                #
#                                                                                #
# You should have received a copy of the GNU Lesser General Public               #
# License along with this library; if not, write to the Free Software            #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA #
##################################################################################

use strict;

use CGI::Carp qw(fatalsToBrowser);
use Crimp;

our $crimp = Crimp->new;
$crimp->execute;
$crimp->sendDocument;

## Deadpan110's thoughts... ##
# default web settings are to use local files
# with 404 error document in place
#
# config file contains file and or directory actions
# whether file exists or not
# will try and use apache config style for settings...
#
# <[file] or [directory] = "[local server path to file/directory]"
# [OPTIONS GO HERE]
# ie: *.exe's are located on a number of remote servers
#   try a random server to redirect to 
# </[file] or [directory]>
# also enable file to contain # comments
#
#Produce apache style logs

####################################################################
# this is a server beep (used for testing)
# Turns local and remote IP adressess into a tune
# gentoo users: emerge beep
# to activate, uncomment below
#
#$BEEP = $crimp->beep();
#
####################################################################

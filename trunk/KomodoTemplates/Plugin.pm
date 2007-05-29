# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2007 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: Plugin.pm,v 1.2 2007-05-29 23:17:31 diddledan Exp $
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This file is Licensed under the LGPL.

package Crimp::Plugin::[[%(ask0:Plugin Name)]];
use strict;

sub new {
    my ($class, $crimp) = @_;
    my $self = { id => q$Id: Plugin.pm,v 1.2 2007-05-29 23:17:31 diddledan Exp $, crimp => $crimp, };
    bless $self, $class;
}

sub execute {
    my $self = shift;
    my $crimp = $self->{crimp};

    $crimp->printdebug('Module \'[[%(ask0:Plugin Name)]]\'',
        '',
        'Authors: The CRIMP Team',
        "Version: $self->{id}",
        'http://crimp.sourceforge.net/'
    );
}

1;
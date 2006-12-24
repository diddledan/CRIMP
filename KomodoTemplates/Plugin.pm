package Crimp::Plugin::[[%(ask0:Plugin Name)]];
use strict;

sub new {
    my ($class, $crimp) = @_;
    my $self = { id => q$Id: Plugin.pm,v 1.1 2006-12-24 14:56:31 diddledan Exp $, crimp => $crimp, };
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
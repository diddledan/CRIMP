#!/usr/bin/perl -w
##### IMPORTANT #####
# THIS IS NOT A CGI APPLICATION, AND CANNOT BE USED DIRECTLY: SEE USAGE
##### IMPORTANT #####
# USAGE:
# drop this script inside CRIMP_HOME/plugins/perl_plugins, create a subdir
# called CRIMP_HOME/plugins/perl_plugins/Crimp <-- upper case C important!!,
# and finally drop any perl-based crimp plugins inside this new Crimp subdir
#
# perl-php-wrapper.pl - this script acts as a bridge between the older
#   perl-based CRIMP plugins and the new PHP engine.
#
# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2007 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: perl-php-wrapper.pl,v 1.13 2007-04-29 23:22:32 diddledan Exp $
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This file is Licensed under the LGPL.

use strict;

## we need to keep the Crimp package, as plugins expect to call functions using
## the $crimp package descriptor which is passed upon plugin initialisation.
my $crimp = new Crimp;
$crimp->execute();





##### Crimp.pm substitute follows: #####

package Crimp;

#constructor
sub new {
  my $class = shift;
  my $self = {
              _DefaultHtml => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type"/>
<title></title>
</head>
<body>
</body>
</html>',
              _DefaultLang      => 'en',
              _HttpRequest      => $ENV{'HTTP_REQUEST'},
              _HttpQuery        => $ENV{'QUERY_STRING'} || '',
              _PostQuery        => undef,
              _GetData          => undef,
              _PostData         => undef,
              _receivedCookies  => undef,
              _rawCookies       => $ENV{'COOKIES'},
              _VarDirectory     => $ENV{'VAR_DIR'},
              _ErrorDirectory   => $ENV{'ERROR_DIR'},
              _HtmlDirectory    => $ENV{'DOCUMENT_ROOT'},
              _ContentType      => $ENV{'CONTENT_TYPE'},
              _RemoteHost       => $ENV{'REMOTE_HOST'},
              _ServerName       => $ENV{'SERVER_NAME'},
              _ServerSoftware   => $ENV{'SERVER_SOFTWARE'},
              _ServerProtocol   => $ENV{'PROTOCOL'},
              _UserAgent        => $ENV{'USER_AGENT'},
              _UserConfig       => $ENV{'USERCONFIG'},
             };
  bless $self, $class;

  eval {use Fcntl;use URI::Escape;};
  if ($@) {
    $self->printdebug('Initialisation Failure','fail','Could not load all required modules:',"&nbsp;&nbsp;$@");
    return;
  }

    $self->parsePOSTed();
    $self->parseGETed();
    $self->parseCookies();

  return $self;
}

sub execute {
    my $self = shift;

    ##################
    ## Main Routine ##
    ##################

    $self->executePlugin();
}

###### HELPER ROUTINES ######
sub redirectTo {
    my ($self, $url) = @_;
    return if not defined $url;
    print <<EOF;
header('Location: $url');
exit;
EOF
    exit;
}

sub stripHtmlHeaderFooter {
    my $self = shift;
    my $html = shift;

    #parse headers storing the title of the page
    $html =~ m|<title>(.*?)</title>|si;
    my $title = $1;
    #remove everything down to <body>
    $html =~ s|.*?<body.*?>||si;
    #remove everything after </body>
    $html =~ s|</body>.*||si;
    return ($title, $html);
}

sub PageTitle {
    my ($self, $pt, $override) = @_;
    if (defined $pt) {
        if (defined $override) {
            print "\$crimp->setTitle('$pt', true);\n";
        } else {
            print "\$crimp->setTitle('$pt');\n";
        }
    }
}

sub errorPage {
    my $self = shift;
    my $package = shift;
    my $errCode = shift;
    print "\$crimp->errorPage('$package', '$errCode');\n";
    exit;
}

sub HttpRequest {
  my $self = shift;
  return $self->{_HttpRequest} || '/';
}

sub ContentType {
    my ($self, $ct) = @_;
    if (defined $ct) {
        $self->{_ContentType} = $ct;
        print "\$crimp->contentType('$ct');\n";
    }
    return $self->{_ContentType};
}

sub ExitCode {
    my ($self, $ec) = @_;
    if (defined $ec) {
        $self->{_ExitCode} = $ec;
        print "\$crimp->exitCode('$ec');\n";
    }
    return $self->{_ExitCode};
}

sub getCookie {
    my ($self, $cookiename) = @_;
    return $self->{_receivedCookies}->{$cookiename} || '';
}

sub userConfig {
  my $self = shift;
  return $self->{_UserConfig} || '/';
}
sub VarDirectory {
    my $self = shift;
    return $self->{_VarDirectory};
}
sub HtmlDirectory {
    my $self = shift;
    return $self->{_HtmlDirectory};
}
sub queryParam {
    #return the query parameter requested, favouring POST
    my ($self, $parameter) = @_;

    return $self->{_PostData}->{$parameter} if $self->{_PostData}->{$parameter};
    return $self->{_GetData}->{$parameter} if $self->{_GetData}->{$parameter};
    return undef;
}

sub Config {
	#return the configuration for the specified key from the crimp.ini file
	my ($self, $plugin, $key) = @_;
	return $ENV{'PARAMETER'} if $key eq 'value' && $plugin eq $ENV{'PLUGIN'};
	return undef;
}

sub addHeaderContent {
    my $self = shift;
    my $new_header = $self->AddSlashes(shift);
    print "\$crimp->addHeader(stripslashes('$new_header'));\n";
}

sub addPageContent {
    my $self = shift;

    my $PageContent = $self->AddSlashes(shift);
    my $PageLocation = shift; #(top / bottom / null = bottom)
    $PageLocation ||= 'bottom';

    print "\$crimp->addContent(stripslashes('$PageContent'), '$PageLocation');\n";
}

sub addMenuContent {
    my $self = shift;

    my $menuContent = $self->AddSlashes(shift);
    print "\$crimp->addMenu(stripslashes('$menuContent'));\n";
}

sub addReplacement {
    my $self = shift;
    my ($regex, $replace, $opts) = @_;
    return if (!defined $regex || !defined $replace);
    $opts = '' if not defined $opts;
    $replace = $self->AddSlashes($replace);
    $regex = $self->AddSlashes($regex);
    $opts = $self->AddSlashes($opts);

    print "\$crimp->_output = preg_replace(stripslashes('/$regex/$opts'), stripslashes('$replace'), \$crimp->_output);\n";
}

###### END HELPER ROUTINES ######

sub parseCookies {
    my $self = shift;
    return if !$self->{_rawcookies};
    my @TempArray = split /&/, $self->{_rawcookies};
    my %cookies;
    foreach (@TempArray) {
	my ($name, $value) = split /=/;
	$name =~ s/([^\\])\+/$1 /g;
	$name = uri_unescape($name);
	$value =~ s/([^\\])\+/$1 /g;
	$value = uri_unescape($value);
        $cookies{$name} = $value;
    }

    %{$self->{rceivedCookies}} = %cookies;
}

sub parseGETed {
    my $self = shift;
    return if !$self->{_HttpQuery};
    my @TempArray = split /&/, $self->{_HttpQuery};
    my %GetQuery;
    foreach (@TempArray) {
        my ($name, $value) = split /=/;
        $name =~ s/([^\\])\+/$1 /g;
        $name = uri_unescape($name);
        $value =~ s/([^\\])\+/$1 /g;
        $value = uri_unescape($value);
        $GetQuery{$name} = $value;
    }

    %{$self->{_GetData}} = %GetQuery;
}

sub parsePOSTed {
    my $self = shift;

    read(STDIN, my $PostQueryString, $ENV{'CONTENT_LENGTH'});
    my @TempArray = split /&/, $PostQueryString;
    my %PostQuery;
    foreach my $item (@TempArray) {
        my ($name, $value) = split /=/, $item;
        $name =~ s/([^\\])\+/$1 /g;
        $name = uri_unescape($name);
        $value =~ s/([^\\])\+/$1 /g;
        $value = uri_unescape($value);
        $PostQuery{$name} = $value;
    }

    %{$self->{_PostData}} = %PostQuery;
    $self->{PostQuery} = $PostQueryString;
}

####################################################################
sub executePlugin {
    my $self = shift;

    my $plugin = $ENV{'PLUGIN'};
    $self->printdebug('Executing Plugin','',"<b>($plugin)</b>");
    $self->{$plugin} = $ENV{'PARAMETER'};

    my $handle;

    eval "use Crimp::$plugin; \$handle = new Crimp::$plugin(\$self);";
    $self->printdebug('', 'warn', 'Plugin failed to execute:', "&nbsp;&nbsp;$@") if ($@);
    eval { $handle->execute() };
    $self->printdebug('', 'warn', 'Plugin failed to execute:', "&nbsp;&nbsp;$@") if ($@);
}

####################################################################
sub printdebug {
    my $self = shift;
    my $package = shift;
    my $status = shift;
    my $message = '';

    while (my $extra = shift) {
	if ($message eq '') { $message = $extra; }
	else { $message = "$message<br />$extra"; }
    }

    $message = "<b>$package</b><br />$message" if $package ne '';

    $message = $self->AddSlashes($message);

    if ($status eq 'pass') { print "\$dbg->addDebug(stripslashes('$message'), PASS);\n" }
    elsif ($status eq 'warn') { print "\$dbg->addDebug(stripslashes('$message'), WARN);\n" }
    elsif ($status eq 'fail') { print "\$dbg->addDebug(stripslashes('$message'), FAIL);\n\$crimp->errorPage('$package', '500');\n"; exit }
    else { print "\$dbg->addDebug('$message');\n" }
}

####################################################################
sub PageRead {
  my $self = shift;
  my $filename = shift;

  if ( -f $filename ) {
    sysopen (FILE,$filename,O_RDONLY) || $self->printdebug('', 'fail', 'Couldnt open file for reading', "file: $filename", "error: $!");
    my @FileRead=<FILE>;
    close(FILE);
    $self->printdebug('(PageRead - perl-php-wrapper.pl BuiltIn Module)','pass',"Returning content from $filename");
    return "@FileRead";
  }

  $filename = join '/', $self->{_ErrorDirectory}, '404.html';
  $self->printdebug('(PageRead - perl-php-wrapper.pl BuiltIn Module)', 'warn', "File <$filename> does not exist",
                    "Using $self->{_ErrorDirectory}/404.html instead");
  $self->ExitCode('404');

  my $newhtml = <<EOF;
<h1>404 - Page Not Found</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
EOF

  my $FileRead = $self->{_DefaultHtml};
  $FileRead =~ s/(<body>)/$1$newhtml/i;
  $FileRead =~ s/(<title>)/${1}404 - Page Not Found/i;
  return $FileRead;
}

# Garbage Collector for lock files used by FileWrite
sub lockFileGC {
    my $self = shift;
    my $lockfile = shift;

    return if not -f $lockfile;

    my $timeout = 60; #seconds

    my $FileDate = (stat($lockfile))[9];
    if ($FileDate > 0) {
	my $now = time();
	my $diff = $now - $FileDate;
	if ($diff > $timeout) { $self->printdebug('(lockFileGC - perl-php-wrapper.pl built-in)','pass',"Lock File $lockfile expunged ($now - $FileDate = $diff ( > $timeout ))"); unlink($lockfile); }
    }
}

####################################################################
sub FileRead {
  my $self = shift;
    my $filename=shift;
    my $entry=shift;
    my $string=shift;
    my $fileopen = join '/',$self->VarDirectory(),$filename;

    if ( -f $fileopen ) {
	sysopen (FILE,$fileopen,O_RDONLY) || $self->printdebug('(FileRead - perl-php-wrapper.pl built-in)', 'fail', 'Couldnt open file for reading', "file: $fileopen", "error: $!");
	my @FileRead=<FILE>;
	close(FILE);

	if (@FileRead) {
	    foreach (@FileRead) {
		chop($_) if $_ =~ /\n$/;
		my ($FileEntry,$FileString) = split(/\|\|/,$_);
		return($FileString) if ($FileEntry eq $entry);
	    }
	}
    }
    return ($self->FileWrite($filename,$entry,$string));
}

####################################################################
sub FileWrite {
    my $self = shift;
    my $filename=shift;
    my $entry=shift;
    my $string=shift;
    my $try = shift;
    my $filelock = join '/',$self->VarDirectory(),'lock',$filename;
    $self->lockFileGC($filelock);
    my $fileopen = join '/',$self->VarDirectory(),$filename;

    sysopen(LOCKED,$filelock, O_WRONLY | O_EXCL | O_CREAT) or return $self->RetryWait($filename,$entry,$string,$try||0);
    $self->printdebug('','',"FileWrite: [$filename] $entry");#Keep on one line
    if ( -f $fileopen ) {
        sysopen (FILE,$fileopen,O_RDONLY) || $self->printdebug('', 'fail', 'Couldn\'t open file for reading', "file: $fileopen", "error: $!");
        my @FileRead=<FILE>;
        close(FILE);

        if (@FileRead) {
            my $flag=0;
            foreach my $line (@FileRead) {
            chop($line) if $line =~ /\n$/;
            my ($FileEntry,$FileString) = split(/\|\|/,$line);

            if ($FileEntry eq $entry) {
                print LOCKED "$entry||$string\n";
                $flag=1;
            } else {
                print LOCKED "$FileEntry||$FileString\n";
            }
        }

        print LOCKED "$entry||$string\n" if($flag == 0);
        }
    } else {
        print LOCKED "$entry||$string\n";
    }

    close(LOCKED);

    if (!rename($filelock, $fileopen)) {
        $self->printdebug('(FileWrite - perl-php-wrapper.pl built-in)','fail','Can\'t rename: '.$!);
        return undef;
    }

    return($string);
}

####################################################################
sub RetryWait {
    my $self = shift;
    my $filename=shift;
    my $entry=shift;
    my $string=shift;
    my $tries = shift;

    if ($tries > 5) {
        $self->ExitCode('500');
        $self->printdebug('(RetryWait - perl-php-wrapper.pl built-in)','warn',"File lock in place on $filename. Write aborted.");
        return 0;
    }

    if ($tries != 0) { sleep 1; }
    $tries++;
    return $self->FileWrite($filename,$entry,$string,$tries);
}

sub AddSlashes {
    my $self = shift;
    my $text = shift;
    $text =~ s|'|\\'|g;
    $text =~ s|"|\\"|g;
    return $text;
}

# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2007 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
# Revision info: $Id: PageVote.pm,v 1.6 2007-04-29 23:22:32 diddledan Exp $
#
# This file is Licensed under the LGPL.

package Crimp::PageVote;

sub new {
	my ($class, $crimp) = @_;
        my $self = {
        	id => q$Id: PageVote.pm,v 1.6 2007-04-29 23:22:32 diddledan Exp $,
                crimp => $crimp,
                YesVoteRating => 0,
		NoVoteRating => 0,
		YesPageRating => 0,
		NoPageRating => 0,
		PageRating => 0,
		LocalPageRating => 0,
		YesVotePage => 0,
		YesVoteSite => 0,
		NoVotePage => 0,
		NoVoteSite => 0,
		StarRating => 0,
		TotalRating => 0,
                message => 0,
        };
        bless $self, $class;
}

sub execute {
	my $self = shift;

        $self->{crimp}->printdebug('',
			'',
			'Authors: The CRIMP Team',
			"Version: $self->{id}",
			'http://crimp.sourceforge.net/'
			);

	$self->{crimp}->printdebug('','',"Started With: $self->{crimp}->{PageVote}");

	####################################################################

	if ($self->{crimp}->queryParam('PageVote')) {
		if (($self->{crimp}->queryParam('PageVote') eq 'yes')
			||($self->{crimp}->queryParam('PageVote') eq 'good')
			||($self->{crimp}->queryParam('PageVote') eq 'ok')) {
				$self->{message} = 1;
				$self->PageVote('Yes');
		} elsif (($self->{crimp}->queryParam('PageVote') eq 'no')
			||($self->{crimp}->queryParam('PageVote') eq 'poor')
			||($self->{crimp}->queryParam('PageVote') eq 'bad')) {
				$self->{message} = 2;
				$self->PageVote('No');
		} else {
			$self->{message} = 5;
		}
	}

	#Get Current results
	$self->GetVote();

	####################################################################

	$self->{crimp}->printdebug('','',"Results (for use in comment tags within a template):",
						"   YesRate (%)          : $self->{YesVoteRating}",
						"   NoRate (%)           : $self->{NoVoteRating}",
						"   TotalRate (%)        : $self->{PageRating}",
						"   YesPageRate (%)      : $self->{YesPageRating}",
						"   NoPageRate (%)       : $self->{NoPageRating}",
						"   TotalPageRate (%)    : $self->{LocalPageRating}",
						"   YesVotesTotal        : $self->{YesVotePage}",
						"   YesSiteTotal         : $self->{YesVoteSite}",
						"   NoVotesTotal         : $self->{NoVotePage}",
						"   NoSiteTotal          : $self->{NoVoteSite}",
						"   StarRating (1 to 10) : $self->{StarRating}",
						"   TotalRating (1 to 10): $self->{TotalRating}",
						);

	my @PageVote = <<ENDEOF;
<a name="PageVote" id="PageVote"></a>
<hr/>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="33%" align="left" valign="top"><font size='-1'><em><strong>Did you find this page useful?</strong></em><br />
      <form id="crimpPageVote" name="crimpPageVote" method="get" action="">
        <strong>Vote:</strong><input name="PageVote" type="submit" id="PageVote" value="yes" /><input name="PageVote" type="submit" value="no" />
      </form>
    </td>
    <td width="34%" align="center" valign="top"><p align="center"><!--SubmitMessage--></p></td>
    <td width="33%" align="right" valign="top"><font size='-1'>Current Rating : <!--TotalRate-->%<br/><br/></font></td>
  </tr>
</table>

ENDEOF

	####################################################################

	if ($self->{crimp}->{PageVote} ne 'Default') {
		# Use a Custom Template
		my $requested = join '', $self->{crimp}->HtmlDirectory, '/crimp_assets/PageVote/', $self->{crimp}->{PageVote}, '/style.htm';
		if ( -f $requested ) {
			sysopen (FILE,$requested,O_RDONLY) || $self->{crimp}->printdebug('', 'fail', 'Couldnt open file for reading', "file: $requested", "error: $!");
			@PageVote=<FILE>;
			close(FILE);
		} else {
			$self->{crimp}->printdebug('','warn',"Template '$requested' does not exist, using 'Default'");
			$self->{crimp}->{PageVote} = 'Default';
		}
	}

	$PageVote = join '', @PageVote;

	####################################################################

	#####
	# All these tags need clearing before sending them into the page or menu

	if($self->{message} == 1) {
		if ($PageVote =~ m/<!--YesVote:/){
			$PageVote =~ s!<\!--YesVote:(.*?)-->!!is;
			$self->{message} = $1;
		} else {
			$self->{message} = "Thankyou for voting yes!";
	        }
	} elsif($self->{message} == 2) {
		if ($PageVote =~ m/<!--NoVote:/) {
			$PageVote =~ s!<\!--NoVote:(.*?)-->!!is;
			$self->{message} = $1;
		} else {
			$self->{message} = "Maybe you should join our mailing list and tell us how we can improve this page.";
		}
	} elsif($self->{message} == 3) {
		if ($PageVote =~ m/<!--VoidVote:/) {
			$PageVote =~ s!<\!--VoidVote:(.*?)-->!!is;
			$self->{message} = $1;
		} else {
			$self->{message}  ="You have already voted on this page today!";
		}
	} elsif($self->{message} == 4) {
		if ($PageVote =~ m/<!--ReVote:/) {
			$PageVote =~ s!<\!--ReVote:(.*?)-->!!is;
			$self->{message} = $1;
		} else {
			$self->{message} = "Thankyou for coming back to vote on this page!";
		}
	} elsif($self->{message} == 5) {
		if ($PageVote =~ m/<!--InvalidVote:/) {
			$PageVote =~ s!<\!--InvalidVote:(.*?)-->!!is;
			$self->{message} = $1;
		} else {
			$self->{message} = "Oooh... look at you!!";
		}
	} else {
       		$self->{message} = "&nbsp;";
	}

	$PageVote =~ s/<!--YesRate-->/$self->{YesVoteRating}/gi;
	$PageVote =~ s/<!--NoRate-->/$self->{NoVoteRating}/gi;
	$PageVote =~ s/<!--TotalRate-->/$self->{PageRating}/gi;

	$PageVote =~ s/<!--YesPageRate-->/$self->{YesPageRating}/gi;
	$PageVote =~ s/<!--NoPageRate-->/$self->{NoPageRating}/gi;
	$PageVote =~ s/<!--TotalPageRate-->/$self->{LocalPageRating}/gi;

	$PageVote =~ s/<!--YesVotesTotal-->/$self->{YesVotePage}/gi;
	$PageVote =~ s/<!--NoVotesTotal-->/$self->{NoVotePage}/gi;

	$PageVote =~ s/<!--YesSiteTotal-->/$self->{YesVoteSite}/gi;
	$PageVote =~ s/<!--NoSiteTotal-->/$self->{NoVoteSite}/gi;

	$PageVote =~ s/<!--StarRating-->/$self->{StarRating}/gi;
	$PageVote =~ s/<!--TotalRating-->/$self->{TotalRating}/gi;
	$PageVote =~ s/<!--SubmitMessage-->/$self->{message}/gi;

	####################################################################
	## Decide if we are adding to the page or the menu ##
	####################################################

	if($PageVote =~ m/<!--MenuContent/) {
		$self->{crimp}->printdebug('','pass',"Using '$self->{crimp}->{PageVote}' PageVote Template in Menu");
		$self->{crimp}->addMenuContent($PageVote);
	} else {
		$self->{crimp}->printdebug('','pass',"Using '$self->{crimp}->{PageVote}' PageVote Template in Content");
		$PageVote = join("\n","<div id='crimpPageVote'>",$PageVote,'</div>');
		$self->{crimp}->addPageContent($PageVote);
	}
} #end sub (execute)

sub PageVote {
	my $self = shift;

	$self->{crimp}->printdebug('','','Status: Checking for User');
	my $MyVote = shift;

	my $UserID = join '',$self->{crimp}->{RemoteHost},$self->{crimp}->HttpRequest;
	my $CurrTime = time;
	my $UserTime = $self->{crimp}->FileRead('PageVoteUserTime',$UserID,$CurrTime);

	#24 hours = 86400 seconds
	my $TimeOut = 86400;

	if ($UserTime == $CurrTime) {
		$self->{crimp}->printdebug('','',"Status: Adding Vote");
		$self->CountVote($MyVote);
	} elsif ($CurrTime < ($UserTime + $TimeOut)) {
		$self->{message} = 3;
		$self->{crimp}->printdebug('','',"Status: Refusing Vote");
	} elsif ($CurrTime > ($UserTime + $TimeOut - 1)) {
		$self->{message} = 4;
		$self->{crimp}->FileWrite('PageVoteUserTime',$UserID,$CurrTime);
		$self->{crimp}->printdebug('','',"Status: Adding Another Vote");
		$self->CountVote($MyVote);
	}
} #end sub (PageVote)

sub CountVote {
	my $self = shift;

	my $MyVote = shift;

	my $VoteCountPage = $self->{crimp}->FileRead(join('','PageVote',$MyVote),$self->{crimp}->HttpRequest,0);
	my $VoteCountSite = $self->{crimp}->FileRead(join('','PageVote',$MyVote),'TotalVote',0);

	$VoteCountPage++;
	$VoteCountSite++;

	my $VotePage = $self->{crimp}->FileWrite(join('','PageVote',$MyVote),$self->{crimp}->HttpRequest,$VoteCountPage);
	my $VoteSite = $self->{crimp}->FileWrite(join('','PageVote',$MyVote),'TotalVote',$VoteCountSite);
} #end sub (CountVote)

sub GetVote {
	my $self = shift;

	$self->{crimp}->printdebug('','',"Status: Getting Results");
	$self->{YesVotePage} = $self->{crimp}->FileRead("PageVoteYes",$self->{crimp}->HttpRequest,0);
	$self->{YesVoteSite} = $self->{crimp}->FileRead("PageVoteYes",'TotalVote',0);

	$self->{NoVotePage} = $self->{crimp}->FileRead("PageVoteNo",$self->{crimp}->HttpRequest,0);
	$self->{NoVoteSite} = $self->{crimp}->FileRead("PageVoteNo",'TotalVote',0);

	$self->{YesVoteRating} = 0;
	$self->{NoVoteRating} = 0;
	$self->{PageRating} = 0;

	my $TotalVoteSite = $self->{YesVoteSite} + $self->{NoVoteSite};
	my $TotalVotePage = $self->{YesVotePage} + $self->{NoVotePage};

	#BEWARE 'DIVIDE by ZERO' ERRORS if altered
	if ($TotalVotePage != 0) {
		if ($self->{YesVotePage} != 0) {
			$self->{YesPageRating} = int(($self->{YesVotePage} / $TotalVotePage) * 100);
		}
		if ($self->{NoVotePage} != 0) {
			$self->{NoPageRating} = int(($self->{NoVotePage} / $TotalVotePage) * 100);
		}
		$self->{LocalPageRating} = int($self->{YesPageRating} - $self->{NoPageRating});
	}
		# overall site rating
	if ($TotalVoteSite != 0) {
		if ($self->{YesVotePage} != 0) {
			$self->{YesVoteRating} = int(($self->{YesVoteSite} / $TotalVoteSite) * 100);
		}
		if ($self->{NoVotePage} != 0) {
			$self->{NoVoteRating} = int(($self->{NoVoteSite} / $TotalVoteSite) * 100);
		}
		$self->{PageRating} = int($self->{YesVoteRating} - $self->{NoVoteRating});
	}
	#END BEWARE

	if (($self->{YesVotePage} != 0) || ($self->{NoVotePage} != 0)) {
		$self->{StarRating} = int(((((($self->{YesVotePage} - $self->{NoVotePage}) / ($self->{YesVotePage} + $self->{NoVotePage})) * 100 ) + 100 ) / 2 ) / 10 );
	} else {
        	$self->{StarRating} = 5;
        }

	$self->{TotalRating} = int((($self->{PageRating} + 100)/2)/10);

	# $self->{YesVoteRating}	percentage of yes votes for this page from all votes recorded sitewide
	# $self->{NoVoteRating}		percentage of no votes for this page from all votes recorded sitewide
	# $self->{YesPageRating}	percentage of yes votes for this page only
	# $self->{NoPageRating}		percentage of no votes for this page only
	# $self->{PageRating}		Actual value rating of page from entire site perspective *
	# $self->{LocalPageRating}	Actual value rating of page derived from only votes on this page *
	# $self->{YesVotePage}		Actual count of yes votes for page
	# $self->{YesVoteSite}		Actual count of yes votes for entire site
	# $self->{NoVotePage}		Actual count of no votes for page
	# $self->{NoVoteSite}		Actual count of no votes for entire site
	# $self->{StarRating}		yes votes vs no votes (0 - 10) **
	# $self->{TotalRating}		overall site rating of page (0 - 10) **
	#
	#    *		-100 to +100. +100 being all positive, -100 being all negative, 0 being 50/50
	#    **		5 means neutral rating
} #end sub (GetVote)


1;

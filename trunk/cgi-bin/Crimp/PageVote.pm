$ID = q$Id: PageVote.pm,v 1.1 2006-02-07 19:09:34 deadpan110 Exp $;
&printdebug('Module PageVote',
			'',
			'Authors: The CRIMP Team',
			"Version: $ID",
			'http://crimp.sourceforge.net/'
			);
			
&printdebug('','',"Started With: $crimp->{PageVote}");

####################################################################
my $YesVoteRating = 0;
my $NoVoteRating = 0;
my $PageRating = 0;
my $YesVotePage = 0;
my $YesVoteSite = 0;		# declare these for later use
my $NoVotePage = 0;
my $NoVoteSite = 0;
my $StarRating = 0;
my $TotalRating = 0;

my $message = 0;

my $query = new CGI;
	if ($query->param('PageVote')){
	if (($query->param('PageVote') eq 'yes')
		||($query->param('PageVote') eq 'good')
		||($query->param('PageVote') eq 'ok')){
				$message = 1;
	&PageVote('Yes');
}

elsif (($query->param('PageVote') eq 'no')
		||($query->param('PageVote') eq 'poor')
		||($query->param('PageVote') eq 'bad')) {
				$message = 2;
	&PageVote('No');
}
else{
	$message = 5;
	}
}

#Get Current results
&GetVote();

####################################################################

&printdebug('','',"Results (for use in comment tags within a template):",
						"&nbsp;&nbsp;&nbsp;YesRate (%): $YesVoteRating",
						"&nbsp;&nbsp;&nbsp;NoRate (%): $NoVoteRating",
						"&nbsp;&nbsp;&nbsp;TotalRate (%): $PageRating",
						"&nbsp;&nbsp;&nbsp;YesVotesTotal: $YesVotePage",
						"&nbsp;&nbsp;&nbsp;YesSiteTotal: $YesVoteSite",
						"&nbsp;&nbsp;&nbsp;NoVotesTotal: $NoVotePage",
						"&nbsp;&nbsp;&nbsp;NoSiteTotal: $NoVoteSite",
						"&nbsp;&nbsp;&nbsp;StarRating (1 to 10): $StarRating",
						"&nbsp;&nbsp;&nbsp;TotalRating (1 to 10): $TotalRating",
						);



my @PageVote = <<ENDEOF;
<a name="PageVote" id="PageVote"></a>
<hr/>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr>
      <td width="33%" align="left" valign="top"><font size='-1'><em><strong>Did you find this page useful?</strong></em><br />
          
          <form id="crimpPageVote" name="crimpPageVote" method="get" action="">
          	<strong>Vote:</strong><input name="PageVote" type="submit" id="PageVote" value="yes" />        
				<input name="PageVote" type="submit" value="no" />
          </form> 
               </td>
      <td width="34%" align="center" valign="top"><p align="center"><!--SubmitMessage--></p>
      </td>
      <td width="33%" align="right" valign="top"><font size='-1'>Current Rating : <!--TotalRate-->%<br/><br/>
       </font></td>
    </tr>
  </table>

ENDEOF

####################################################################

if ($crimp->{PageVote} ne "Default"){
# Use a Custom Template
my $requested = "$crimp->{HtmlDirectory}/crimp_assets/PageVote/$crimp->{PageVote}/style.htm";
if ( -f $requested ) {
		sysopen (FILE,$requested,O_RDONLY) || &printdebug('', 'fail', 'Couldnt open file for reading', "file: $requested", "error: $!");
			@PageVote=<FILE>;
		close(FILE);
	}else{	
		&printdebug('','warn',"Template '$crimp->{PageVote}' does not exist, using 'Default'");
		$crimp->{PageVote} ="Default";	
			}
	}


$PageVote = join ('',@PageVote);

####################################################################

#####
# All these tags need clearing before sending them into the page or menu

if($message eq 1){
	if ($PageVote =~ m/(<!--YesVote:)/){
		$PageVote =~ s!<\!--YesVote:(.*?)-->!!is;
		$message = $1;
		}else{
			$message="Thankyou for voting yes!";
		
	}	
}

elsif($message eq 2){
	if ($PageVote =~ m/(<!--NoVote:)/){
		$PageVote =~ s!<\!--NoVote:(.*?)-->!!is;
		$message = $1;
		}else{
			$message="Maybe you should join our mailing list and tell us how we can improve this page.";
		
	}	
}

elsif($message eq 3){
	if ($PageVote =~ m/(<!--VoidVote:)/){
		$PageVote =~ s!<\!--VoidVote:(.*?)-->!!is;
		$message = $1;
		}else{
			$message="You have already voted on this page today!";
		
	}	
}

elsif($message eq 4){
	if ($PageVote =~ m/(<!--ReVote:)/){
		$PageVote =~ s!<\!--ReVote:(.*?)-->!!is;
		$message = $1;
		}else{
			$message="Thankyou for coming back to vote on this page!";
		
	}	
}	

elsif($message eq 5){
	if ($PageVote =~ m/(<!--InvalidVote:)/){
		$PageVote =~ s!<\!--InvalidVote:(.*?)-->!!is;
		$message = $1;
		}else{
			$message="Oooh... look at you!!";
		
	}	
}else{$message = "&nbsp;";}

$PageVote =~ s/<!--YesRate-->/$YesVoteRating/gi;
$PageVote =~ s/<!--NoRate-->/$NoVoteRating/gi;
$PageVote =~ s/<!--TotalRate-->/$PageRating/gi;

$PageVote =~ s/<!--YesVotesTotal-->/$YesVotePage/gi;
$PageVote =~ s/<!--NoVotesTotal-->/$NoVotePage/gi;

$PageVote =~ s/<!--YesSiteTotal-->/$YesVoteSite/gi;
$PageVote =~ s/<!--NoSiteTotal-->/$NoVoteSite/gi;

$PageVote =~ s/<!--StarRating-->/$StarRating/gi;
$PageVote =~ s/<!--TotalRating-->/$TotalRating/gi;
$PageVote =~ s/<!--SubmitMessage-->/$message/gi;


####################################################################
## Decide if we are adding to the page or the menu ##
####################################################

if($PageVote =~ m/(<!--MenuContent)/){
&printdebug('','pass',"Using '$crimp->{PageVote}' PageVote Template in Menu");
&addMenuContent($PageVote);

}else{
&printdebug('','pass',"Using '$crimp->{PageVote}' PageVote Template in Content");
$PageVote = join("\n","<div id='crimpPageVote'>",$PageVote,'</div>');
$crimp->{DisplayHtml} =~ s|(</body>)|$PageVote\1|i;
}

########
## end ##
####################################################################

sub PageVote{
&printdebug('','',"Status: Checking for User");
my $MyVote = shift;

my $UserID = join '',$crimp->{RemoteHost},$crimp->{HttpRequest};
my $CurrTime = time;
my $UserTime = &FileRead('PageVoteUserTime',$UserID,$CurrTime);

#24 hours = 86400 seconds
my $TimeOut = 86400;


if ($UserTime eq $CurrTime){
	&printdebug('','',"Status: Adding Vote");
	&CountVote($MyVote);
}

elsif ($CurrTime lt ($UserTime + $TimeOut)){
	$message = 3;
	&printdebug('','',"Status: Refusing Vote");
}

elsif ($CurrTime gt ($UserTime + $TimeOut -1)){
	$message = 4;
	&FileWrite('PageVoteUserTime',$UserID,$CurrTime);
	&printdebug('','',"Status: Adding Another Vote");
	&CountVote($MyVote);
}

} #end sub

sub CountVote{
my $MyVote = shift;
my $VoteCountPage = &FileRead(join('','PageVote',$MyVote),$crimp->{HttpRequest},0);
my $VoteCountSite = &FileRead(join('','PageVote',$MyVote),'TotalVote',0);

$VoteCountPage++;
$VoteCountSite++;

my $VotePage = &FileWrite(join('','PageVote',$MyVote),$crimp->{HttpRequest},$VoteCountPage);
my $VoteSite = &FileWrite(join('','PageVote',$MyVote),'TotalVote',$VoteCountSite);

} #end sub

sub GetVote{
&printdebug('','',"Status: Getting Results");
$YesVotePage = &FileRead("PageVoteYes",$crimp->{HttpRequest},0);
$YesVoteSite = &FileRead("PageVoteYes",'TotalVote',0);

$NoVotePage = &FileRead("PageVoteNo",$crimp->{HttpRequest},0);
$NoVoteSite = &FileRead("PageVoteNo",'TotalVote',0);

$YesVoteRating = 0;
$NoVoteRating = 0;
$PageRating = 0;

my $TotalVoteSite = $YesVoteSite + $NoVoteSite;

#BEWARE 'DIVIDE by ZERO' ERRORS if altered
if ($TotalVoteSite ne 0){
	if ($YesVotePage ne 0){
		$YesVoteRating = int(($YesVotePage / $TotalVoteSite) * 100);
	}
	if ($NoVotePage ne 0){
		$NoVoteRating = int(($NoVotePage  / $TotalVoteSite) * 100);
	}
	$PageRating = int($YesVoteRating - $NoVoteRating);
}

if (($YesVotePage ne 0) || ($NoVotePage ne 0)){
		$StarRating = int(((((($YesVotePage - $NoVotePage) / ($YesVotePage + $NoVotePage)) * 100 ) + 100 ) / 2 ) / 10 );
	}else{$StarRating = 5}

$TotalRating = int((($PageRating + 100)/2)/10);


# $YesVoteRating			percentage of yes votes from total yes votes
# $NoVoteRating			percentage of no votes from total no votes
# $PageRating				Actual percentage rating of page against entire site (-100 - +100)*
# $YesVotePage				Actual count of yes votes for page
# $YesVoteSite				Actual count of yes votes for entire site
# $NoVotePage				Actual count of no votes for page
# $NoVoteSite				Actual count of no votes for entire site
# $StarRating				yes votes vs no votes (0 - 10)**
# $TotalRating				overall site rating of page (0 - 10)**
#
#										*		0 means average site rating
#										**		5 means neutral rating


} #end sub


1;
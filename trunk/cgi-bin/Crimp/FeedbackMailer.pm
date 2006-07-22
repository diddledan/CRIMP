package Crimp::FeedbackMailer;

sub new {
	my ($class, $crimp) = @_;
	my $self = {
		id => q$Id: FeedbackMailer.pm,v 1.1 2006-07-22 22:45:24 diddledan Exp $,
		crimp => $crimp,
		sendmail => '/usr/sbin/sendmail -t',
		errImg => '<img src="/crimp_assets/pics/error.gif" alt="error" title="error" style="vertical-align: middle;" />',
		};
	bless $self, $class;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};
	$crimp->printdebug('Module FeedbackMailer',
			'',
			'Authors: The CRIMP Team',
			"Version: $self->{id}",
			'http://crimp.sourceforge.net/'
			);

	eval "use Mail::Sendmail";
	if ($@) {
		$crimp->printdebug('','warn','Could not load the Mail::Sendmail package. Cannot complete execution of this module.');
		$crimp->addPageContent('<h2>Error</h2><p>The CRIMP engine could not load all necessary modules for this plugin.</p>');
		return;
	}

	my $validMail = $Mail::Sendmail::address_rx;
	unless ($crimp->queryParam('from') =~ m/$validMail/ && $crimp->queryParam('subject') && $crimp->queryParam('message')) {
		$self->displayFeedbackForm();
		return;
	}

	$self->sendFeedback();
}

sub displayFeedbackForm {
	my $self = shift;
	my $crimp = $self->{crimp};

	my $errImg = $self->{errImg};

	my $validMail = $Mail::Sendmail::address_rx;

	my $content = '<h2>Please send us your feedback...</h2><form method="post"><input type="hidden" name="postback" value="true" /><pre>';
	$content .= $errImg unless $crimp->queryParam('postback') ne 'true' || $crimp->queryParam('from') =~ m/$validMail/;
	$content .= "Your eMail Address: <input type='text' name='from' value='".$crimp->queryParam('from')."' />\n";
	$content .= $errImg if $crimp->queryParam('postback') eq 'true' && !$crimp->queryParam('subject');
	$content .= "Subject of eMail:   <input type='text' name='subject' value='".$crimp->queryParam('subject')."' />\n";
	$content .= $errImg if $crimp->queryParam('postback') eq 'true' && !$crimp->queryParam('message');
	$content .= "Message:\n<textarea cols='50' rows='15' name='message'>".$crimp->queryParam('message')."</textarea>\n";
	$content .= '<input type="submit" value="Send Feedback" /></pre></form>';

	$crimp->addPageContent($content);
}

sub sendFeedback {
	my $self = shift;
	my $crimp = $self->{crimp};

	%Mail = (
		To		=> $crimp->{Config}->{$crimp->userConfig}->{FeedbackMailer},
		From		=> 'CRIMP@'.$crimp->{_ServerName},
		'Reply-to' 	=> $crimp->queryParam('from'),
		Subject		=> $crimp->queryParam('subject'),
		Message		=> $crimp->queryParam('message'),
		'X-Mailer' 	=> 'CRIMP-'.$crimp->{VER}.'@'.$crimp->{_ServerName},
		);
		
	unless (sendmail(%Mail)) {
		$crimp->addPageContent('<h2>Error sending mail</h2><p>Your feedback email could not be sent. This may be a temporary error. If you receive the error consistently, please email the webmaster; this email address is usually webmaster@domain.tld, where domain.tld is the full domainname of the website you are currently viewing.</p>');
		$crimp->printdebug('','warn','Sendmail failed:',$Mail::Sendmail::error);
		return;
	}
	$crimp->addPageContent('<h2>Thankyou</h2><p>Your feedback has been received and queued for delivery to the appropriate mailbox.</p>');
}

1;

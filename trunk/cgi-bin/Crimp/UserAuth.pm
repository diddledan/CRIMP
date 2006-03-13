package Crimp::UserAuth;

sub new {
	my ($class, $crimp) = @_;
	my $self = { id => q$Id: UserAuth.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $, crimp => $crimp, };
	bless $self, $class;
}

sub execute {
	my $self = shift;
	
	$self->{crimp}->printdebug('Module UserAuth','',
				'Authors: The CRIMP Team',
				"Version: $self->{id}",
				'http://crimp.sourceforge.net/',
				);
	
	my $authMethod = 'passwd';
	
	$self->{crimp}->printdebug('','','Using plain text passwd backend');
	
	my ($username, $password, $cookie);
	if ($cookie = cookie(join ':', $self->{crimp}->userConfig, 'authtok')) {
		($username, $password) = split /:/, $cookie;
	}
	$username ||= $self->{crimp}->queryParam(username);
	$password ||= $self->{crimp}->queryParam(password);
	
	$self->{crimp}->printdebug('','',"UserName: $username","PassWord: $password");
	
	if (!$self->{crimp}->queryParam(postback) && !$cookie) {
		$self->setupLoginForm();
	} elsif (!$username || !$password) {
		$self->setupLoginForm('Username and Password must <em>both</em> be specified!');
	} elsif ($self->doFileAuth($username, $password)) {
		$self->{crimp}->printdebug('','pass',"User '$username' is authenticated to access this section");
		$self->{crimp}->addCookie, cookie(-name => join(':',$self->{crimp}->userConfig,'authtok'),
			-value => join(':',$username,$password),
			-path => $self->{crimp}->userConfig);
	} else {
		$self->{crimp}->setupLoginForm('Username and password do not match our database.');
	}
}

sub doFileAuth {
	my ($self, $user, $pass) = @_;
	
	if (!sysopen(AUTHFILE, $self->{crimp}->{Config}->{$self->{crimp}->userConfig}->{UserAuth}, O_RDONLY)) {
		$self->{crimp}->printdebug('','warn',"Couldn't open auth file: $!");
		return;
	}
	
	my @authfile = <AUTHFILE>;
	close(AUTHFILE);
	$self->{crimp}->printdebug('','',"checking for $user:$pass");
	if (grep /$user:$pass/, @authfile) { return 1; }
}

sub setupLoginForm {
	my $self = shift;
	my $msg = shift;
	$msg ||= 'You need to supply credentials for access to this area of the site.';
	
	# set exit code to 403 (forbidden)
	$self->{crimp}->ExitCode('403');
	$self->{crimp}->{skipRemainingPlugins} = 1;
	
	my $html = "
<div style='text-align: center;'>
	<br />
	<h2>Error 403: Forbidden</h2>
	<br />
	<p style='color: #f00;'>$msg</p>
	<br />
	<p><form method='post'>
		<input type='hidden' name='postback' value='1' />
		username: <input type='text' name='username' /><br />
		password: <input type='password' name='password' />
		<br /><br />
		<input type='submit' value='Access the secured section' />
	</form></p>
</div>
	";

	$self->{crimp}->addPageContent($html);
}

1;

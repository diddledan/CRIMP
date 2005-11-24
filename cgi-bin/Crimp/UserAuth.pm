$ID = q$Id: UserAuth.pm,v 1.3 2005-11-24 01:41:39 diddledan Exp $;
&printdebug('Module UserAuth','',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/',
				);

my $authMethod = 'passwd';

&printdebug('','','Using plain text passwd backend');

$query = new CGI;

my ($username, $password, $cookie);
if ($cookie = $query->cookie("$crimp->{UserConfig}:user/pass")) {
	($username, $password) = split /:/, $cookie;
}
if (!$cookie || !$username || !$password) {
	($username, $password) = ($query->param('username'), $query->param('password'));
}

if (!$query->param('postback') && !$cookie) {
	&setupLoginForm();
} elsif (!$username || !$password) {
	&setupLoginForm('Username and Password must both be specified!');
} elsif (&doFileAuth($username, $password)) {
	&printdebug('','pass',"User '$username is authenticated to access this section");
	push @cookies, $query->cookie(-name => "$crimp->{UserConfig}:user/pass",
											-value => "$username:$password",
											-path => $crimp->{UserConfig},
											);
} else {
	&setupLoginForm('Username and password do not match our database.');
}
	
sub doFileAuth {
	my ($user, $pass) = @_;
	if (!sysopen(AUTHFILE, $Config->{$crimp->{UserConfig}}->{UserAuth}, O_RDONLY)) {
		&printdebug('','warn',"Couldn't open auth file: $!");
		return 0;
	}
	
	my @authfile = <AUTHFILE>;
	close(AUTHFILE);
	&printdebug('','',"checking for $user:$pass");
	if (grep /$user:$pass/, @authfile) { return 1; }
}

sub setupLoginForm {
	my $msg = shift;
	$msg ||= 'You need to supply credentials for access to this area of the site.';
	
	# set exit code to 403 (forbidden)
	$crimp->{PageTitle} = 'Access Denied';
	$crimp->{ExitCode} = '403';
	$crimp->{skipRemainingPlugins} = 1;
	
	$crimp->{DisplayHtml} = "
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
}

1;
$crimp->{DebugMode} = 'on';
$ID = q$Id: UserAuth.pm,v 1.4 2006-03-01 22:59:26 diddledan Exp $;
&printdebug('Module UserAuth','',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/',
				);

my $authMethod = 'passwd';

&printdebug('','','Using plain text passwd backend');

my ($username, $password, $cookie);
if ($cookie = cookie("$crimp->{UserConfig}:authtok")) {
	($username, $password) = split /:/, $cookie;
}
$username ||= $crimp->{PostQuery}->{username};
$password ||= $crimp->{PostQuery}->{password};

&printdebug('','',"UserName: $username","PassWord: $password");

if (!$crimp->{PostQuery}->{postback} && !$cookie) {
	&setupLoginForm();
} elsif (!$username || !$password) {
	&setupLoginForm('Username and Password must <em>both</em> be specified!');
} elsif (&doFileAuth($username, $password)) {
	&printdebug('','pass',"User '$username is authenticated to access this section");
	push @cookies, cookie(-name => "$crimp->{UserConfig}:authtok",
                               -value => "$username:$password",
                               -path => $crimp->{UserConfig});
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
	$crimp->{ExitCode} = '403';
	$crimp->{skipRemainingPlugins} = 1;
	
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

	&addPageContent($html);
}

1;

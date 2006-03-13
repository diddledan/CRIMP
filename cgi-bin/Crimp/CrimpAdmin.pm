my $ID = q$Id: CrimpAdmin.pm,v 2.0 2006-03-13 23:48:34 diddledan Exp $;
&printdebug('Module CrimpAdmin',
				'',
				'Authors: The Crimp Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/',
				);

use Crypt::PasswdMD5;

my $query = new CGI;

$crimp->{ExitCode} = '403';

if (!$Config->{_}->{AdminPass}) {
	sub showPassSetForm {
		my $msg = shift;
		$crimp->{DisplayHtml} = "
<div style='text-align: center;'>
	<h2>Error 403: Forbidden</h2><br />
	<span style='color: #f00;'>$msg</span><br /><br />
	<form method='post'>
		<input type='hidden' name='postback' value='1' />
		Enter an administrative password which will be used to control access to this module.<br /><br />
		Password: <input type='password' name='password' /><br />
		Again: <input type='password' name='password2' /><br />		
		<input type='submit' value='Set Password' />
	</form>
</div>
";
	}

	&printdebug('','','Checking for password in config file: none found');
	if (!$query->param('postback')) {
		&showPassSetForm();
	} elsif (!$query->param('password')) {
		&showPassSetForm('You forgot to specify a password');
	} elsif ($query->param('password') ne $query->param('password2')) {
		&showPassSetForm('The two passwords you entered do not match. Please try again.');
	} else {
		$Config->{_}->{AdminPass} = unix_md5_crypt($query->param('password2'));
		if ($Config->write('crimp.ini')) { &printdebug('','pass','Writing new configuration file'); }
		else { &printdebug('','warn','Writing new configuration file failed. Check that the webserver can write to the file.'); }
	}
}

if ($Config->{_}->{AdminPass}) {
	&printdebug('','','Checking for password in config file: found');
	sub showLoginForm {
		my $msg = shift;
		$crimp->{DisplayHtml} = "
<div style='text-align: center;'>
	<h2>Error 403: Forbidden</h2><br />
	<form method='post'>
		<span style='color: #f00;'>$msg</span><br /><br />
		<input type='hidden' name='postback' value='1' />
		Enter administrative password: <input type='password' name='password' /><br />
		<input type='submit' value='Enter secured area' />
	</form>
</div>
";
	}
	
	my $cookie = $query->cookie("$crimp->{UserConfig}:pass");
	my $passy = $Config->{_}->{AdminPass};
	
	if (!$query->param('postback') && !$cookie) {
		&showLoginForm();
	} elsif (!$query->param('password') && !$cookie) {
		&showLoginForm('Password cannot be empty.');
	} elsif (unix_md5_crypt($query->param('password'), $passy) eq $passy || unix_md5_crypt($cookie, $passy) eq $passy) {
		&printdebug('','pass','User is authenticated to access the admin section.');
		push @cookies, $query->cookie(-name => "$crimp->{UserConfig}:pass",
												-value => $query->param('password'),
												-path => $crimp->{UserConfig},
												);
		&doAdminPage();
	} else {
		&showLoginForm('Password does not match our records');
	}
}

sub doAdminPage {
	my ($msg, $changed) = ('', 0);
	if ($query->param('password1') && $query->param('password1') eq $query->param('password2')) {
		$Config->{_}->{AdminPass} = unix_md5_crypt($query->param('password2'));
		$changed++;
	}
	
	if ($changed) {
		if ($Config->write('crimp.ini')) { $msg = 'Successfully wrote new configuration file'; }
		else { $msg = 'Failed to write new configuration file'; }
	}
	
	$crimp->{DisplayHtml} = "
<form method='post'>
<div style='text-align: center;'><table class='crimpAdmin'>
	<tr><th class='crimpAdmin' colspan='2'>CRIMP Administration</th></tr>
	<tr>
		<td colspan='2' style='color: #f00; text-align: center;'>&nbsp;$msg&nbsp;</td>
	</tr>
	<tr>
		<td class='crimpAdminDesc'>Reset Admin Password</td>
		<td class='crimpAdminItem'>
			<table class='crimpAdminItem'><tr><td>New Pass:</td><td><input type='password' name='password1' /></td></tr>
				<tr><td>Again:</td><td><input type='password' name='password2' /></td></tr></table>
		</td>
	</tr>
	<tr>
		<td class='crimpAdminDesc'>&nbsp;</td>
		<td class='crimpAdminItem'>&nbsp;</td>
	</tr>
	<tr><td style='text-align: center;' colspan='2'><input type='reset' value='Reset' /> <input type='submit' value='Submit Changes' /></td></tr>
</table></div>
</form>
";
}

1;
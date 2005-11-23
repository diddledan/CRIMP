$ID = q$Id: UserAuth.pm,v 1.2 2005-11-23 15:06:33 diddledan Exp $;
&printdebug('Module UserAuth','',
				'Authors: The CRIMP Team',
				"Version: $ID",
				'http://crimp.sourceforge.net/',
				);

if ($Config->{$crimp->{UserConfig}}->{UserAuth} ne '') {
	# set exit code to 403 (forbidden)
	$crimp->{PageTitle} = 'Access Denied';
	$crimp->{ExitCode} = '403';
	$crimp->{skipRemainingPlugins} = 1;
	
	$crimp->{DisplayHtml} = '
<div style="text-align: center;">
	<br />
	<h2>Error 403: Forbidden</h2>
	<br />
	<p>You need to supply credentials for access to this area of the site</p>
	<br />
	<p><form method="post">
		Please enter the pasword for this section: <input type="password" name="password" />
		<br /><br />
		<input type="submit" value="Access the secured section" />
	</form></p>
</div>
';

	$query = new CGI;
	my $passy = $Config->{$crimp->{UserConfig}}->{UserAuth};
	if (($query->param('password') eq $passy) || ($query->cookie("$crimp->{UserConfig}:pass") eq $passy)) {
		#clean up after ourselves, as the user is permitted access to this section...
		push @cookies, $query->cookie(-name => "$crimp->{UserConfig}:pass",
												-value => $passy,
												-path => $crimp->{UserConfig},
												);
		$crimp->{DisplayHtml} = '';
		$crimp->{ExitCode} = '500';
		$crimp->{skipRemainingPlugins} = 0;
	}
} else {
	&printdebug('','warn','Auth is not configured apropriately for this location');
}

1;
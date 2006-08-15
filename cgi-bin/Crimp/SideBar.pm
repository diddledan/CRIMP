package Crimp::SideBar;

sub new {
	my ($class, $crimp) = @_;
	my $self = {
		id => q$Id: SideBar.pm,v 1.2 2006-08-15 19:05:36 diddledan Exp $,
		crimp => $crimp,
		DisplayHtml => '',
	};
	bless $self, $class;

	my @plugins = $crimp->parsePlugins('Crimp::SideBar');
	my %pluginHandles = $crimp->loadPlugins($self,'Crimp::SideBar',@plugins);

	@{$self->{_plugins}} = @plugins;
	%{$self->{_pluginHandles}} = %pluginHandles;

	return $self;
}

sub execute {
	my $self = shift;
	my $crimp = $self->{crimp};

	@{$self->{_ConfigBase}} = (
		$crimp->{Config}->{$crimp->userConfig}->{plugin}->{SideBar},
		$crimp->{Config}->{_}->{plugin}->{SideBar},
	);

	$crimp->printdebug('','',
		'Authors: The CRIMP Team',
		'Version: '.$self->{id},
		'http://crimp.sourceforge.net/');

	if ($crimp->{_ConfigMode} ne 'xml') {
		$crimp->printdebug('','warn','This module requires that you are using the xml configuration file format');
		return;
	}

	$self->{skipRemainingPlugins} = 0;
	my %executedCommands;

	foreach (split ',', $self->{Config}->{$crimp->userConfig}->{plugin}->{SideBar}->{PluginOrder}) {
		$pluginname = join '::','Crimp','SideBar',$_;
		$crimp->executePlugin($_, $self->{_pluginHandles}->{$pluginname}, $self, @{$self->{_ConfigBase}}) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++) || ($self->Config($_, 'switch', @{$self->{_ConfigBase}}) eq 'off'));
	}
	foreach (split ',', $self->{Config}->{_}->{plugin}->{SideBar}->{PluginOrder}) {
		$pluginname = join '::','Crimp','SideBar',$_;
		$crimp->executePlugin($_, $self->{_pluginHandles}->{$pluginname}, $self, @{$self->{_ConfigBase}}) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++) || ($self->Config($_, 'switch', @{$self->{_ConfigBase}}) eq 'off'));
	}
	foreach (@{$self->{_plugins}}) {
		$pluginname = join '::','Crimp','SideBar',$_;
		$crimp->executePlugin($_, $self->{_pluginHandles}->{$pluginname}, $self, @{$self->{_ConfigBase}}) unless (($self->{skipRemainingPlugins}) || ($executedCommands{$_}++) || ($self->Config($_, 'switch', @{$self->{_ConfigBase}}) eq 'off'));
	}

	my $float;
	$float = $self->Config('SideBar');
	$float = "style='float: $float;'" if $float;
	$crimp->addPageContent("<div id='crimpSideBar' $float>$self->{DisplayHtml}</div>") if $self->{DisplayHtml};
}

sub Config {
	my $self = shift;
	my $crimp = $self->{crimp};
	my $plugin = shift;
	my $key = shift;
	return $crimp->Config($plugin, $key, @{$self->{_ConfigBase}});
}

sub addToSideBar {
	my $self = shift;
	my $content = shift;

	$self->{DisplayHtml} = "$self->{DisplayHtml}<div class='crimpSideBarPanel'>$content</div>";
}


1;

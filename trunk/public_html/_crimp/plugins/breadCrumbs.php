<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: breadCrumbs.php,v 1.7 2007-04-29 23:22:31 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class breadCrumbs implements iPlugin {
    protected $deferred;
    protected $pluginNum;
    protected $scope;
    protected $crimp;

    function __construct(&$crimp, $scope = SCOPE_CRIMP, $pluginNum = false, $deferred = false) {
        $this->deferred = $deferred;
        $this->pluginNum = $pluginNum;
        $this->scope = $scope;
        $this->crimp = &$crimp;
    }

    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;
        $pluginNum = $this->pluginNum;
        $pluginName = 'breadCrumbs';

        if ( !($config = $crimp->Config('position', $this->scope, $pluginName)) ) {
            $dbg->addDebug('Please define a <position /> tag in the config.xml file', WARN);
            return;
        }

        /**
         *this plugin should defer itself
         */
        if ( !$this->deferred ) {
            $crimp->setDeferral($pluginName, $pluginNum, $this->scope);
            return;
        }

        $position = $config;
        if ( $position != 'top' && $position != 'bottom' && $position != 'both' )
            $position = 'top';

        $dbg->addDebug('Config: '.$position, PASS);

        $BreadLink = '';
	$BreadCrumbs = "<a href='/$BreadLink'>home</a>";

        $HttpRequest = explode('/',$crimp->HTTPRequest());
	foreach ( $HttpRequest as $requestPart ) {
	    if ( $requestPart && $requestPart != 'index.html' ) {
		$BreadLink = "$BreadLink/$requestPart";
		$requestPart = preg_replace('/\.html$/', '', $requestPart);
		$BreadCrumbs = "$BreadCrumbs - <a href='$BreadLink'>$requestPart</a>";
	    }
	}

        if ( $position == 'top' || $position == 'both' )
            $crimp->addContent("<div id='crimpBreadCrumbsTop'><b>Location: $BreadCrumbs</b></div>", 'top');
        if ( $position == 'bottom' || $position == 'both' )
            $crimp->addContent("<div id='crimpBreadCrumbsBottom'><b>Location: $BreadCrumbs</b></div>", 'bottom');
    }
}

?>

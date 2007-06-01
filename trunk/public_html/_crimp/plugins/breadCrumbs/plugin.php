<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.2 2007-06-01 21:57:49 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class breadCrumbs extends Plugin {
    public function execute() {
        $crimp = &$this->Crimp;
        $pluginNum = $this->ConfigurationIndex;
        $pluginName = 'breadCrumbs';
	
        if ( !($config = $crimp->Config('position', $this->ConfigurationScope, $pluginName, $pluginNum)) ) {
            WARN('Please define a <position /> tag in the config.xml file');
            return;
        }
	
        /**
         *this plugin should defer itself
         */
        if ( !$this->IsDeferred ) {
            $crimp->setDeferral($pluginName, $pluginNum, $this->ConfigurationScope, $pluginNum);
            return;
        }
	
        $position = $config;
        if ( $position != 'top' && $position != 'bottom' && $position != 'both' )
            $position = 'top';
	
        PASS("$pluginName executing (position: $position)");
	
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

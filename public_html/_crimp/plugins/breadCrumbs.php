<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: breadCrumbs.php,v 1.2 2006-11-30 19:37:17 diddledan Exp $
 *
 *This library is free software; you can redistribute it and/or
 *modify it under the terms of the GNU Lesser General Public
 *License as published by the Free Software Foundation; either
 *version 2.1 of the License, or (at your option) any later version.
 *
 *This library is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *Lesser General Public License for more details.
 *
 *You should have received a copy of the GNU Lesser General Public
 *License along with this library; if not, write to the Free Software
 *Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
 */

class breadCrumbs extends plugin implements iPlugin {
    public function execute() {
        global $dbg, $crimp, $http;
        
        if ( ! isset($this->config['position']) ) {
            $dbg->addDebug('Please define a &lt;position /&gt; tag in the config.xml file', WARN);
            return;
        }
        
        $position = $this->config['position'];
        if ( $position != 'top' && $position != 'bottom' && $position != 'both' )
            $position = 'top';
        
        $dbg->addDebug('Config: '.$position, PASS);
        
        $BreadLink = '';
	$BreadCrumbs = "<a href='/$BreadLink'>home</a>";
        
        $HttpRequest = explode('/',$this->httpRequest);
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
<?php
/**
 *plugin.php - extendable plugin base class designed for use with CRIMP
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: plugin.php,v 1.2 2006-11-30 21:55:31 diddledan Exp $
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

interface iPlugin {
    public function execute();
}
class plugin {
    protected $config;
    protected $userConfig;
    protected $httpRequest;

    function plugin($userconfig, $httpRequest, $config) {
        $this->userConfig = $userconfig;
        $this->config = $config;
        $this->httpRequest = $httpRequest;
    }
}

class crimpPlugins {
    function execute($plugName, $file, $userconfig, $httpRequest, $config) {
        global $dbg;
        
        if ( !file_exists($file) || !is_readable($file) ) {
            $dbg->addDebug("plugin file for $plugName inaccessible", WARN);
            return;
        }
        
        require_once($file);
        
        $dbg->addDebug("Calling '$plugName' plugin", PASS);
        $newplugin = new $plugName($userconfig, $httpRequest, $config);
        $newplugin->execute();
    }
}
?>
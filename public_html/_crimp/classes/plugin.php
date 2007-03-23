<?php
/**
 *plugin.php - extendable plugin base class designed for use with CRIMP
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2007 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: plugin.php,v 1.5 2007-03-23 14:11:11 diddledan Exp $
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

class crimpPlugins {
    protected $crmip;

    function __construct(&$crimp) {
        $this->crimp = &$crimp;
    }

    function execute($plugName, $pluginNum, $file, $scope = SCOPE_ROOT, $deferred = false) {
        if ( !file_exists($file) || !is_readable($file) ) {
            $this->crimp->debug->addDebug("plugin file for '$plugName' inaccessible", WARN);
            return;
        }

        require_once($file);

        $this->crimp->debug->addDebug("Calling '$plugName' plugin", PASS);
        $newplugin = new $plugName( $this->crimp,
                                    $scope,
                                    $pluginNum,
                                    $deferred );
        $newplugin->execute();
    }
}

/**
 *this interface must be supported by all would-be plugins
 */
interface iPlugin {
    public function execute();
}
?>

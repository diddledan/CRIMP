<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.7 2007-04-29 23:22:27 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class crimpPlugins {
    protected $crmip;

    function __construct(&$crimp) {
        $this->crimp = &$crimp;
    }

    function execute($plugName, $pluginNum, $file, $scope, $deferred = false) {
        if ( !file_exists($file) || !is_readable($file) ) {
            $this->crimp->debug->addDebug("plugin file for '$plugName' inaccessible", WARN);
            return;
        }

        if (!@include_once($file)) {
            $this->crimp->debug->addDebug("Couldn't include() '$file'", WARN);
            return;
        }

        $newplugin = new $plugName( $this->crimp,
                                    $scope,
                                    $pluginNum,
                                    $deferred );
        if (!$newplugin) {
            $this->crimp->debug->addDebug("Failed to instantiate an object for plugin '$plugName' class", WARN);
            return;
        }
        $this->crimp->debug->addDebug("Calling '$plugName' plugin", PASS);
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

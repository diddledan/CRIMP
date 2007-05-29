<?php
/**
 * [[%(ask0:plugin name)]]: a plugin for CRIMP
 * (the Content Redirection Internet Management Program)
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                   HomePage:      http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.4 2007-05-29 23:17:31 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class [[%(ask0:Plugin Name)]] implements iPlugin {
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
        $pluginName = '[[%(ask0:Plugin Name)]]';

        /**
         *should this plugin defer itself?
         */
        $defer = [[%(ask:Should this plugin defer itself? (true or false):false)]];

        /**
         *check that we aren't locked
         */
        if ( $crimp->pluginLock($pluginName) ) {
            $dbg->addDebug('Exiting, as we are locked.');
            return;
        }

        /**
         *the value referenced by default configuration key, that you entered
         *in the komodo dialog, is stored in the variable $config
         */
        if ( !($config = $crimp->Config('[[%(ask1:Default Configuration Key)]]', $this->scope, $pluginName, $pluginNum)) ) {
            $dbg->addDebug('Please define a <[[%(ask1:Default Configuration Key)]]></[[%(ask1:Default Configuration Key)]]> tag in the config.xml file', WARN);
            return;
        }

        /**
         *the actual deferral check
         */
        if ( $defer && !$this->deferred ) {
            $dbg->addDebug('Deferring execution till later', PASS);
            $crimp->setDeferral($pluginName, $pluginNum, $this->scope);
            return;
        }

        /**
         *BEGIN CUSTOM PLUGIN CODE HERE
         */
    }
}

?>

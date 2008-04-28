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
 * Revision info: $Id: plugin.php,v 1.5 2007-06-04 12:03:59 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class [[%(ask0:Plugin Name)]] extends Plugin {
    public function execute() {
        $crimp = &$this->Crimp;
        $pluginNum = $this->ConfigurationIndex;
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
        if ( !($config = $crimp->Config('[[%(ask1:Default Configuration Key)]]', $this->ConfigurationScope, $pluginName, $pluginNum)) ) {
            WARN('Please define a &lt;[[%(ask1:Default Configuration Key)]]&gt&lt;/[[%(ask1:Default Configuration Key)]]&gt; tag in the config.xml file');
            return;
        }
        
        /**
         *the actual deferral check
         */
        if ( $defer && !$this->deferred ) {
            PASS('Deferring execution till later');
            $crimp->setDeferral($pluginName, $pluginNum, $this->ConfigurationScope);
            return;
        }
        
        /**
         *BEGIN CUSTOM PLUGIN CODE HERE
         */
    }
}

?>
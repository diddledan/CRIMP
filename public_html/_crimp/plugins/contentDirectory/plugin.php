<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.1 2007-05-01 20:17:31 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class contentDirectory implements iPlugin {
    protected $deferred;
    protected $scope;
    protected $crimp;

    function __construct(&$crimp, $scope = SCOPE_CRIMP, $pluginNum, $deferred = false) {
        $this->deferred = $deferred;
        $this->scope = $scope;
        $this->crimp = &$crimp;
    }

    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;

        $pluginName = 'contentDirectory';

        if ( !($config = $crimp->Config('directory', $this->scope, $pluginName)) ) {
            $dbg->addDebug('Please specify a <directory /> setting in the config file', WARN);
            return;
        }

        /**
         *Uncomment this if construct if this plugin should defer itself
         */
        #if ( !$this->deferred ) {
        #    $crimp->setDeferral($pluginName, $pluginNum, $this->scope);
        #    return;
        #}

        $path = $crimp->HTTPRequest();
        $userConfig = $crimp->userConfig();
        $path = preg_replace("|^$userConfig|i", '', $path);
        $path = preg_replace('|\.\.|', '', $path);
        $dbg->addDebug("Requested document: $path", PASS);

        if ( !$path ) $path = 'index.html';

        $requested = "$config/$path";

        if ( is_dir($requested) ) $requested = "$requested/index.html";

        $dbg->addDebug("Using File: $requested", PASS);

        if ( !is_file($requested) ) {
            $dbg->addDebug('File requested does not exist.', WARN);
            $crimp->errorPage($pluginName, '404');
            return;
        }
        if ( !is_readable($requested) ) {
            $dbg->addDebug('File requested exists, but is not readable. (Check permissions?)', WARN);
            $crimp->errorPage($pluginName, '500');
            return;
        }

        $display_content = $crimp->pageRead($requested);

        list($title, $content) = $crimp->stripHeaderFooter($display_content);
        if ( $title ) $crimp->setTitle($title);
        $crimp->addContent($content);

        if ( $crimp->exitCode() != '404' ) $crimp->exitCode('200');
    }
}

?>
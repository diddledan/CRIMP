<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.2 2007-06-01 21:57:48 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class contentDirectory extends Plugin {
    public function execute() {
        $crimp = &$this->Crimp;
        $pluginName = 'contentDirectory';
        $pluginNum = $this->ConfigurationIndex;
        
        if ( !($config = $crimp->Config('directory', $this->ConfigurationScope, $pluginName, $pluginNum)) ) {
            WARN('Please specify a &lt;directory /&gt; setting in the config file');
            $crimp->errorPage($pluginName, '500');
            return;
        }
        
        /**
         *Uncomment this 'if' construct if this plugin should defer itself
         */
        #if ( !$this->deferred ) {
        #    $crimp->setDeferral($pluginName, $pluginNum, $this->scope);
        #    return;
        #}
        
        $path = $crimp->HTTPRequest();
        $userConfig = $crimp->userConfig();
        $path = preg_replace("|^$userConfig|i", '', $path);
        $path = preg_replace('|\.\.|', '', $path);
        PASS("Requested document: $path");
        
        if ( !$path ) $path = 'index.html';
        
        $requested = "$config/$path";
        
        if ( is_dir($requested) ) $requested = "$requested/index.html";
        
        PASS("Using File: $requested");
        
        if ( !is_file($requested) ) {
            WARN('File requested does not exist.');
            $crimp->errorPage($pluginName, '404');
            return;
        }
        if ( !is_readable($requested) ) {
            WARN('File requested exists, but is not readable. (Check permissions?)');
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
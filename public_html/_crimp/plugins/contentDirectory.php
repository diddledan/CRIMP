<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: contentDirectory.php,v 1.3 2006-12-02 00:24:11 diddledan Exp $
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

class contentDirectory implements iPlugin {
    protected $deferred;
    protected $scope;
    protected $crimp;

    function __construct(&$crimp, $scope = SCOPE_ROOT, $deferred = false) {
        $this->deferred = $deferred;
        $this->scope = $scope;
        $this->crimp = &$crimp;
    }
    
    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;
        
        $pluginName = 'contentDirectory';
        
        if ( !($config = $this->crimp->Config('directory', $this->scope, 'contentDirectory')) ) {
            $dbg->addDebug('Please specify a <directory /> setting in the config file', WARN);
            return;
        }
        
        /**
         *Uncomment this if construct if this plugin should defer itself
         */
        #if ( !$this->deferred ) {
        #    $crimp->setDeferral($pluginName, $this->scope);
        #    return;
        #}
        
        $path = $crimp->HTTPRequest();
        $userConfig = $crimp->userConfig();
        $path = preg_replace("|^$userConfig|i", '', $path);
        $dbg->addDebug($path, PASS);
        
        if ( !$path ) $path = '/index.html';
        
        $requested = $crimp->Config('directory', $this->scope, $pluginName).'/'.$path;
        
        if ( is_dir($requested) ) $requested = $requested.'/index.html';
        
        $dbg->addDebug("contentDirectory\nUsing File: $requested", PASS);
        
        if ( !is_file($requested) ) {
            $dbg->addDebug('File requested does not exist.', WARN);
            $crimp->errorPage('contentDirectory', '404');
            return;
        }
        if ( !is_readable($requested) ) {
            $dbg->addDebug('File requested is not readable. (Check permissions?)', WARN);
            $crimp->errorPage('contentDirectory', '500');
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
<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2007 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: fileList.php,v 1.6 2007-04-29 20:37:33 diddledan Exp $
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

class fileList implements iPlugin {
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
        $pluginName = 'fileList';

        /**
         *this plugin relies on contentDirectory having been defined.
         */
        if ( !($config = $crimp->Config('directory', SCOPE_SECTION, 'contentDirectory')) ) {
            $dbg->addDebug('Please make sure that the contentDirectory plugin has been enabled properly in the config.xml file', WARN);
            return;
        }

        $DirList = '<b>Directories</b><br />&nbsp;&nbsp;&nbsp;';
	$FileList = '<b>Documents</b><br />&nbsp;&nbsp;&nbsp;';
	$DirCount = $FileCount = 0;

        $DirList = '<b>Directories:</b>';
	$FileList = '<b>Documents:</b>';

        if ( $crimp->Config('orientation', $this->scope, $pluginName) == 'vertical') {
	    $DirLayout = '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	    $DirList = $DirList.'<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	    $FileList = $FileList.'<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	} else {
            $DirLayout = ' | ';
            $DirList = $DirList.' ';
	    $FileList = $FileList.' ';
	}

        $FileDir = $config;

        $HttpRequest = split('/',$crimp->HTTPRequest());
        $BaseUrl = '';

        foreach ($HttpRequest as $_) {
	    if ( is_dir("$FileDir/$_") ) {
		$FileDir = $FileDir.'/'.$_;
		$BaseUrl = $BaseUrl.'/'.$_;
	    }
	}

        if ( !preg_match("|^{$crimp->userConfig()}|", $BaseUrl) )
            $BaseUrl = $crimp->userConfig().'/'.$BaseUrl;

	$BaseUrl = preg_replace('|/+|','/', $BaseUrl);
	$dbg->addDebug("FileDir: $FileDir\nBaseUrl: $BaseUrl", PASS);

        if ( is_dir($FileDir) ) {
	    $DIR = opendir($FileDir);
            if ( $DIR === false ) {
                $dbg->addDebug('Could not open the directory for reading (check permissions)', WARN);
                return;
            }

            while ( ($file = readdir($DIR)) !== false )
                $DirChk[] = $file;
	    closedir($DIR);

	    foreach ( $DirChk as $file ) {
		if (($file != '.') && ($file != '..') && ($file != 'index.html') && ($file != 'CVS')) {
		    if ( is_dir("$FileDir/$file") ) {
			$DirCount++;
			$newurl = $BaseUrl.'/'.$file;
			$newurl = preg_replace('|/+|', '/', $newurl);
			if ($DirCount != 1) $DirList = $DirList.$DirLayout;
			$DirList = "$DirList<a href='$newurl'>$file</a>\n";
		    } elseif ( preg_match('/\.html$/', $file) ) {
			$FileCount++;
			$file = preg_replace('/\.html$/', '', $file);
			$newurl = $BaseUrl.'/'.$file;
			$newurl = preg_replace('|/+|', '/', $newurl);
			$newurl = $newurl.'.html';
			if ($FileCount != 1) $FileList = $FileList.$DirLayout;
			$FileList="$FileList<a href='$newurl'>$file</a>\n";
                    }
		}
	    }

	    $dbg->addDebug("Directories found: $DirCount\nDocuments found: $FileCount", PASS);

	    $newhtml = '';
            if ( $DirCount > 0 ) $newhtml = $newhtml.$DirList;
	    if ( ($DirCount > 0) && ($FileCount > 0) ) $newhtml = $newhtml.'<br />';
	    if ( $FileCount != 0 ) $newhtml = $newhtml.$FileList;

	    $crimp->addMenu($newhtml);
	} else $dbg->addDebug('Directory does not exist, or we tried to open a file as a directory.', WARN);
    }
}

?>

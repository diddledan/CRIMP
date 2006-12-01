<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: fileList.php,v 1.2 2006-12-01 10:46:01 diddledan Exp $
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

class fileList extends plugin implements iPlugin {
    public function execute() {
        global $dbg, $crimp, $http;
        
        # this module should depend on contentDirectory, but we have no way
        # of knowing whether that plugin has been defined or not, so we go
        # ahead anyway.
        $DirList = '<b>Directories</b><br />&nbsp;&nbsp;&nbsp;';
	$FileList = '<b>Documents</b><br />&nbsp;&nbsp;&nbsp;';
	$DirCount = $FileCount = 0;
        
        $DirList = '<b>Directories:</b>';
	$FileList = '<b>Documents:</b>';
        
        if ( isset($this->config['orientation'] )
            && $this->config['orientation'] == 'vertical') { 
	    $DirLayout = '<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	    $DirList = $DirList.'<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	    $FileList = $FileList.'<br />&nbsp;&nbsp;&nbsp;&nbsp;';
	} else {
            $DirLayout = ' | ';
            $DirList = $DirList.' ';
	    $FileList = $FileList.' ';
	}
        
        $FileDir = $this->config['directory'];
        
        $HttpRequest = split('/',$this->httpRequest);
        $BaseUrl = '';
        
        foreach ($HttpRequest as $_) {
	    if ( is_dir("$FileDir/$_") ) {
		$FileDir = $FileDir.'/'.$_;
		$BaseUrl = $BaseUrl.'/'.$_;
	    }
	}
        
        if ( !preg_match("|^$this->userConfig|", $BaseUrl) )
            $BaseUrl = implode('/', $this->userConfig, $BaseUrl);
        
	$BaseUrl = preg_replace('|/+|','/', $BaseUrl);
	$dbg->addDebug("FileDir: $FileDir<br />BaseUrl: $BaseUrl", PASS);
        
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
	    
	    $dbg->addDebug("Directories found: $DirCount<br />Documents found: $FileCount", PASS);
	    
	    $newhtml = '';
            if ( $DirCount > 0 ) $newhtml = $newhtml.$DirList;
	    if ( ($DirCount > 0) && ($FileCount > 0) ) $newhtml = $newhtml.'<br />';
	    if ( $FileCount != 0 ) $newhtml = $newhtml.$FileList;
	    
	    $crimp->addMenu($newhtml);
	} else $dbg->addDebug('Directory does not exist, or we tried to open a file as a directory.', WARN);
    }
}

?>
<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.2 2007-06-01 21:57:49 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

class fileList extends Plugin {
    public function execute() {
        $crimp = &$this->Crimp;
        $pluginNum = $this->ConfigurationIndex;
        $pluginName = 'fileList';

        /**
         *this plugin relies on contentDirectory having been defined.
         */
        if ( !($config = $crimp->Config('directory', $this->ConfigurationScope, 'contentDirectory', $pluginNum)) ) {
            WARN('Please make sure that the contentDirectory plugin has been enabled properly in the config.xml file');
            return;
        }

        $DirList = '<b>Directories</b><br />&nbsp;&nbsp;&nbsp;';
	$FileList = '<b>Documents</b><br />&nbsp;&nbsp;&nbsp;';
	$DirCount = $FileCount = 0;

        $DirList = '<b>Directories:</b>';
	$FileList = '<b>Documents:</b>';

        if ( $crimp->Config('orientation', $this->ConfigurationScope, $pluginName, $pluginNum) == 'vertical') {
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
	PASS("$pluginName executing: (FileDir: $FileDir, BaseUrl: $BaseUrl)");

        if ( !is_dir($FileDir) ) {
	    WARN('Directory does not exist, or we tried to open a file as a directory.');
	    return;
	}
	
	$DIR = opendir($FileDir);
	if ( $DIR === false ) {
	    WARN('Could not open the directory for reading (check permissions)');
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
	
	$newhtml = '';
	if ( $DirCount > 0 ) $newhtml = $newhtml.$DirList;
	if ( ($DirCount > 0) && ($FileCount > 0) ) $newhtml = $newhtml.'<br />';
	if ( $FileCount != 0 ) $newhtml = $newhtml.$FileList;
	
	$crimp->addMenu($newhtml);
	StopTimer();
    }
}

?>

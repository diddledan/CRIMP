<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: html.php,v 1.2 2006-11-30 21:55:31 diddledan Exp $
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

class HTML {
    public function stripHeaderFooter($html) {
        #parse headers storing the title of the page
	preg_match('|<title>(.*?)</title>|si', $html, $title);
        $title = $title[1];
	#remove everything down to <body>
	$html = preg_replace('|.*?<body.*?>|si', '', $html);
	#remove everything after </body>
	$html = preg_replace('|</body>.*|si','',$html);
        
        return array($title, $html);
    }
    
    public function pageRead($file) {
        global $dbg, $crimp;
        $dbg->addDebug("<b>pageRead()</b> - builtin module\nFile: $file", PASS);

        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        else $dbg->addDebug('File is either non-existant or unreadable (permissions?)', WARN);

        $file = implode('/', ERRORDIR, '404.html');
        $crimp->exitCode('404');
        
        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        else $dbg->addDebug("Error page file is either non-existant or unreadable (permissions?)\nFilename: $file", WARN);

        $newhtml = <<<EOF
<h1>404 - Page Not Found</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
EOF;

        $FileRead = $crimp->defaultHTML;
        $FileRead = preg_replace('/(<body>)/i', "$1$newhtml", $FileRead);
        $FileRead = preg_replace('/(<title>)/i', '${1}404 - Page Not Found', $FileRead);
        return $FileRead;
    }
}
?>
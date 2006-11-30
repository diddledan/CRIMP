<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: config.php,v 1.2 2006-11-30 21:55:31 diddledan Exp $
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
require_once('Config.php');

class crimpConf {
    var $conf;
    var $root;
    var $configArray;
    
    public function crimpConf() {
        $this->conf = new Config;
        $this->root =& $this->conf->parseConfig('config.xml','XML');

        if ( PEAR::isError($this->root) )
            die("Configuration Parser failed to read the configuration:<br />&nbsp;&nbsp;&nbsp;&nbsp;{$this->root->getMessage}");

        $this->configArray = $this->root->toArray();
    }
    
    public function get() {
        return $this->configArray['root']['crimp'];
    }
}
?>
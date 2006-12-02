<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: conf.php,v 1.1 2006-12-02 00:15:08 diddledan Exp $
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

define('SCOPE_SECTION',  1);
define('SCOPE_GLOBALS',  2);
define('SCOPE_ROOT',     3);

require_once('Config.php');

class crimpConf {
    private $conf;
    private $root;
    protected $configArray;
    
    public function __construct(&$dbg) {
        $this->conf = new Config;
        $this->root =& $this->conf->parseConfig('config.xml','XML');
        
        if ( PEAR::isError($this->root) ) {
            $dbg->addDebug("Configuration Parser failed to read the configuration:<br />&nbsp;&nbsp;&nbsp;&nbsp;{$this->root->getMessage()}", FAIL);
            $dbg->render();
            die();
        }
        
        $this->configArray = $this->root->toArray();
        $this->configArray = $this->configArray['root']['crimp'];
    }
    
    public function get() {
        /**
         *reorganise the ['section'] hash/array. first force it to be an array,
         *then create a hash key for each section with the contents being the
         *contents of the <section /> tag (this means that the section name
         *is both in ['sections'][$sectname] and =['sections'][$sectname]['name']
         */
        if ( isset($this->configArray['section'])
            && (!is_array($this->configArray['section'])
            || !isset($this->configArray['section'][0])) )
            $this->configArray['section'] = array($this->configArray['section']);
        
        for ($i = 0; $i < count($this->configArray['section']); $i++) {
            $this->configArray['section'][$this->configArray['section'][$i]['name']] = $this->configArray['section'][$i];
            unset($this->configArray['section'][$i]);
        }
        
        /**
         *force plugins to be listed in an array format for each section
         */
        foreach ($this->configArray['section'] as $key => $section)
            if ( isset($section['plugin'])
                && (!is_array($section['plugin'])
                || !isset($section['plugin'][0])) )
                $this->configArray['section'][$key]['plugin'] = array($section['plugin']);
        
        /**
         *force plugins to be listed in an array format for the globals section.
         *first make sure the globals key exists.
         */
        if ( ! isset($this->configArray['globals']) )
            $this->configArray['globals'] = array();
        elseif ( isset($this->configArray['globals']['plugin'])
                && (!is_array($this->configArray['globals']['plugin'])
                || !isset($this->configArray['plugin'][0])) )
            $this->configArray['globals']['plugin'] = array($this->configArray['globals']['plugin']);
        
        /**
         *force the root namespace's plugin declaration(s) to be in array form
         */
        if ( isset($this->configArray['plugin'])
            && (!is_array($this->configArray['plugin'])
            || !isset($this->configArray['plugin'][0])) )
            $this->configArray['plugin'] = array($this->configArray['plugin']);
        
        /**
         *return the configuration array
         */
        return $this->configArray;
    }
}
?>
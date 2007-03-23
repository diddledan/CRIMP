<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: conf.php,v 1.3 2007-03-23 14:02:48 diddledan Exp $
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

function crimpConf() {
    $conf = new Config;
    $root =& $conf->parseConfig('config.xml','XML');
    unset($conf);

    if ( PEAR::isError($root) ) {
        return $root;
    }

    $configArray = $root->toArray();
    unset($root);
    $configArray = $configArray['root']['crimp'];

    /**
     *reorganise the ['section'] hash/array. first force it to be an array,
     *then create a hash key for each section with the contents being the
     *contents of the <section /> tag (this means that the section name
     *is both in ['sections'][$sectname] and =['sections'][$sectname]['name']
     */
    if ( isset($configArray['section'])
        && (!is_array($configArray['section'])
            || !isset($configArray['section'][0])) )
        $configArray['section'] = array($configArray['section']);

    for ($i = 0; $i < count($configArray['section']); $i++) {
        $configArray['section'][$configArray['section'][$i]['name']] = $configArray['section'][$i];
        unset($configArray['section'][$i]);
    }

    /**
     *force plugins to be listed in an array format for each section
     */
    foreach ($configArray['section'] as $key => $section)
        if ( isset($section['plugin'])
            && (!is_array($section['plugin'])
                || !isset($section['plugin'][0])) )
            $configArray['section'][$key]['plugin'] = array($section['plugin']);

    /**
     *force plugins to be listed in an array format for the globals section.
     *first make sure the globals key exists.
     */
    if ( ! isset($configArray['globals']) )
        $configArray['globals'] = array();
    elseif ( isset($configArray['globals']['plugin'])
            && (!is_array($configArray['globals']['plugin'])
                || !isset($configArray['plugin'][0])) )
        $configArray['globals']['plugin'] = array($configArray['globals']['plugin']);

    /**
     *force the root namespace's plugin declaration(s) to be in array form
     */
    if ( isset($configArray['plugin'])
        && (!is_array($configArray['plugin'])
            || !isset($configArray['plugin'][0])) )
        $configArray['plugin'] = array($configArray['plugin']);

    /**
     *return the configuration array
     */
    return $configArray;
}
?>

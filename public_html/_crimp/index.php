<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: index.php,v 1.3 2006-12-02 00:14:27 diddledan Exp $
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

/**
 *this sets the CRIMP_HOME constant to the directory containing this very file
 */
define('CRIMP_HOME', dirname(__FILE__));

/**
 *tell php where to look for our classes
 */
set_include_path('./classes'.PATH_SEPARATOR.get_include_path());

/**
 *debug routines
 */
require_once('Debug.php');

/**
 *our own config interface to the 'Config' pear module
 */
require_once('conf.php');

/**
 *plugin architecture
 */
require_once('plugin.php');
/**
 *the HTTP pear module
 */
require_once('HTTP.php');
/**
 *Main class - this is where the bulk of the app resides
 */
require_once('crimp.php');
$crimp = new Crimp($dbg, $config);

/**
 *do the plugin thing
 */
$crimp->executePlugins();

/**
 *send the completed page
 */
$crimp->sendDocument();

?>
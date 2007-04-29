<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: index.php,v 1.7 2007-04-29 23:22:31 diddledan Exp $
 *
 * This file is released under the LGPL License.
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
 *plugin architecture
 */
require_once('plugin.php');

/**
 *Main class - this is where the bulk of the app resides
 */
require_once('crimp.php');
$crimp = new Crimp;

/**
 *do the plugin thing
 */
$crimp->executePlugins();

/**
 *send the completed page
 */
$crimp->sendDocument();

?>
<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: index.php,v 2.4 2007-06-07 21:33:56 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

/**
 *this sets the CRIMP_HOME constant to the directory containing this very file
 */
define('DOC_ROOT', dirname(__FILE__));
define('CRIMP_HOME', DOC_ROOT.'/_crimp');

/**
 *tell php where to look for our classes
 */
set_include_path('./_crimp/classes');

/**
 *debug routines
 */
require_once('PHP/Debug.php');

/**
 *negotiatelanguage
 */
require_once('HTTP.php');

/**
 *plugin architecture
 */
require_once('plugin.php');

/**
 *Main class - this is where the bulk of the app resides
 */
require_once('crimp.php');
$crimp = new Crimp;
$crimp->setup();

/**
 *do the plugin thing
 */
$crimp->executePlugins();

/**
 *send the completed page
 */
$crimp->sendDocument();

function PASS($message) {
    global $crimp;
    $crimp->PASS($message);
}
function WARN($message) {
    global $crimp;
    $crimp->WARN($message);
}
function FAIL($message) {
    global $crimp;
    $crimp->FAIL($message);
}
function DUMP($variable, $varname = '') {
    global $crimp;
    $crimp->DUMP($variable, $varname);
}
function StopTimer() {
    global $crimp;
    $crimp->StopTimer();
}
?>
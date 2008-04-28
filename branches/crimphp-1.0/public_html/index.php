<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: index.php,v 2.5 2007-08-22 12:38:49 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

/**
 *debugging helper routines
 */
function PASS($message) {
    global $crimp;
    if ($crimp) $crimp->PASS($message);
}
function WARN($message) {
    global $crimp;
    if ($crimp) $crimp->WARN($message);
}
function FAIL($message) {
    global $crimp;
    if ($crimp) $crimp->FAIL($message);
}
function DUMP($variable, $varname = '') {
    global $crimp;
    if ($crimp) $crimp->DUMP($variable, $varname);
}
function StopTimer() {
    global $crimp;
    if ($crimp) $crimp->StopTimer();
}

/**
 *-----------------
 */

/**
 *this sets the CRIMP_HOME constant to the directory containing this very file
 */
define('DOC_ROOT', dirname(__FILE__));
define('CRIMP_HOME', DOC_ROOT.'/_crimp');

/**
 *tell php where to look for our classes
 */
set_include_path(CRIMP_HOME.'/classes');

/**
 *import crimp
 */
require_once('crimp.php');
/**
 *initialise the app
 */
$crimp = new Crimp;
/**
 *run the program
 */
$crimp->run();
?>
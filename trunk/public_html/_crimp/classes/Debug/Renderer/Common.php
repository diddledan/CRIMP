<?php
/**
 * This is a debugging routine developed for use with crimp based heavily on
 * PHP Debug (http://www.php-debug.com/)
 * 
 *---
 * 
 * PHP_Debug : A simple and fast way to debug your PHP code
 * 
 * The basic purpose of PHP_Debug is to provide assistance in debugging PHP
 * code, by "debug" i don't mean "step by step debug" but program trace,
 * variables display, process time, included files, queries executed, watch
 * variables... These informations are gathered through the script execution and
 * therefore are displayed at the end of the script (in a nice floating div or a
 * html table) so that it can be read and used at any moment. (especially
 * usefull during the development phase of a project or in production with a
 * secure key/ip)
 *
 * PHP version 5 only
 * 
 *---
 * 
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: Common.php,v 1.6 2007-05-29 23:20:31 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 */

/**
 * A base class for Debug renderers, must be inherited by all such.
 *
 * @package PHP_Debug
 * @category PHP
 * @author Loic Vernet <qrf_coil at yahoo dot fr>
 * @since 10 Apr 2006
 * 
 * @package PHP_Debug
 * @filesource
 */

class PHP_Debug_Renderer_Common
{
    /**
     * 
     * @var Debug object
     * This is the debug object to render
     */    
    protected $DebugObject = null;

    /**
     * Run-time configuration options.
     *
     * @var array
     * @access public
     */
    protected $options = array();

    /**
     * Default configuration options.
     *
     * @See Debug/Renderer/*.php for the complete list of options
     * @var array
     * @access public
     */
    protected $defaultOptions = array();

    /**
     * Set run-time configuration options for the renderer
     *
     * @param array $options Run-time configuration options.
     * @access public
     */
    public function setOptions($options = array())
    {
        $this->options = array_merge($this->defaultOptions, $options);
    }

    /**
     * Default output function
     */
    public function __tostring()
    {
        return '<pre>'. PHP_Debug::dumpVar($this, __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '<pre>';  
    }

    /**
     * PHP_DebugOutput class destructor
     */
    function __destruct()
    {
    }
}

?>
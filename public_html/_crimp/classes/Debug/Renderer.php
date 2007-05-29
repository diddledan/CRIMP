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
 * Revision info: $Id: Renderer.php,v 1.7 2007-05-29 23:20:31 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 */

require_once 'Debug/Renderer/Common.php';

/**
 * A loader class for the renderers.
 *
 * @package PHP_Debug
 * @category PHP
 * @author Loic Vernet <qrf_coil at yahoo dot fr>
 * @since 10 Apr 2006
 * 
 * @package PHP_Debug
 * @filesource
 */

class PHP_Debug_Renderer
{

    /**
     * Attempt to return a concrete Debug_Renderer instance.
     *
     * @param string $mode Name of the renderer.
     * @param array $options Parameters for the rendering.
     * @access public
     */
    static function factory($debugObject, $options)
    {
        $className = 'PHP_Debug_Renderer_' . $options['DEBUG_render_mode'];
        $classPath = 'Debug/Renderer/'. $options['DEBUG_render_mode']. '.php';
        include_once $classPath;

        if (class_exists($className)) {
            $obj = new $className($debugObject, $options);
        } else {
            include_once 'PEAR.php';
            PEAR::raiseError('PHP_Debug: renderer "' . $options['DEBUG_render_mode'] . '" not found', TRUE);
            return NULL;
        }
        
        return $obj;
    }
}

?>
<?php
/**
 *Debug - A debugging routine developed for use with crimp based heavily on
 *PHP Debug (http://www.php-debug.com/)
 *
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2007 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: Common.php,v 1.4 2007-03-23 14:11:12 diddledan Exp $
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

class Debug_Renderer_Common
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
        return '<pre>'. Debug::dumpVar($this, __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '<pre>';  
    }

    /**
     * PHP_DebugOutput class destructor
     */
    function __destruct()
    {
    }
}

?>
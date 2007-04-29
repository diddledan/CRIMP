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
 *Revision info: $Id: Renderer.php,v 1.5 2007-04-29 20:37:32 diddledan Exp $
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
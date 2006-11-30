<?php

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

class Debug_Renderer
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
        //Debug::dumpVar($options, "Debug_Renderer::options");

        $className = 'Debug_Renderer_' . $options['DEBUG_render_mode'];
        include_once 'Debug/Renderer/'. $options['DEBUG_render_mode']. '.php';

        if (class_exists($className)) {
            $obj = new $className($debugObject, $options);
        } else {
            include_once 'PEAR.php';
            PEAR::raiseError('Debug: renderer "' . $options['DEBUG_render_mode'] . '" not found', TRUE);
            return NULL;
        }
        
        return $obj;
    }
}

?>
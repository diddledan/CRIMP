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
 * Revision info: $Id: HTML_Div_Config.php,v 1.1 2007-04-29 20:37:32 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 */

/**
 * Configuration file for HTML_Div renderer
 *
 * @package PHP_Debug
 * @category PHP
 * @author Loïc Vernet <qrf_coil at yahoo dot fr>
 * @since  29 march 2007
 * 
 * @package PHP_Debug
 * @filesource
 */

class PHP_Debug_Renderer_HTML_Div_Config
{    
    /**
     * Config container for Debug_Renderer_HTML_Div
     * 
     * @var array
     * @since V2.0.0 - 11 apr 2006
     */
    static $options = array();

    /**
     * Static Instance of class
     *  
     * @var array
     * @since V2.0.0 - 11 apr 2006
     */
    static $instance = null;
        
    /**
     * Debug_Renderer_HTML_DIV_Config class constructor
     * 
     * @since V2.0.0 - 11 apr 2006
     */
    private function __construct()
    {
        /**
         * Enable or disable Credits in debug infos 
         */
        self::$options['HTML_DIV_disable_credits'] = false;

        /**
         * Enable or disable pattern removing in included files
         */
        self::$options['HTML_DIV_remove_templates_pattern'] = false;
        
        /**
         * Pattern list to remove in the display of included files
         * if HTML_DIV_remove_templates_pattern is set to true
         */ 
        self::$options['HTML_DIV_templates_pattern'] = array(); 

        /** 
         * View Source script path
         */
        self::$options['HTML_DIV_view_source_script_path'] = '.';  
        
        /** 
         * View source script file name
         */     
        self::$options['HTML_DIV_view_source_script_name'] = /*'PHP_Debug_show_source.php'*/'';

        /** 
         * Tabsize for view source script
         */     
        self::$options['HTML_DIV_view_source_tabsize'] = 4; 

        /** 
         * Tabsize for view source script
         */     
        self::$options['HTML_DIV_view_source_numbers'] = 2; //HL_NUMBERS_TABLE

        /** 
         * images
         */     
        self::$options['HTML_DIV_images_path'] = '/crimp_assets/images'; 
        self::$options['HTML_DIV_image_info'] = '/crimp_assets/info.png'; 
        self::$options['HTML_DIV_image_warning'] = '/crimp_assets/warning.png'; 
        self::$options['HTML_DIV_image_error'] = '/crimp_assets/error.png'; 

        /** 
         * css path
         */     
        self::$options['HTML_DIV_css_path'] = '/crimp_assets/debug-css'; 

        /** 
         * js path
         */     
        self::$options['HTML_DIV_js_path'] = 'js'; 
        
        /**
         * Class name of the debug info levels
         */
        self::$options['HTML_DIV_debug_level_classes'] = array(
            PHP_DEBUGLINE_INFO_LEVEL     => 'sfWebDebugInfo',
            PHP_DEBUGLINE_WARNING_LEVEL  => 'sfWebDebugWarning',
            PHP_DEBUGLINE_ERROR_LEVEL    => 'sfWebDebugError',
        );

        /**
         * After this goes all HTML related variables
         * 
         * HTML code for header 
         */         
         self::$options['HTML_DIV_header'] = '
<div id="sfWebDebug">

    <div id="sfWebDebugBar" class="sfWebDebugInfo">
        <div id="title">
            <a href="#" onclick="sfWebDebugToggleMenu(); return false;"><b>&raquo; PHP_Debug</b></a>
        </div>
        <ul id="sfWebDebugDetails" class="menu">
            <li>{$phpDebugVersion}</li>
            <li><a href="#" onclick="sfWebDebugShowDetailsFor(\'sfWebDebugConfig\'); return false;"><img src="{$imagesPath}/config.png" alt="Config" /> vars &amp; config</a></li>
            <li><a href="#" onclick="sfWebDebugShowDetailsFor(\'sfWebDebugLog\'); return false;"><img src="{$imagesPath}/comment.png" alt="Comment" /> logs &amp; msgs</a></li>
            <li><a href="#" onclick="sfWebDebugShowDetailsFor(\'sfWebDebugDatabaseDetails\'); return false;"><img src="{$imagesPath}/database.png" alt="Database" /> {$nb_queries}</a></li>
            <li class="last"><a href="#" onclick="sfWebDebugShowDetailsFor(\'sfWebDebugTimeDetails\'); return false;"><img src="{$imagesPath}/time.png" alt="Time" /> {$exec_time} ms</a></li>
        </ul>
        <a href="#" onclick="document.getElementById(\'sfWebDebug\').style.display=\'none\'; return false;"><img src="{$imagesPath}/close.png" alt="Close" /></a>
    </div> <!-- End sfWebDebugBar -->

';

        /**
         * HTML code for debug time tab
         */         
         self::$options['HTML_DIV_sfWebDebugTimeDetails'] = '

    <div id="sfWebDebugTimeDetails" class="top" style="display: none">
        <h1>Timers</h1>
        <table class="sfWebDebugLogs" style="width: 300px">
            <tr>
                <th>type</th>
                <th>time (ms)</th>
                <th>percent</th>
            </tr>
            <tr>
                <td class="sfWebDebugLogTypePerf">{$txtExecutionTime}</td>
                <td style="text-align: right">{$processTime}</td>
                <td style="text-align: right">100%</td>
            </tr>
            <tr>
                <td class="sfWebDebugLogTypePerf">{$txtPHP}</td>
                <td style="text-align: right">{$phpTime}</td>
                <td style="text-align: right">{$phpPercent}%</td>
            </tr>
            <tr>
                <td class="sfWebDebugLogTypePerf">{$txtSQL}</td>
                <td style="text-align: right">{$sqlTime}</td>
                <td style="text-align: right">{$sqlPercent}% : {$queryCount} {$txtQuery}</td>
            </tr>
            {$buffer}
        </table>
    </div> <!-- End sfWebDebugTimeDetails -->

';

        /**
         * HTML code for database tab
         */         
         self::$options['HTML_DIV_sfWebDebugDatabaseDetails'] = '

    <div id="sfWebDebugDatabaseDetails" class="top" style="display: none">
        <h1>Database / SQL queries</h1>

        <div id="sfWebDebugDatabaseLogs">
            <ol>
                {$buffer}
            </ol>
        </div>

    </div> <!-- End sfWebDebugDatabaseDetails -->

';

        /**
         * HTML code for Log & msg tab
         */         
    self::$options['HTML_DIV_sfWebDebugLog'] = '

    <div id="sfWebDebugLog" class="top" style="display: none"><h1>Log and debug messages</h1>
        <ul id="sfWebDebugLogMenu">
            <li><a href="#" onclick="sfWebDebugToggleAllLogLines(true, \'sfWebDebugLogLine\'); return false;">[all]</a></li>
            <li><a href="#" onclick="sfWebDebugToggleAllLogLines(false, \'sfWebDebugLogLine\'); return false;">[none]</a></li>
            <li><a href="#" onclick="sfWebDebugShowOnlyLogLines(\'info\'); return false;"><img src="{$imagesPath}/info.png" alt="Info" /></a></li>
            <li><a href="#" onclick="sfWebDebugShowOnlyLogLines(\'warning\'); return false;"><img src="{$imagesPath}/warning.png" alt="Warning" /></a></li>
            <li><a href="#" onclick="sfWebDebugShowOnlyLogLines(\'error\'); return false;"><img src="{$imagesPath}/error.png" alt="Error" /></a></li>
        </ul>

        <div id="sfWebDebugLogLines">
            <table class="sfWebDebugLogs">
                <tr>
                    <th>#</th>
                    <th>type</th>
                    <th>file</th>
                    <th>line</th>
                    <th>class</th>
                    <th>function</th>
                    <th>time</th>
                    <th>message</th>
                </tr>
                {$buffer}
            </table>
        </div>
    </div> <!-- End sfWebDebugLog -->

';

        /**
         * HTML code for Vars & config tab
         */         
    self::$options['HTML_DIV_sfWebDebugConfig'] = '

    <div id="sfWebDebugConfig" class="top" style="display: none">
        <h1>Configuration and request variables</h1>

        <h2>Request <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugRequest\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>

        <div id="sfWebDebugRequest" style="display: none">
{$sfWebDebugRequest}
        </div>

        <h2>Response <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugResponse\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>
        <div id="sfWebDebugResponse" style="display: none">
{$sfWebDebugResponse}
        </div>

        <h2>Settings <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugSettings\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>
        <div id="sfWebDebugSettings" style="display: none">
{$sfWebDebugSettings}
        </div>

        <h2>Globals <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugGlobals\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>
        <div id="sfWebDebugGlobals" style="display: none">
{$sfWebDebugGlobals}
        </div>

        <h2>Php <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugPhp\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>
        <div id="sfWebDebugPhp" style="display: none">
{$sfWebDebugPhp}
        </div>

        <h2>Files <a href="#" onclick="sfWebDebugToggle(\'sfWebDebugFiles\'); return false;"><img src="{$imagesPath}/toggle.gif" alt="Toggle" /></a></h2>
        <div id="sfWebDebugFiles" style="display: none">
{$sfWebDebugFiles}
        </div>

    </div> <!-- End sfWebDebugConfig -->

';
        
        /**
         * HTML code for credits 
         */         
         self::$options['HTML_DIV_credits'] = '
        PHP_Debug ['. PHP_DEBUG_RELEASE .'] | By COil (2007) | 
        <a href="http://www.coilblog.com">http://www.coilblog.com</a> | 
        <a href="http://phpdebug.sourceforge.net/">PHP_Debug Project Home</a> 
        ';

        /**
         * HTML code for a basic header 
         */         
         self::$options['HTML_DIV_simple_header'] = '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Pear::PHP_Debug</title>

';

        /**
         * HTML code for a basic footer 
         */         
         self::$options['HTML_DIV_simple_footer'] = '
</body>
</html>

';

        /**
         * HTML code for footer 
         */         
         self::$options['HTML_DIV_footer'] = '

</div> <!-- End div sfWebDebug -->

';

    }

    /**
     * returns the static instance of the class
     *
     * @since V2.0.0 - 11 apr 2006
     * @see PHP_Debug
     */
    public static function singleton()
    {
        if (!isset(self::$instance)) {
            $class = __CLASS__;
            self::$instance = new $class;
        }
        return self::$instance;
    }
    
    /**
     * returns the configuration
     *
     * @since V2.0.0 - 07 apr 2006
     * @see PHP_Debug
     */
    static function getConfig()
    {
        return self::$options;
    }
    
    /**
     * HTML_DIV_Config
     * 
     * @since V2.0.0 - 26 Apr 2006
     */
    function __tostring()
    {
        return '<pre>'. PHP_Debug::dumpVar($this->singleton()->getConfig(), __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '</pre>';
    }   
}

?>
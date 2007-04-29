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
 * Revision info: $Id: HTML_Table_Config.php,v 1.5 2007-04-29 20:37:32 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 */

/**
 * Configuration file for HTML_Table renderer
 *
 * @package PHP_Debug
 * @category PHP
 * @author Loic Vernet <qrf_coil at yahoo dot fr>
 * @since 10 Apr 2006
 * 
 * @package PHP_Debug
 * @filesource
 */

class PHP_Debug_Renderer_HTML_Table_Config
{    
    /**
     * Config container for Debug_Renderer_HTML_Table
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
     * Debug_Renderer_HTML_Table_Config class constructor
     * 
     * @since V2.0.0 - 11 apr 2006
     */
    private function __construct()
    {
        /**
         * Enable or disable Credits in debug infos 
         */
        self::$options['HTML_TABLE_disable_credits'] = false;

        /**
         * Enable or disable included and required files
         */ 
        self::$options['HTML_TABLE_show_templates'] = true;
        
        /**
         * Enable or disable pattern removing in included files
         */
        self::$options['HTML_TABLE_remove_templates_pattern'] = false;
        
        /**
         * Pattern list to remove in the display of included files
         * if HTML_TABLE_remove_templates_pattern is set to true
         */ 
        self::$options['HTML_TABLE_templates_pattern'] = array(); 

        /**
         * Enable or disable visualisation of $globals var in debug
         */
        self::$options['HTML_TABLE_show_globals'] = false;   

        /** 
         * Enable or disable search in debug 
         */ 
        self::$options['HTML_TABLE_enable_search'] = true; 

        /** 
         * Enable or disable view of super arrays 
         */
        self::$options['HTML_TABLE_show_super_array'] = false;

        /** 
         * Enable or disable the use of $_REQUEST array instead of 
         * $_POST + _$GET + $_COOKIE + $_FILES
         */
        self::$options['HTML_TABLE_use_request_arr'] = false;  

        /** 
         * View Source script path
         */
        self::$options['HTML_TABLE_view_source_script_path'] = '.';  
        
        /** 
         * View source script file name
         */     
        self::$options['HTML_TABLE_view_source_script_name'] = /*'PHP_Debug_show_source.php'*/''; 

        /** 
         * css path
         */     
        self::$options['HTML_TABLE_css_path'] = '/crimp_assets/debug-css'; 

        /** 
         * Tabsize for view source script
         */     
        self::$options['HTML_TABLE_view_source_tabsize'] = 4; 

        /** 
         * Tabsize for view source script
         */     
        self::$options['HTML_TABLE_view_source_numbers'] = 2; //HL_NUMBERS_TABLE 

       /** 
        * Define wether the display must be forced for the debug type when
        * in search mode
        */
        self::$options['HTML_TABLE_search_forced_type'] = array( 
            PHP_DEBUGLINE_STD         => false, 
            PHP_DEBUGLINE_QUERY       => false, 
            PHP_DEBUGLINE_QUERYREL    => false,
            PHP_DEBUGLINE_ENV         => false,
            PHP_DEBUGLINE_APPERROR    => false,
            PHP_DEBUGLINE_CREDITS     => false,
            PHP_DEBUGLINE_SEARCH      => true,
            PHP_DEBUGLINE_DUMP        => false,
            PHP_DEBUGLINE_PROCESSPERF => false,
            PHP_DEBUGLINE_TEMPLATES   => false,
            PHP_DEBUGLINE_PAGEACTION  => false,
            PHP_DEBUGLINE_SQLPARSE    => false,
            PHP_DEBUGLINE_WATCH       => false,
            PHP_DEBUGLINE_PHPERROR    => false
        );    

        /**
         * After this goes all HTML related variables
         * 
         * 
         * HTML code for header 
         */         
         self::$options['HTML_TABLE_header'] = '
<div id="pd-div">
<br />
<a name="pd-anchor" id="pd-anchor" />
<table class="pd-table" cellspacing="0" cellpadding="0" width="100%">
  <tr>
    <td class="pd-table-header" align="center">File</td>
    <td class="pd-table-header" align="center">Line</td>
    <td class="pd-table-header" align="center">Inside/From function</td>
    <td class="pd-table-header" align="center">Inside/From Class</td>  
    <td class="pd-table-header" align="center">Type</td>  
    <td class="pd-table-header" align="center">Debug information</td>
    <td class="pd-table-header" align="center">Execution time (sec)</td>
  </tr>
        ';

        /**
         * HTML code for footer 
         */         
         self::$options['HTML_TABLE_credits'] = '
        PHP_Debug ['. PHP_DEBUG_RELEASE .'] | By COil (2007) &amp; The CRIMP Team (2007) | 
        <a href="http://www.coilblog.com">http://www.coilblog.com</a> | 
        <a href="http://phpdebug.sourceforge.net/">PHP_Debug Project Home</a> 
        ';

        /**
         * HTML code for a basic header 
         */         
         self::$options['HTML_TABLE_simple_header'] = '<?xml version="1.0" encoding="UTF-8"?>
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
         self::$options['HTML_TABLE_simple_footer'] = '
</body>
</html>
';

        /**
         * HTML pre-row code for debug column file 
         */         
         self::$options['HTML_TABLE_prerow'] = '
  <tr>';

        /**
         * HTML pre-row code for debug column file 
         */         
         self::$options['HTML_TABLE_interrow_file'] = '
    <td class="pd-td" align="center">';

        /**
         * HTML post-row code for debug column line (centered)
         */         
        self::$options['HTML_TABLE_interrow_line'] = '
    </td>
    <td class="pd-td" align="center">';

        self::$options['HTML_TABLE_interrow_function'] = self::$options['HTML_TABLE_interrow_line']; 
        self::$options['HTML_TABLE_interrow_class']    = self::$options['HTML_TABLE_interrow_line']; 
        self::$options['HTML_TABLE_interrow_type']     = self::$options['HTML_TABLE_interrow_line']; 
        self::$options['HTML_TABLE_interrow_time']     = self::$options['HTML_TABLE_interrow_line']; 

        /**
         * HTML pre-row code for debug column info
         */         
        self::$options['HTML_TABLE_interrow_info'] = '
    </td>
    <td class="pd-td" align="left">';


        /**
         * HTML post-row code for debugline 
         */         
         self::$options['HTML_TABLE_postrow'] = '
    </td>
  </tr>
';

        /**
         * HTML code for footer 
         */         
         self::$options['HTML_TABLE_footer'] = '
</table>
</div>
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
     * HTML_Table_Config
     * 
     * @since V2.0.0 - 26 Apr 2006
     */
    function __tostring()
    {
        return '<pre>'. PHP_Debug::dumpVar($this->singleton()->getConfig(), __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '</pre>';
    }   
}

?>
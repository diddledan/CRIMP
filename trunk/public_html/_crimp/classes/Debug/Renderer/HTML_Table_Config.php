<?php

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

class Debug_Renderer_HTML_Table_Config
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
        self::$options['HTML_TABLE_show_templates'] = false;
        
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
        self::$options['HTML_TABLE_view_source_script_name'] = /*'source.php'*/''; 

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
    <td class="pd-table-header" align="center" valign="bottom">Type</td>
    <td class="pd-table-header" align="center">Debug information</td>
    <td class="pd-table-header" align="center">Execution time (sec)</td>
  </tr>
        ';

        /**
         * HTML code for footer 
         */         
         self::$options['HTML_TABLE_credits'] = '
        PHP_Debug ['. PHP_DEBUG_RELEASE .'] | By COil (2006) | 
        <a href="mailto:qrf_coil@yahoo.fr">qrf_coil@yahoo.fr</a> | 
        <a href="http://phpdebug.sourceforge.net/">PHP_Debug Project Home</a> |
        Adapted for CRIMP by The CRIMP Team (crimp.sf.net)
        ';

         /**
         * PHP_Debug style sheet
         */         
         self::$options['HTML_TABLE_stylesheet'] = '
    <style type="text/css">
    /* Main table */
    .pd-table {
      border: solid 1px Navy;
      border-bottom: 0px;
      border-right: 0px;
    }
    /* Table header */
    .pd-table-header {
      font-family: tahoma, arial, sans-serif;
      font-size: 0.8em;
      font-weight: bold;
      color: white;
      background-color: Navy;
      border-bottom: solid 1px Navy;
    }
    /* 1- Generic TD cell */
    .pd-td {
      font-family: tahoma, arial, sans-serif;
      font-size: 0.8em;
      color: black;
      background-color: white;
      padding: 2px;
      border-bottom: solid 1px Navy;
      border-right: solid 1px Navy;
    }
    /* 2, 3 - Query cell */
    .pd-query {
      font-weight: bold;
      color: orange;
    }
    /* 5 - Application error */
    .pd-app-error {
      background-color: orange;
      color: white;
      font-weight: bold;
    }
    /* 6 - Credits */
    .pd-credits { 
      font-family: tahoma, arial, sans-serif;
      font-size: 0.9em;
      color: navy;
      font-weight: bold;
    }
    /* 7 - Search cell */
    .pd-search {
      font-family: tahoma, arial, sans-serif;
      font-size: 0.8em;
      font-weight: bold;
    }
    /* Highligthed search keyword */
    .pd-search-hl {
      background-color: yellow;
      color: blue;
    }
    /* 8 - Dump */
    .pd-dump-title {
      color: blue;
    }
    .pd-dump-val {
      color: black;
      border: solid 1px blue;
    }
    /* 9 - Perf summary */
    .pd-perf {
      font-size: 0.8em;
      color: white;
      font-weight: bold;
      background-color: blue;
    }
    .pd-perf-table {
      border: solid 1px blue;
    }
    .pd-time {
      color: navy;
      font-weight: bold;
    }
    /* 10 - Templates */
    .pd-files {
      color: blue;
    }
    .pd-main-file {
      background-color: LightSteelBlue;
      color: white;
      font-weight: bold;
    }
    /* 11 - Page action */
    .pd-pageaction {
      background-color: LightSteelBlue;
      color: white;
      font-weight: bold;
    }
    /* 13 - Watch cell */
    .pd-watch {
      font-style: oblique; 
      font-weight: bold;
    }
    .pd-watch-val {
      font-weight: bold;
      border: solid 1px Navy;
    }
    /* 14 - Php errors */
    .pd-php-warning {
      background-color: red;
      color: white;
      font-weight: bold;
    }
    .pd-php-notice {
      background-color: yellow;
      color: navy;
      font-weight: bold;
    }
    .pd-php-user-error {
      background-color: orange;
      color: white;
      font-weight: bold;
    }
    </style>
';

         /**
         * View source style sheet
         */         
         self::$options['HTML_TABLE_view_source_stylesheet'] = '
    <style type="text/css">
    .hl-default {
      color: Black;
    }
    .hl-code {
      color: Gray;
    }
    .hl-brackets {
      color: Olive;
    }
    .hl-comment {
      color: Orange;
    }
    .hl-quotes {
      color: Darkred;
    }
    .hl-string {
      color: Red;
    }
    .hl-identifier {
      color: Blue;
    }
    .hl-builtin {
      color: Teal;
    }
    .hl-reserved {
      color: Green;
    }
    .hl-inlinedoc {
      color: Blue;
    }
    .hl-var {
      color: Darkblue;
    }
    .hl-url {
      color: Blue;
    }
    .hl-special {
      color: Navy;
    }
    .hl-number {
      color: Maroon;
    }
    .hl-inlinetags {
      color: Blue;
    }
    .hl-main { 
      background-color: #F5F5F5;
    }
    .hl-gutter {
      background-color: #999999;
      color: White
    }
    .hl-table {
      font-family: courier;
      font-size: 14px;
      border: solid 1px Lightgrey;
    }
    .hl-title {    
      font-family: Tahoma;
      font-size: 22px;
      border: solid 1px Lightgrey;
      background-color: #F0F0F0;
      margin-left: 15px;
      padding-left: 5px;
      padding-right: 5px;
    }
    </style>
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
        return '<pre>'. Debug::dumpVar($this->singleton()->getConfig(), __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '</pre>';
    }   
}

?>
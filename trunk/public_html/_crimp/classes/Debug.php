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
 * Revision info: $Id: Debug.php,v 1.6 2007-04-29 20:37:32 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 * 
 *---
 * 
 * @category   PHP
 * @package    PHP_Debug
 * @author     Vernet Loïc <qrf_coil[at]yahoo.fr>
 * @copyright  1997-2005 The PHP Group
 * @license    http://www.php.net/license/3_0.txt  PHP License 3.0
 * @link       http://pear.php.net/package/PHP_Debug
 * @link       http://phpdebug.sourceforge.net
 * @link       http://www.php-debug.com
 * @see        Var_Dump, Text_Highlighter, SQL_Parser
 * @since      1.0.0
 * @version    CVS: $Id: Debug.php,v 1.6 2007-04-29 20:37:32 diddledan Exp $
 */

/**
 * External constants
 * 
 * @filesource
 * @package PHP_Debug
 */
if (!defined('STR_N')) {
    define('STR_N', "");
}

if (!defined('CR')) { 
    define('CR', "\n");
}

/**
 * Factory class for renderer of Debug class
 * 
 * @see Debug/Renderer/*.php
 */
require_once 'Debug/Renderer.php';


/**
 * Possible version of class Debug
 */ 
define('PHP_DEBUG_VERSION_STANDALONE', 0);
define('PHP_DEBUG_VERSION_PEAR',       1);
define('PHP_DEBUG_VERSION_DEFAULT',    PHP_DEBUG_VERSION_STANDALONE);
define('PHP_DEBUG_VERSION',            PHP_DEBUG_VERSION_STANDALONE);
define('PHP_DEBUG_RELEASE',            'V2.1.0-CRIMP');



/**
 * These are constant for dump() and DumpObj() functions.
 * 
 * - PHP_DEBUG_DUMP_DISP : Tell the function to display the debug info.
 * - PHP_DEBUG_DUMP_STR  : Tell the function to return the debug info as a
 * string 
 * - PHP_DEBUG_DUMP_VARNAME : Default name of Array - DBG_ARR_OBJNAME : Default
 * name of Object
 */
define('PHP_DEBUG_DUMP_DISP',    1);
define('PHP_DEBUG_DUMP_STR',     2);
define('PHP_DEBUG_DUMP_VARNAME', 'Variable');

/**
 * These are constants to define Super array environment variables
 */ 
define('PHP_DEBUG_GLOBAL_GET',     0);
define('PHP_DEBUG_GLOBAL_POST',    1);
define('PHP_DEBUG_GLOBAL_FILES',   2);
define('PHP_DEBUG_GLOBAL_COOKIE',  3);
define('PHP_DEBUG_GLOBAL_REQUEST', 4);
define('PHP_DEBUG_GLOBAL_SESSION', 5);
define('PHP_DEBUG_GLOBAL_GLOBALS', 6);

/**
 * These are constant for addDebug functions, they set the behaviour where
 * the function should add the debug information in first or in last position
 */
define('PHP_DEBUG_POSITIONLAST',  0);
define('PHP_DEBUG_POSITIONFIRST', 1);


class PHP_Debug
{
    /**
     * Default configuration options
     * 
     * @since V2.0.0 - 16 apr 2006
     * @see setOptions()
     * @var array
     */
    protected $defaultOptions = array(
        'DEBUG_render_mode'          => 'HTML_Div',        // Render mode
        'DEBUG_restrict_access'      => false,             // Restrict or not the access
        'DEBUG_allowed_ip'           => array('127.0.0.1'),// Authorized IP to view the debug when restrcit_access is true
        'DEBUG_allow_url_access'     => false,             // Allow to access the debug with a special parameter in the url
        'DEBUG_url_key'              => 'debug',           // Key for url instant access
        'DEBUG_url_pass'             => 'true',            // Password for url instant access
        'DEBUG_enable_watch'         => false,             // Enable the watch function
        'DEBUG_replace_errorhandler' => true,              // Replace or no the PHP errorhandler
        'DEBUG_lang'                 => 'EN'               // Language
    );

    /**
     * Default static options for static functions
     *
     * @since V2.0.0 - 16 apr 2006
     * @see dump()
     * @var array
     */
    static $staticOptions = array(
        'DEBUG_dump_method'          => 'print_r',          // print_r or var_dump
        'DEBUG_pear_var_dump_method' => 'Var_Dump::display' // Var_Dump display funtion 
    );

    /**
     * Functions from this class that must be excluded in order to have the
     * correct backtrace information
     *
     * @see PHP_Debug_Line::setTraceback()
     * @since V2.0.0 - 13 apr 2006
     * @var array
     */
    static $excludedBackTraceFunctions = array(
        'add', 
        'dump', 
        'error', 
        'query', 
        'addDebug', 
        'setAction', 
        'addDebugFirst',
        'watchesCallback',
        'errorHandlerCallback'
    );

    /**
     * Correspondance between super array constant and variable name
     * Used by renderers
     *
     * @since V2.0.0 - 18 apr 2006
     * @var array
     */
    static $globalEnvConstantsCorresp = array(  
        PHP_DEBUG_GLOBAL_GET    => '_GET',
        PHP_DEBUG_GLOBAL_POST   => '_POST',
        PHP_DEBUG_GLOBAL_FILES  => '_FILES',
        PHP_DEBUG_GLOBAL_COOKIE => '_COOKIE',
        PHP_DEBUG_GLOBAL_REQUEST=> '_REQUEST',
        PHP_DEBUG_GLOBAL_SESSION=> '_SESSION',
        PHP_DEBUG_GLOBAL_GLOBALS=> 'GLOBALS'
    );

    /**
     * Default configuration options
     *
     * @since V2.0.0 - 13 apr 2006
     * @see setOptions() 
     * @var array
     */
    protected $options = array();

    /**
     * This is the array where the debug lines are collected.
     *
     * @since V2.0.0 - 11 apr 2006
     * @see Debug_Line
     * @var array
     */
    protected  $debugLineBuffer = array();
    
    /**
     * This is the array containing all the required/included files of the 
     * script
     *
     * @since V2.0.0 - 17 apr 2006
     * @see render(), PHP_DEBUGLINE_TEMPLATES
     * @var array
     */    
    protected $requiredFiles = array();

    /**
     * This is the array containing all the watched variables
     *
     * @since V2.0.0 - 16 apr 2006
     * @see watch()
     * @var array
     */    
    protected $watches = array();
    
    /** 
     * Execution start time
     * 
     * @since V2.0.0 - 11 apr 2006
     * @see __construct()
     * @var float          
     */
    private $startTime;
        
    /** 
     * Exection end time
     * 
     * @since V2.0.0 - 11 apr 2006
     * @see render()
     * @var float
     */
    private $endTime;
    
    /** 
     * Number of queries executed during script 
     * 
     * @since V2.0.0 - 19 apr 2006
     * @var integer          
     */
    private $queryCount = 0;

    /**
     * PHP_Debug class constructor
     * 
     * Here we set :
     * - the execution start time
     * - the options
     * - the error and watch call back functions
     * 
     * @param array $options    Array containing options to affect to Debug 
     *                          object and his childs
     * 
     * @since V2.0.0 - 11 apr 2006
     */
    function __construct($options = array())
    {
        $this->startTime = PHP_Debug::getMicroTimeNow();
        $this->options = array_merge($this->defaultOptions, $options);
        $this->setWatchCallback();
        $this->setErrorHandler();
    }

    /**
     * Add a debug information
     *
     * @param string  $info  The main debug information 
     *                      (may be empty for some debug line types)
     * @param integer $type Type of the Debug_Line
     * 
     * @see Debug constants
     * @since 07 Apr 2006 
     */     
    public function addDebug($info, $type = PHP_DEBUGLINE_STD, $position = PHP_DEBUG_POSITIONLAST)
    {    	
        // Add info
        if ($position == PHP_DEBUG_POSITIONLAST) {        
            $this->debugLineBuffer[] = new PHP_Debug_Line($info, $type);
        } else {
            array_unshift($this->debugLineBuffer, new PHP_Debug_Line($info, $type));
        }
        
        // Additional process for some types
        switch ($type) {
			case PHP_DEBUGLINE_QUERY:
                $this->queryCount++;
				break;
		
			default:
				break;
		}
    }

    /**
     * Add a debug info before all the existing other debug lines
     * It is an alias for addDebug($info, PHP_DEBUG_POSITIONLAST)
     * 
     * @see addDebug
     * @since 13 Apr 2006 
     */
    public function addDebugFirst($info, $type = PHP_DEBUGLINE_STD)
    {
        $this->addDebug($info, $type, PHP_DEBUG_POSITIONFIRST);
    }

    /**
     * This is an alias for the addDebug function
     *
     * @see addDebug()
     * @since  V2.0.0 - 20 apr 2006
     */
    public function add($info, $type = PHP_DEBUGLINE_STD)
    {
        $this->addDebug($info, $type);
    }

    /**
     * This is an alias for the addDebug function when wanting to add a query
     * debug information
     * 
     * @see addDebug(), PHP_DEBUGLINE_QUERY
     * @since V2.0.0 - 21 Apr 2006
     */
    public function query($qry)
    {
        $this->addDebug($qry, PHP_DEBUGLINE_QUERY);
    }

    /**
     * This is an alias for the addDebug function when wanting to add a
     * database related debug info
     * 
     * @see addDebug(), PHP_DEBUGLINE_QUERYREL
     * @since V2.1.0 - 3 apr 2007
     */
    public function queryRel($info)
    {
        $this->addDebug($info, PHP_DEBUGLINE_QUERYREL);
    }

    /**
     * This is an alias for the addDebug function when wanting to add an
     * application error
     * 
     * @see addDebug(), PHP_DEBUGLINE_APPERROR
     * @since V2.0.0 - 21 Apr 2006
     */
    public function error($info)
    {
        $this->addDebug($info, PHP_DEBUGLINE_APPERROR);
    }

    /**
     * This is an alias for adding the monitoring of processtime
     * 
     * @see addDebug(), PHP_DEBUGLINE_PROCESSPERF
     * @since V2.1.0 - 21 Apr 2006
     */
    public function addProcessPerf()
    {
        $this->addDebug(STR_N, PHP_DEBUGLINE_PROCESSPERF);
    }

    /**
     * Set the callback fucntion to process the watches, enabled depending of 
     * the options flag 'DEBUG_enable_watch' 
     * 
     * @since V2.0.0 - 16 apr 2006
     * @see options, watches, watchesCallback()
     */
    private function setWatchCallback()
    {
        if ($this->options['DEBUG_enable_watch'] == true) {
            if (count($this->watches) === 0) {
                $watchMethod = array($this, 'watchesCallback');
                register_tick_function($watchMethod);
            }
        }
    }

    /**
     * Set the callback function to process replace the php error handler, 
     * enabled depending of the options flag 'DEBUG_replace_errorhandler'
     * 
     * @since V2.0.0 - 16 apr 2006
     * @see options, errorHandlerCallback()
     */
    private function setErrorHandler()
    {
        if ($this->options['DEBUG_replace_errorhandler'] == true) {

            $errorhandler = array(
                $this,
                'errorHandlerCallback'
            );
            set_error_handler($errorhandler);
        }
    }

    /**
     * Callback function for php error handling
     * 
     * Warning : the only PHP error codes that are processed by this user
     * handler are : E_WARNING, E_NOTICE, E_USER_ERROR
     * For the other error codes the standart php handler will be used  
     *
     * @since V2.0.0 - 17 apr 2006
     * @see options, setErrorHandler()
     */
    public function errorHandlerCallback() 
    {
        $details = func_get_args();
        $popNumber = 3;

        // We already have line & file with setBackTrace function
        for ($index = 0; $index < $popNumber; $index++) {
		  array_pop($details);	
		}
        
        if ($details[0] != E_STRICT)                            
            $this->addDebug($details, PHP_DEBUGLINE_PHPERROR);
    }

    /**
	 * Add a variable to the watchlist. Watched variables must be in a declare
	 * (ticks=n) block so that every n ticks the watched variables are checked
	 * for changes. If any changes were made, the new value of the variable is
	 * recorded
     * 
     * @param string $variableName      Variable to watch
     * @since V2.0.0 - 17 apr 2006
     * @see watchesCallback()
     */
    public function watch($variableName) 
    {   
        if ($this->options['DEBUG_enable_watch'] == true) {
            if (isset($GLOBALS[$variableName])) {
                $this->watches[$variableName] = $GLOBALS[$variableName];
            } else {
                $this->watches[$variableName] = null;
            }
        } else {
            print('<p><br />The <b>Watch()</b> function is disabled please set the option "DEBUG_enable_watch" to "true" to be able to use this feature<br /></p>');
        }
    }

    /**
     * Watch callback function, process watches and add changes to the debug 
     * information
     * 
     * @since V2.0.0 - 17 apr 2006
     * @see watch()
	 */
    public function watchesCallback() 
    {
        // Check if there are variables to watch
        if (count($this->watches)) {
            foreach ($this->watches as $variableName => $variableValue) {
                if ($GLOBALS[$variableName] !== $this->watches[$variableName]) {

                    $info = array(
                        $variableName,
                        $this->watches[$variableName],
                        $GLOBALS[$variableName]
                    );
                                        
                    $this->watches[$variableName] = $GLOBALS[$variableName];
                    $this->addDebug($info, PHP_DEBUGLINE_WATCH);
                }
            }
        }
    }

    /**
     * Get global process time
     * 
     * @return  float     		Execution process time of the script
     * 
     * @see getElapsedTime()
     * @since V2.0.0 - 21 Apr 2006
     */ 
    public function getProcessTime()
    {
        return ($this->getElapsedTime($this->startTime, $this->endTime));
    }

    /**
     * Get database related process time
     * 
     * @return  float      Execection process time of the script for all
     * 					   database	specific tasks
     * 
     * @see PHP_DEBUGLINE_QUERY, PHP_DEBUGLINE_QUERYREL
     * @since V2.0.0 - 21 Apr 2006
     */ 
    public function getQueryTime()
    {
    	$queryTime = 0;        
        
        foreach($this->debugLineBuffer as $lkey => $lvalue)  {
            $properties = $lvalue->getProperties();
        	if ($properties['type'] == PHP_DEBUGLINE_QUERY OR $properties['type'] == PHP_DEBUGLINE_QUERYREL) {
                if (!empty($properties['endTime'])) {
                	$queryTime = $queryTime + $this->getElapsedTime($properties['startTime'], $properties['endTime']);
                }
            }
        }
        return $queryTime;
    }

    /**
     * PHP_Debug default output function, first we finish the processes and
     * then a render object is created and its render method is invoked
     * 
     * The renderer used is set with the options, all the possible renderer
     * are in the directory Debug/Renderer/*.php
     * (not the files ending by '_Config.php')
     * 
     * @since V2.0.0 - 13 apr 2006
     * @see Debug_Renderer
     */
    public function render()
    {
        // Finish process
        $this->endTime = PHP_Debug::getMicroTime(microtime());

        // Render output if we are allowed to
        if ($this->isAllowed()) {

            // Create render object and invoke its render function
            $renderer = PHP_Debug_Renderer::factory($this, $this->options);
    
            // Get required files here to have event all Debug classes
            $this->requiredFiles = get_required_files();
    
            // Call rendering
            $renderer->render();
        }
    }

    /**
     * Alias for the render function
     * 
     * @since V2.0.0 - 17 apr 2006
     * @see render()
     */
    public function display()
    {
        $this->render();
    }
    
    /**
     * Return the display 
     * 
     * @since V2.0.1 - 17 apr 2006
     * @see render()
     */
    public function getDisplay()
    {
        ob_start();
        $this->render();
        $dbgBuffer = ob_get_contents();
        ob_end_clean();
        return $dbgBuffer;
    }
    

    /**
     * Restrict access to a list of IP
     * 
     * @param array $ip     Array with IP to allow access
     * @since 11 Apr 2006
     * @see $options, isAllowed()
     */ 
    function restrictAccess($ip)
    {
        $this->options['DEBUG_allowed_ip'] = $ip;
    }

    /**
     * Test if the client is allowed to access the debug information
     * There are several possibilities : 
     * - 'DEBUG_restrict_access' flag is set to false
     * - 'DEBUG_restrict_access' flag is set to true and client IP is the
     * allowed ip in the options 'DEBUG_allowed_ip'
     * - Access by url is allowed with flag 'DEBUG_allow_url_access' then 
     * the client must enter the good key and password in the url
     * 
     * @since V2.0.0 - 20 apr 2006
     * @see $options, restrictAcess()
     */ 
    private function isAllowed()
    {
        if ($this->options['DEBUG_restrict_access'] == true) {

            // Check if client IP is among the allowed ones
            if (in_array($_SERVER['REMOTE_ADDR'], $this->options['DEBUG_allowed_ip'])) {
                return true;
            }
            // Check if instant access is allowed and test key and password
            elseif ($this->options['DEBUG_allow_url_access'] == true) {
                
                $key = $this->options['DEBUG_url_key'];
                
                if (!empty($_GET[$key])) {
                    if ($_GET[$key] == $this->options['DEBUG_url_pass']) {
                        return true;
                    } else {
                        return false;                        
                    }
                }
                else {
                    return false;
                }                
            } else {
                return false;
            }
        } else {
            // Access is not restricted
            return true;
        }
    }

    /**
     * Return microtime from a timestamp
     *   
     * @param $time     Timestamp to retrieve micro time
     * @return numeric  Microtime of timestamp param
     * 
     * @since V1.1.0 - 14 Nov 2003
     * @see $DebugMode
     */ 
    static function getMicroTime($time)
    {   
        list($usec, $sec) = explode(' ', $time);
        return ((float)$usec + (float)$sec);
    }

    /**
     * Alias for getMicroTime(microtime()
     *   
     * @see getMicroTime()
     * @since V2.0.0 - 19 apr 2006
     */ 
    static function getMicroTimeNow()
    {   
        return PHP_Debug::getMicroTime(microtime()); 
    }

    /**
     * Get elapsed time between 2 timestamp
     *   
     * @param   float $timeStart    Start time
     * @param   float $timeEnd      End time
     * @return  float               Numeric difference between the two times 
     *                              ref in format 00.0000 sec
     * 
     * @see getMicroTime()
     * @since 20 Oct 2003
     */ 
    static function getElapsedTime($timeStart, $timeEnd)
    {           
        return round($timeEnd - $timeStart, 4);
    }

    /**
     * Set the endtime for a Debug_Line in order to monitor the performance
     * of a part of script
     *   
     * @see PHP_Debug_Line::endTime
     * @since V2.0.0 - 19 apr 2006
     */ 
    public function stopTimer()
    {
        $this->debugLineBuffer[count($this->debugLineBuffer)-1]->setEndTime(PHP_Debug::getMicroTimeNow());
    }

    /**
     * Display the content of any kind of variable
     * 
     * - Mode PHP_DEBUG_DUMP_ARR_DISP display the array
     * - Mode PHP_DEBUG_DUMP_ARR_STR return the infos as a string
     * 
     * @param   mixed       $var        Variable to dump 
     * @param   string      $varname    Name of the variable
     * @param   integer     $mode       Mode of function
     * @param   boolean     $stopExec   Stop the process after display of debug
     * @return  mixed                   Nothing or string depending on the mode
     * 
     * @todo I don't know if it is a good practice to have static properties
     * for static functions, to check
     * 
     * @since V2.0.0 - 25 Apr 2006
     */ 
    static function dumpVar($var, $varName = PHP_DEBUG_DUMP_VARNAME, $stopExec = false, $mode = PHP_DEBUG_DUMP_DISP)
    {
        // Check Pear Activation
        if (PHP_DEBUG_VERSION == PHP_DEBUG_VERSION_PEAR) 
            $dumpMethod = self::$staticOptions['DEBUG_pear_var_dump_method'];
        else
            $dumpMethod = self::$staticOptions['DEBUG_dump_method'];

        ob_start();
        $dumpMethod($var);
        $dbgBuffer = htmlentities(ob_get_contents());
        ob_end_clean();
        
        switch ($mode) {
            default:
            case PHP_DEBUG_DUMP_DISP:

                if (empty($varName)) {
                    if (is_array($var)) {
                        $varName = 'Array';
                    } elseif (is_object($var)) {
                        $varName = get_class($var);
                    } else {
                        $varName = 'Variable';                              
                    }
                }
            
                $dbgBuffer = "<pre><b>dump of '$varName'</b> :". CR. $dbgBuffer. '</pre>';
                print($dbgBuffer);
                break;
                
            case PHP_DEBUG_DUMP_STR:
                return($dbgBuffer);
        }        

        // Check process stop
        if ($stopExec) {
            die('<b>&raquo; Process stopped by PHP_Debug</b>');
        }

    }

   /**
     * This a method to dump the content of any variable and add the result in
     * the debug information
     * 
     * @param   mixed       $var        Variable to dump 
     * @param   string      $varname    Name of the variable
     * 
     * @since V2.0.0 - 25 Apr 2006
     */  
    public function dump($obj, $varName = STR_N)
    {
        $info[] = $varName;
        $info[] = $obj;
        $this->addDebug($info, PHP_DEBUGLINE_DUMP);
    }

    /**
     * Set the main action of PHP script
     * 
     * @param string $action Name of the main action of the file
     * 
     * @since V2.0.0 - 25 Apr 2006
     * @see PHP_DEBUGLINE_CURRENTFILE
     */  
    public function setAction($action)    
    {
        $this->add($action, PHP_DEBUGLINE_PAGEACTION);
    }

    /**
     * Add an application setting
     * 
     * @param string $action Name of the main action of the file
     * 
     * @since V2.1.0 - 02 Apr 2007
     * @see PHP_DEBUGLINE_ENV
     */  
    public function addSetting($value, $name)
    {
        $this->add($name. ': '. $value, PHP_DEBUGLINE_ENV);
    }

    /**
     * Add a group of settings
     * 
     * @param string $action Name of the main action of the file
     * 
     * @since V2.1.0 - 2 Apr 2007
     * @see PHP_DEBUGLINE_ENV
     */  
    public function addSettings($values, $name)
    {
        $this->add($name. ': '. PHP_Debug::dumpVar($values, $name, false, PHP_DEBUG_DUMP_STR), PHP_DEBUGLINE_ENV);
    }

    /**
     * Get one option
     *
     * @param string $optionsIdx Name of the option to get
     * @since V2.0.0 - 13 apr 2006
     */
    public function getOption($optionIdx)
    {
        return $this->options[$optionIdx];
    }

    /**
     * Return the style sheet of the HTML_TABLE debug object
     * 
     * @return string The stylesheet
     */    
    public function getStyleSheet()
    {
        return $this->options['HTML_TABLE_stylesheet'];
    }

    /**
     * Getter of requiredFiles property
     * 
     * @return array Array with the included/required files
     * @since V2.0.0 - 13 apr 2006
     * @see requiredFiles
     */
    public function getRequiredFiles()
    {
        return $this->requiredFiles;
    }

    /**
     * Getter of debugString property
     * 
     * @since V2.0.0 - 13 apr 2006
     * @see debugLineBuffer
     */
    public function getDebugBuffer()
    {
        return $this->debugLineBuffer;           
    }

    /**
     * Getter of queryCount property
     * 
     * @since @since V2.0.0 - 21 Apr 2006
     * @see queryCount
     */
    public function getQueryCount()
    {
        return $this->queryCount;           
    }

    /**
     * Debug default output function, simply uses the static dump fonction
     * of this class 
     * 
     * @since V2.0.0 - 11 apr 2006
     * @see dump
     */
    public function __tostring()
    {
        return '<pre>'. PHP_Debug::dumpVar($this, __CLASS__. ' class instance', PHP_DEBUG_DUMP_STR). '</pre>';  
    }

    /**
     * Debug class destructor
     * 
     * @since V2.0.0 - 11 apr 2006
     */     
    function __destruct()
    {        
    }
} 

// {{{ constants

/**
 * PHP_DEBUGLINE Types
 *
 * - PHP_DEBUGLINE_ANY          : All available types (for search mode)
 * - PHP_DEBUGLINE_STD          : Standart debug
 * - PHP_DEBUGLINE_QUERY        : Query debug
 * - PHP_DEBUGLINE_REL          : Database related debug
 * - PHP_DEBUGLINE_ENV          : Environment debug ($GLOBALS...)
 * - PHP_DEBUGLINE_APPERROR     : Custom application error 
 * - PHP_DEBUGLINE_CREDITS      : Credits information 
 * - PHP_DEBUGLINE_SEARCH       : Search mode in debug 
 * - PHP_DEBUGLINE_DUMP         : Dump any kind of variable 
 * - PHP_DEBUGLINE_PROCESSPERF  : Performance analysys 
 * - PHP_DEBUGLINE_TEMPLATES    : Included templates of the calling script 
 * - PHP_DEBUGLINE_PAGEACTION   : Store main page action 
 * - PHP_DEBUGLINE_SQLPARSE     : SQL Parse error 
 * - PHP_DEBUGLINE_WATCH        : A variable to watch 
 * - PHP_DEBUGLINE_PHPERROR     : A debug generated by the custom error handler
 *
 * @todo Currentfile is deprecated, numbers to resequence 
 * @category Debug_Line
 */
define('PHP_DEBUGLINE_ANY',         0);
define('PHP_DEBUGLINE_STD',         1);
define('PHP_DEBUGLINE_QUERY',       2);
define('PHP_DEBUGLINE_QUERYREL',    3);
define('PHP_DEBUGLINE_ENV',         4);
define('PHP_DEBUGLINE_APPERROR',    5);
define('PHP_DEBUGLINE_CREDITS',     6);
define('PHP_DEBUGLINE_SEARCH',      7);
define('PHP_DEBUGLINE_DUMP',        8);
define('PHP_DEBUGLINE_PROCESSPERF', 9);
define('PHP_DEBUGLINE_TEMPLATES',   10);
define('PHP_DEBUGLINE_PAGEACTION',  11);
define('PHP_DEBUGLINE_SQLPARSE',    12);
define('PHP_DEBUGLINE_WATCH',       13);
define('PHP_DEBUGLINE_PHPERROR',    14);
define('PHP_DEBUGLINE_DEFAULT',     PHP_DEBUGLINE_STD);
/**
 * CRIMP Modification:
 * PHP_DEBUGLINE_PASS = messages that are logged to indicate success
 * PHP_DEBUGLINE_WARN = messages that provide a warning but aren't fatal
 * PHP_DEBUGLINE_FAIL = PHP_DEBUGLINE_APPERROR = fatal errors
 */
define('PHP_DEBUGLINE_PASS',        15);
define('PHP_DEBUGLINE_WARN',        16);
define('PHP_DEBUGLINE_FAIL',        PHP_DEBUGLINE_APPERROR);

/**
 * PHP_DEBUGLINE info levels
 */
define('PHP_DEBUGLINE_INFO_LEVEL',    1);
define('PHP_DEBUGLINE_WARNING_LEVEL', 2);
define('PHP_DEBUGLINE_ERROR_LEVEL',   3);

// }}}


class PHP_Debug_Line
{
	
   /** 
  	* Labels for debugline types
  	*/
    static $debugLineLabels = array(
        PHP_DEBUGLINE_ANY         => 'ALL', 
        PHP_DEBUGLINE_STD         => '[<span class="crimpDebugInfo">INFO</span>]',
        PHP_DEBUGLINE_QUERY       => 'Query', 
        PHP_DEBUGLINE_QUERYREL    => 'Database related',
        PHP_DEBUGLINE_ENV         => 'Environment',
        PHP_DEBUGLINE_APPERROR    => '[<span class="crimpDebugFail">CRITICAL</span>]',
        PHP_DEBUGLINE_CREDITS     => 'Credits',
        PHP_DEBUGLINE_SEARCH      => 'Search',
        PHP_DEBUGLINE_DUMP        => 'Variable dump',
        PHP_DEBUGLINE_PROCESSPERF => 'Performance analysis',
        PHP_DEBUGLINE_TEMPLATES   => 'Included files',
        PHP_DEBUGLINE_PAGEACTION  => 'Page main action',
        PHP_DEBUGLINE_SQLPARSE    => 'SQL parse error',
        PHP_DEBUGLINE_WATCH       => 'Watch',
        PHP_DEBUGLINE_PHPERROR    => '[<span class="crimpDebugPHP">PHP</span>]',
        PHP_DEBUGLINE_PASS        => '[<span class="crimpDebugPass">PASS</span>]',
        PHP_DEBUGLINE_WARN        => '[<span class="crmipDebugWarn">WARNING</span>]',
        PHP_DEBUGLINE_FAIL        => '[<span class="crimpDebugFail">FAIL</span>]'
    );

    /**
     * Properties that stores the non formatted debug information
     * 
     * @since V2.0.0 - 11 apr 2006
     * @var string          
     */     
    private $info;
    
    /**
     * Type of the debug information
     * 
     * @since V2.0.0 - 11 apr 2006
     * @see Debug_Line constants 
     * @var integer          
     */     
    private $type;

    /** 
     * File of debug info
     * 
     * @since V2.0.0 - 11 apr 2006
     * @var integer          
     */
    private $file;

    /** 
     * Line of debug info
     * 
     * @since V2.0.0 - 11 apr 2006
     * @var integer          
     */
    private $line;
        
    /** 
     * Class from witch the debug was called
     * 
     * @since V2.0.0 - 13 apr 2006
     * @var integer          
     */
    private $class;

    /** 
     * Function from wich the debug was called
     * 
     * @var integer          
     * @since V2.0.0 - 11 apr 2006
     */
    private $function;
    
    /** 
     * Exection time for debug info
     * 
     * @var float          
     * @see stopTimer()          
     * @since V2.0.0 - 16 apr 2006
     */
    private $startTime;

    /** 
     * Exection end time for debug info
     * 
     * @see PHP_Debug::stopTimer(), setEndTime()
     * @since V2.0.0 - 16 apr 2006
     * @var float
     */
    private $endTime;

    /**
     * PHP_DebugLine class constructor
     * 
     * Here it is set :
     * - the start time of the debug info
     * - the traceback information
     *
     * @since V2.0.0 - 11 apr 2006
     * @see PHP_Debug::add()
     */
    function __construct($info, $type = PHP_DEBUGLINE_DEFAULT)
    {
        $this->startTime = PHP_Debug::getMicroTimeNow();
        $this->info = $info;
        $this->type = $type;
        $this->setTraceback();
    }

    /**
     * Fills properties of debug line with backtrace informations
     * 
     * @since @since V2.0.0 - 15 apr 2006
     */
    protected function setTraceback()
    {
        $callStack = debug_backtrace();
        $idx = 0;
        
        // Get max id of 'add' debug functions  
        foreach($callStack as $lkey => $lvalue) {
            if (in_array($callStack[$lkey]['function'], PHP_Debug::$excludedBackTraceFunctions) == true) {
                $idx = $lkey;
            }
        }

        $this->file     = !empty($callStack[$idx]  ['file'])     ? $callStack[$idx]['file']       : '';
        $this->line     = !empty($callStack[$idx]  ['line'])     ? $callStack[$idx]['line']       : '';
        $this->function = !empty($callStack[$idx+1]['function']) ? $callStack[$idx+1]['function'] : '';
        $this->class    = !empty($callStack[$idx+1]['class'])    ? $callStack[$idx+1]['class']    : '';
    }

    /**
     * Getter of all properties of Debug_Line object
     * 
     * @return array    Array containg all the properties of the debugline
     * @since V2.0.0 - 21 apr 2006
     */
    public function getProperties()
    {
        return array(
            'class'     => $this->class,
            'file'      => $this->file,
            'function'  => $this->function,
            'line'      => $this->line,
            'info'      => $this->info,
            'type'      => $this->type,
            'startTime' => $this->startTime,
            'endTime'   => $this->endTime
        );
    }

    /**
     * setter of endTime
     * 
     * @since V2.0.0 - 19 apr 2006
     */
    public function setEndTime($endTime)
    {
        $this->endTime = $endTime;
    }

    /**
     * Debug_Line default output function
     * 
     * @since V2.0.0 - 11 apr 2006
     * @see PHP_Debug::dumpVar()
     */
    function __tostring()
    {
        return '<pre>'. PHP_Debug::dumpVar($this, __CLASS__, PHP_DEBUG_DUMP_ARR_STR). '</pre>';
    }

    /**
     * Function that give the debug type lable
     * 
     * @author COil
     * @since  2 avr. 2007
     */
    public static function getDebugLabel($type)
    {
        return self::$debugLineLabels[$type];
    }

    /**
     * Debug_Line class destructor
     * 
     * @since V2.0.0 - 11 apr 2006
     */
    function __destruct()
    {
    }
}

?>
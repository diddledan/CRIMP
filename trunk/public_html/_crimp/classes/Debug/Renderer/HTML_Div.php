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
 * Revision info: $Id: HTML_Div.php,v 1.1 2007-04-29 20:37:32 diddledan Exp $
 *
 * This file is released under the LGPL License under kind permission from Vernet Loïc.
 */

/**
 * Configuration class for HTML_Div
 * 
 * Idea from the debug sytem of Symfony PHP framework 
 * @see http://www.symfony-project.com
 */
require_once 'Debug/Renderer/HTML_Div_Config.php';


/**
 * A floating div renderer for PHP_Debug
 *
 * Returns a floating based representation of the debug infos in XHTML sctrict
 * format
 *
 * @package PHP_Debug
 * @category PHP
 * @author Loïc Vernet <qrf_coil at yahoo dot fr>
 * @since  30 march 2007
 * 
 * @package PHP_Debug
 * @filesource
 */

class PHP_Debug_Renderer_HTML_Div extends PHP_Debug_Renderer_Common
{    
    // debug types for Vars & Config
    static $settingsType = array(
        PHP_DEBUGLINE_ENV,
    );

    // debug types for Log & Message tab
    static $msgTypes = array(
        PHP_DEBUGLINE_STD,
        PHP_DEBUGLINE_PAGEACTION,
        PHP_DEBUGLINE_APPERROR,
        PHP_DEBUGLINE_CREDITS,
        PHP_DEBUGLINE_DUMP,
        PHP_DEBUGLINE_WATCH,
        PHP_DEBUGLINE_PHPERROR,
        //crimp stuff
        PHP_DEBUGLINE_PASS,
        PHP_DEBUGLINE_WARN
    );

    // debug types for Database tab
    static $databaseTypes = array(
        PHP_DEBUGLINE_QUERY,
        PHP_DEBUGLINE_QUERYREL,
        PHP_DEBUGLINE_SQLPARSE,
    );

    /**
     * Debug_Renderer_HTML_Div class constructor
     * 
     * @since V2.1.0 - 3 apr 2007
     */
    function __construct($DebugObject, $options)
    {
        $this->DebugObject = $DebugObject;
        $this->defaultOptions = PHP_Debug_Renderer_HTML_Div_Config::singleton()->getConfig();
        $this->setOptions($options);
        
        if ($this->options['HTML_DIV_disable_credits'] == false) {
            $this->DebugObject->addDebugFirst($this->options['HTML_DIV_credits'], PHP_DEBUGLINE_CREDITS);
        }

        // Add execution time
        $this->DebugObject->addProcessPerf();
    }

    /**
     * This is the function to display the debug informations
     *
     * @since V2.0.0 - 07 Apr 2006
     * @see PHP_Debug::Render()
     */
    public function display()
    {
        $buffer = '';

        // Header    	
        $buffer .= $this->displayHeader();

        // Infos
        $debugInfos = $this->DebugObject->getDebugBuffer(); 
            
        // Vars & config
        $buffer .= $this->showVarsAndConfig($debugInfos);

        // Logs & msg
        $buffer .= $this->showLogsAndMsg($debugInfos);

        // Database
        $buffer .= $this->showDatabaseInfos($debugInfos);

        // Process time
        $buffer .= $this->showProcessTime($debugInfos);
        
        // Footer
        $buffer .= $this->displayFooter();
        
        // Output Buffer
        print($buffer);        
    }

    /**
     * Shows vars & config
     * 
     * @param array debug row
     * 
     * @author COil
     * @since  30 march 2007
     */
    private function showDatabaseInfos($debugInfos)
    {
        $idx = 1;
        $buffer = '';

        foreach ($debugInfos as $debugInfo) {
            $properties = $debugInfo->getProperties();
            if (in_array($properties['type'], self::$databaseTypes)) {                
                $buffer.= '<li>['. $this->processExecTime($properties). ' ms] '. $this->processDebugInfo($properties) .'</li>'. CR;
            }
        }

        return str_replace(
            array('{$buffer}'),
            array($buffer ? $buffer : '<li>&nbsp;</li>'),
            $this->options['HTML_DIV_sfWebDebugDatabaseDetails']
        );
    }

    /**
     * Shows vars & config
     * 
     * @author COil
     * @since  30 march 2007
     * 
c     */
    private function showLogsAndMsg($debugInfos)
    {
        $idx = 1;
        $buffer = '';

        foreach($debugInfos as $debugInfo) {
            $properties = $debugInfo->getProperties();
            if (in_array($properties['type'], self::$msgTypes)) {
            
                // Error level of debug information
                $level = $this->getLogInfoLevel($properties);   
                $infoImg = $this->getImageInfo($level);
            
                $buffer .= '<tr class=\'sfWebDebugLogLine '. $this->getDebugLevelClass($level) .' sfRouting\'>
                    <td class="sfWebDebugLogNumber"># '. $idx. '</td>
                    <td class="sfWebDebugLogType">
                        <img src="'. $this->options['HTML_DIV_images_path']. '/'. $infoImg .'" alt="" />&nbsp;'. $this->processType($properties).
                    '</td>
                    <td class="sfWebDebugLogFile">'.     $this->processFile($properties). '</td>
                    <td class="sfWebDebugLogLine">'.     $this->processLine($properties). '</td>
                    <td class="sfWebDebugLogClass">'.    $this->processClass($properties). '</td>
                    <td class="sfWebDebugLogFunction">'. $this->processFunction($properties). '</td>
                    <td class="sfWebDebugLogTime">'.     $this->processExecTime($properties). '</td>
                    <td class="sfWebDebugLogMessage">'.  $this->processDebugInfo($properties). '</td>
                </tr>'. CR;
                $idx++;
            }
        }

        return str_replace(
            array(
                '{$buffer}',
                '{$imagesPath}',
            ),
            array(
                $buffer,
                $this->options['HTML_DIV_images_path']
            ),
            $this->options['HTML_DIV_sfWebDebugLog']
        );

    }

    /**
     * Get the log level of the debug info
     * 
     * @author COil
     * @since  2 avr. 2007
     * 
     * @param array debug row
     */
    protected function getLogInfoLevel($properties)
    {
        $level = PHP_DEBUGLINE_INFO_LEVEL;

        switch ($properties['type']) {
            case PHP_DEBUGLINE_PAGEACTION:
            case PHP_DEBUGLINE_CREDITS:
            case PHP_DEBUGLINE_DUMP:
            case PHP_DEBUGLINE_WATCH:
            break;
        
            // a crimp thing
            case PHP_DEBUGLINE_WARN:
                $level = PHP_DEBUGLINE_WARNING_LEVEL;
                break;

            case PHP_DEBUGLINE_APPERROR:
                $level = PHP_DEBUGLINE_ERROR_LEVEL;
            break;

            case PHP_DEBUGLINE_PHPERROR:
                $level = $this->getPhpErrorLevel($properties);
            break;
        }
        
        return $level;    	
    }

    /**
     * Return the global error level corresponding to the related php error
     * level
     * 
     * @param array debug row
     * 
     * @author COil
     * @since 2.1.0 - 3 apr 2007
     */
    protected function getPhpErrorLevel($properties)
    {
        $infos = $properties['info'];

        switch ($infos[0]) {
            case E_ERROR:
            case E_PARSE:
            case E_CORE_ERROR:
            case E_COMPILE_ERROR:
            case E_USER_ERROR:
                return PHP_DEBUGLINE_ERROR_LEVEL;
            break;                
            
            case E_WARNING:
            case E_CORE_WARNING:
            case E_NOTICE:
            case E_COMPILE_WARNING:
            case E_USER_WARNING:
            case E_USER_NOTICE:
            case E_ALL:
            case E_STRICT:
            case E_RECOVERABLE_ERROR:
                return PHP_DEBUGLINE_WARNING_LEVEL;
            break;                

            default:
                return PHP_DEBUGLINE_ERROR_LEVEL;
            break;                
        }
    }

    /**
     * Get the image info for the current debug type
     * 
     * @author COil
     * @since  2 avr. 2007
     */
    private function getDebugLevelClass($debug_level)
    {
        return $this->options['HTML_DIV_debug_level_classes'][$debug_level];
    }

    /**
     * Get the image info for the current debug type
     * 
     * @author COil
     * @since  2 avr. 2007
     */
    private function getImageInfo($debug_level)
    {
        $info = $this->options['HTML_DIV_image_info'];
        $warning = $this->options['HTML_DIV_image_warning'];
        $error   = $this->options['HTML_DIV_image_error'];

    	switch ($debug_level) {
            case PHP_DEBUGLINE_INFO_LEVEL:
                $level = $info;
            break;

            case PHP_DEBUGLINE_WARNING_LEVEL:
                $level = $warning;
            break;

            case PHP_DEBUGLINE_ERROR_LEVEL:
                $level = $error;
            break;
    	}
        
        return $level;
    }

    /**
     * Shows vars & config
     * 
     * @author COil
     * @since  30 march 2007
     */
    private function showVarsAndConfig($debugInfos)
    {
        return str_replace(
            array(
                '{$sfWebDebugRequest}',
                '{$sfWebDebugResponse}',
                '{$sfWebDebugSettings}',
                '{$sfWebDebugGlobals}',
                '{$sfWebDebugPhp}',
                '{$sfWebDebugFiles}',
                '{$imagesPath}',
            ),
            array(
                $this->showSuperArray(PHP_DEBUG_GLOBAL_REQUEST),
                $this->showSuperArray(PHP_DEBUG_GLOBAL_COOKIE),
                $this->showArray($this->settingsAsArray($debugInfos)),
                $this->showArray($this->globalsAsArray()),
                $this->showArray($this->phpInfoAsArray()),
                $this->showTemplates(),
                $this->options['HTML_DIV_images_path'],
            ),
            $this->options['HTML_DIV_sfWebDebugConfig']
        );
    }

    /**
     * Return all settings of application
     * 
     * @author COil
     * @since  2 avr. 2007
     */
    public function settingsAsArray($debugInfos)
    {
        $settings = array();
        foreach($debugInfos as $debugInfo) {
            $infos = $debugInfo->getProperties();
            if (in_array($infos['type'], self::$settingsType)) {
                $settings[] = $infos['info']; 
            }
        }	
    
        return $settings;
    }

   /**
    * Returns PHP globals variables as a sorted array.
    *
    * @return array PHP globals
    */
    public static function globalsAsArray()
    {
        $values = array();
        foreach (array('cookie', 'server', 'get', 'post', 'files', 'env', 'session') as $name) {

            if (!isset($GLOBALS['_'.strtoupper($name)])) {
                continue;
            }
    
            $values[$name] = array();
            foreach ($GLOBALS['_'.strtoupper($name)] as $key => $value) {
                $values[$name][$key] = $value;
            }
            ksort($values[$name]);
        }   

        ksort($values);

        return $values;
    }

    /**
     * Returns PHP information as an array.
     * 
     * @return  array An array of php information
     */
    public static function phpInfoAsArray()
    {
        $values = array(
            'php'        => phpversion(),
            'os'         => php_uname(),
            'extensions' => get_loaded_extensions(),
        );

        return $values;
    }

    /**
     * Add the process time information to the debug information
     * 
     * @since V2.0.0 - 18 Apr 2006
     */ 
    private function showProcessTime($debugInfos)
    {
        // Lang
        $txtExecutionTime = 'Global execution time ';
        $txtPHP           = 'PHP';
        $txtSQL           = 'SQL';              
        $txtSECOND        = 's';
        $txtOneQry        = ' query';
        $txtMultQry       = ' queries';
        $queryCount       = $this->DebugObject->getQueryCount();
        $txtQuery         = $queryCount > 1 ? $txtMultQry : $txtOneQry;
        $buffer           = '';

        // Performance Debug
        $processTime = $this->DebugObject->getProcessTime();
        $sqlTime    = $this->DebugObject->getQueryTime();
        $phpTime    = $processTime - $sqlTime;
    
        $sqlPercent = round(($sqlTime / $processTime) * 100, 2);                              
        $phpPercent = round(($phpTime / $processTime) * 100, 2);

        $processTime = $processTime*1000;
        $sqlTime    = $sqlTime*1000;
        $phpTime    = $phpTime*1000;
        
        if ($debugInfos) {
            $buffer .= '
            <tr>
                <th>message</th>
                <th>time (ms)</th>
                <th>percent</th>
            </tr>'. CR;

        	foreach($debugInfos as $debugInfo) {
                $properties = $debugInfo->getProperties();
                if ($properties['startTime'] && $properties['endTime']) {

                    $localPercent = round((($properties['endTime'] - $properties['startTime'])*1000 / $processTime) * 100, 2);
                    $buffer .= '
                    <tr>
                        <td class="sfWebDebugLogMessagePerf">'. $this->ProcessDebugInfo($properties). '</td>
                        <td style="text-align: right">'. $this->ProcessExecTime($properties). '</td>
                        <td style="text-align: right">'. $localPercent. '%</td>
                    </tr>'. CR;
                }
            }
        }

        return str_replace(
            array(
                '{$txtExecutionTime}',
                '{$processTime}',
                '{$txtPHP}',
                '{$phpTime}',
                '{$phpPercent}',
                '{$txtSQL}',
                '{$sqlTime}',
                '{$sqlPercent}',
                '{$queryCount}',
                '{$txtQuery}',
                '{$buffer}'
                
            ),
            array(
                $txtExecutionTime,
                $processTime,
                $txtPHP,
                $phpTime,
                $phpPercent,
                $txtSQL,
                $sqlTime,
                $sqlPercent,
                $queryCount,
                $txtQuery,
                $buffer
            ),
            $this->options['HTML_DIV_sfWebDebugTimeDetails']       
        );
    }

    /**
     * Default render function for HTML_Div renderer
     *
     * @since 11 Apr 2006
     * @see Renderer
     */
    public function render()
    {
        $this->display();
    }

    /**
     * Displays the header of the PHP_Debug object
     *
     * @since 08 Apr 2006
     * @see PHP_Debug
     */
    protected function displayHeader()
    {
        return str_replace(
            array(
                '{$nb_queries}', 
                '{$exec_time}',
                '{$imagesPath}',
                '{$phpDebugVersion}'
            ),
            array(
                $this->DebugObject->getQueryCount(), 
                $this->DebugObject->getProcessTime()*1000,
                $this->options['HTML_DIV_images_path'],
                PHP_DEBUG_RELEASE
            ),        
            $this->options['HTML_DIV_header']);  
    }        

    /**
     * Diplays the footer of the PHP_Debug object
     *
     * @since 08 Apr 2006
     * @see PHP_Debug
     */
    protected function displayFooter()
    {
        return $this->options['HTML_DIV_footer'];
    }        
    
    /**
     * process display of the execution time of debug information  
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the main debug info
     * @since V2.0.0 - 28 Apr 2006
     */ 
    private function processExecTime($properties)
    {   
        // Lang
        $txtPHP = 'PHP';
        $txtSQL = 'SQL';
        $txtSECOND = 's';

        if (!empty($properties['endTime'])) {
            $buffer .= $this->span(PHP_Debug::getElapsedTime($properties['startTime'], $properties['endTime'])*1000, 'time');
        } else {
            $buffer .= '&nbsp;';
        }

        return $buffer; 
    }
    
    /**
     * process display of the main information of debug 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the main debug info
     * @since V2.0.0 - 28 Apr 2006
     */ 
    private function processDebugInfo($properties)
    {   
        $buffer = '';

        switch($properties['type']) {

            // Case for each of the debug lines types
            // 1 : Standard
            case PHP_DEBUGLINE_STD:
                $buffer .= $this->span($properties['info'], 'std');
                break;
            
            // 2 : Query
            case PHP_DEBUGLINE_QUERY:
                $buffer .= preg_replace('/\b(SELECT|FROM|AS|LIMIT|ASC|COUNT|DESC|WHERE|LEFT JOIN|INNER JOIN|RIGHT JOIN|ORDER BY|GROUP BY|IN|LIKE|DISTINCT|DELETE|INSERT|INTO|VALUES)\b/', '<span class="sfWebDebugLogInfo">\\1</span>', $properties['info']);
                break;

            // 3 : Query related
            case PHP_DEBUGLINE_QUERYREL:
                $buffer .= $this->span($properties['info'], 'query');
                break;
                
            // 4 : Environment
            case PHP_DEBUGLINE_ENV:
                $buffer .= $this->showSuperArray($properties['info']);
                break;

            // 6 : User app error
            case PHP_DEBUGLINE_APPERROR:
                $buffer .= $this->span('/!\\<br />&nbsp;&nbsp;&nbsp;' . nl2br(htmlspecialchars($properties['info'])), 'app-error');
                break;
                
            // 7
            case PHP_DEBUGLINE_CREDITS:
                $buffer .= $this->span($properties['info'], 'credits');            
                break;

            // 9
            case PHP_DEBUGLINE_DUMP:
                $buffer .= $this->showDump($properties);
                break;

            // 10
            case PHP_DEBUGLINE_PROCESSPERF:
                $buffer .= $this->showProcessTime();
                break;

            // 11 : Main Page Action
            case PHP_DEBUGLINE_PAGEACTION;
                $buffer .= $this->span('[Action : '. $properties['info']. ']' , 'pageaction');
                break;

            // 12 : SQL parse 
            case PHP_DEBUGLINE_SQLPARSE:
                $buffer .= $properties['info'];
                break;

            // 13 : Watches
            case PHP_DEBUGLINE_WATCH:
                $infos = $properties['info'];
                $buffer .= 'Variable '. $this->span($infos[0], 'watch').
                           ' changed from value '. $this->span($infos[1], 'watch-val'). ' ('. gettype($infos[1]). 
                                    ') to value '. $this->span($infos[2], 'watch-val'). ' ('. gettype($infos[2]). ')';
                break;

            // 14 : PHP errors
            case PHP_DEBUGLINE_PHPERROR:                
                $buffer .= $this->showError($properties['info']);
                break;
            
            // a couple CRIMPed items
            case PHP_DEBUGLINE_PASS:
            case PHP_DEBUGLINE_WARN:
                $buffer .= nl2br(htmlspecialchars($properties['info']));
                break;

            default:
                $buffer .= "<b>Default(". $properties['type'].
                           ")</b>: TO IMPLEMENT OR TO CORRECT : >". 
                           $properties['info']. '<';
                break;
        }

        return $buffer;
    }

    /**
     * Return a string with applying a span style on it
     * 
     * @param string $info String to apply the style
     * @param string $class CSS style to apply to the string
     * @return string Formatted string with style applied
     * @since V2.0.0 - 05 May 2006
     */ 
    private function span($info, $class)
    {   
        return '<span class="'. $class .'">'. $info .'</span>'; 
    }

    /**
     * process display of the type of the debug information 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the debug type
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function processType($properties)
    {   
        $buffer = PHP_Debug_Line::$debugLineLabels[$properties['type']];
        return $buffer;
    }

    /**
     * process display of Class 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the class
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function processClass($properties)
    {
        $buffer = '';

        switch ($properties['type'])
        {
            case PHP_DEBUGLINE_STD:
            case PHP_DEBUGLINE_QUERY:
            case PHP_DEBUGLINE_QUERYREL:
            case PHP_DEBUGLINE_APPERROR:             
            case PHP_DEBUGLINE_PAGEACTION:
            case PHP_DEBUGLINE_PHPERROR:
            case PHP_DEBUGLINE_SQLPARSE:
            case PHP_DEBUGLINE_WATCH:
            case PHP_DEBUGLINE_DUMP:
                        
                if (!empty($properties['class'])) {
                    $buffer .= $properties['class'];
                } else {
                    $buffer .= '&nbsp;';
                }

                break;
                        
            case PHP_DEBUGLINE_CREDITS: 
            case PHP_DEBUGLINE_SEARCH:
            case PHP_DEBUGLINE_PROCESSPERF:
            case PHP_DEBUGLINE_TEMPLATES:
            case PHP_DEBUGLINE_ENV:

                $buffer .= '&nbsp;';

                break;
        
            default:
                break;
        }
        
        return $buffer;
    }

    /**
     * process display of function 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the function
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function processFunction($properties)
    {
        $buffer = '';

        switch ($properties['type'])
        {
            case PHP_DEBUGLINE_STD:
            case PHP_DEBUGLINE_QUERY:
            case PHP_DEBUGLINE_QUERYREL:
            case PHP_DEBUGLINE_APPERROR:             
            case PHP_DEBUGLINE_PAGEACTION:
            case PHP_DEBUGLINE_PHPERROR:
            case PHP_DEBUGLINE_SQLPARSE:
            case PHP_DEBUGLINE_WATCH:
            case PHP_DEBUGLINE_DUMP:
                        
                if (!empty($properties['function'])) {                	
                    if ($properties['function'] != 'unknown') { 
                        $buffer .= $properties['function']. '()';
                    } else {
                        $buffer .= '&nbsp;';
                }
                } else {
                    $buffer .= '&nbsp;';
                }

                break;
                        
            case PHP_DEBUGLINE_CREDITS: 
            case PHP_DEBUGLINE_SEARCH:
            case PHP_DEBUGLINE_PROCESSPERF:
            case PHP_DEBUGLINE_TEMPLATES:
            case PHP_DEBUGLINE_ENV:

                $buffer .= '&nbsp;';
                break;
        
            default:
                break;
        }
        
        return $buffer;
    }


    /**
     * process display of line number 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the line number
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function processLine($properties)
    {
        $buffer = '';

        switch ($properties['type'])
        {
            case PHP_DEBUGLINE_STD:
            case PHP_DEBUGLINE_QUERY:
            case PHP_DEBUGLINE_QUERYREL:
            case PHP_DEBUGLINE_APPERROR:             
            case PHP_DEBUGLINE_PAGEACTION:
            case PHP_DEBUGLINE_PHPERROR:
            case PHP_DEBUGLINE_SQLPARSE:
            case PHP_DEBUGLINE_WATCH:
            case PHP_DEBUGLINE_DUMP:
                        
                if (!empty($properties['line'])) {
                    $buffer.= '<span class="line">'. $properties['line']. '</span>';
                } else {
                    $buffer.= '&nbsp;';
                }        

                break;
                        
            case PHP_DEBUGLINE_CREDITS: 
            case PHP_DEBUGLINE_SEARCH:
            case PHP_DEBUGLINE_PROCESSPERF:
            case PHP_DEBUGLINE_TEMPLATES:
            case PHP_DEBUGLINE_ENV:

                $buffer.= '&nbsp;';

                break;
        
            default:
                break;
        }
        
        return $buffer;
    }

    /**
     * process display of file name 
     * 
     * @param array $properties Properties of the debug line
     * @return string Formatted string containing the file
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function processFile($properties)
    {
    	$buffer = '';

        switch ($properties['type'])
        {
            case PHP_DEBUGLINE_STD:
            case PHP_DEBUGLINE_QUERY:
            case PHP_DEBUGLINE_QUERYREL:
            case PHP_DEBUGLINE_APPERROR:             
            case PHP_DEBUGLINE_PAGEACTION:
            case PHP_DEBUGLINE_PHPERROR:
            case PHP_DEBUGLINE_SQLPARSE:
            case PHP_DEBUGLINE_WATCH:
            case PHP_DEBUGLINE_DUMP:

                if (!empty($properties['file'])) {
                    if (!empty($this->options['HTML_DIV_view_source_script_path']) and !empty($this->options['HTML_DIV_view_source_script_name'])) {
                        $buffer .= '<a href="'. $this->options['HTML_DIV_view_source_script_path']
                                . '/'. $this->options['HTML_DIV_view_source_script_name']  
                                .'?file='. urlencode($properties['file']);

                        $buffer .= '">'. basename($properties['file']). '</a>'; 

                    } else {
                        $buffer .= basename($properties['file']);                    	
                    }
                } else {
                    $buffer .=  '&nbsp;';
                }        
        
                break;
                        
            case PHP_DEBUGLINE_CREDITS: 
            case PHP_DEBUGLINE_SEARCH:
            case PHP_DEBUGLINE_PROCESSPERF:
            case PHP_DEBUGLINE_TEMPLATES:
            case PHP_DEBUGLINE_ENV:

                $buffer .=  '&nbsp;';

                break;
        
            default:
                break;
        }
        
        return $buffer;
    }

    /**
     * Print the dump of a variable
     * 
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function showDump($properties)
    {
    	$buffer = '';

        // Check display with a <pre> design
        if (is_array($properties['info'][1])) {
            $preDisplay = true;                      
        } elseif (is_object($properties['info'][1])) {
            $preDisplay = true;                      
        } else {
            $preDisplay = false;                      
        }

        // Check var name
        if (empty($properties['info'][0])) {
            if (is_array($properties['info'][1])) {
                $varName = 'Array';
            } elseif (is_object($properties['info'][1])) {
                $varName = get_class($properties['info'][1]);
            } else {
                $varName = 'Variable';                              
            }
        } else {
            $varName = $properties['info'][0];
        }
        
        // Output
        if ($properties['type'] != PHP_DEBUGLINE_ENV) { 
            $title = "dump of '";
        } 
        
        $title .= $varName. "' (".  gettype($properties['info'][1]) .") : ";
        
        $buffer .= $this->span($title , 'dump-title');
        
        if ($preDisplay == true){
            $buffer .= '<pre>';                   
            $buffer .= PHP_Debug::dumpVar($properties['info'][1], '', false, PHP_DEBUG_DUMP_STR);
        } else {
            $buffer .= $this->span(PHP_Debug::dumpVar($properties['info'][1], '', false, PHP_DEBUG_DUMP_STR), 'dump-val');
        }

        if ($preDisplay == true) {
            $buffer .= '</pre>';                  
        }

        return $buffer;
    }

    /**
     * Print the templates
     * 
     * @since V2.0.0 - 26 Apr 2006
     */ 
    private function showTemplates()
    {
        $txtMainFile = 'MAIN File';
        $idx = 1;
        $buffer = '<br />';

        foreach($this->DebugObject->getRequiredFiles() as $lvalue) {
        	
        	$isToDisplay = true;
        	
        	foreach ($this->options['HTML_DIV_view_source_excluded_template'] as $template) {        		
        		if (stristr($lvalue, $template)) {
        			$isToDisplay = false;
        		}
        	}
        	
        	if ($isToDisplay == true) {

                $buffer .= '<div class="source">';
	            $buffer .= $this->span($this->truncate($lvalue), 'files');
	            $buffer .= ' <a href="'. $this->options['HTML_DIV_view_source_script_path']
	                         . '/'. $this->options['HTML_DIV_view_source_script_name']  
	                         .'?file='. urlencode($lvalue). '">View source</a> ';
	                
	            // main file    
	            if ($idx == 1) {
	                $buffer .= $this->span("&laquo; $txtMainFile", 'main-file');
	            }                       
	            $idx++;
	            $buffer .= '</div><br />'. CR;
        	}            
        }        

        $buffer .= '<br />'. CR;
        return $buffer; 
    }
    
    
    /**
     * Truncate/replace a pattern from the file path
     * 
     * @param string full file path
     * 
     * @author COil
     * @since 2.1.0 - 3 apr 2007
     * 
     * @see 
     * - HTML_DIV_remove_templates_pattern
     * - HTML_DIV_templates_pattern
     */
    protected function truncate($file)
    {
    	if ($this->options['HTML_DIV_remove_templates_pattern'] && $this->options['HTML_DIV_templates_pattern']) {
            return strtr($file, $this->options['HTML_DIV_templates_pattern']);
    	} 

        return $file;
    }
    
    /**
     * Print an error
     * 
     * @param array $info Array containing information about the error
     * 
     * @since V2.0.0 - 25 Apr 2006
     * @see PHP_DEBUGLINE_PHPERROR
     * @todo Implement the strict error level, add an option to display or not
     * the stricts errors
     * 
     */ 
    private function showError($infos)    
    {
    	   
        $buffer = '';
        $infos[1] = str_replace("'", '"', $infos[1]);
        $infos[1] = str_replace('href="function.', ' href="http://www.php.net/'. $this->options['DEBUG_lang']. '/', $infos[1]);

        switch ($infos[0])
        {
            case E_WARNING:
                $errorlevel = 'PHP WARNING : ';
                $buffer .= '<span class="pd-php-warning"> /!\\ '. $errorlevel. $infos[1] . ' /!\\ </span>';                
                break;

            case E_NOTICE:
                $errorlevel = 'PHP notice : ';
                $buffer .= '<span class="pd-php-notice">'. $errorlevel. $infos[1] . '</span>';
                break;

            case E_USER_ERROR:
                $errorlevel = 'PHP User error : ';
                $buffer .= '<span class="pd-php-user-error"> /!\\ '. $errorlevel. $infos[1] . ' /!\\ </span>';
                break;

            case E_STRICT:
                
                $errorlevel = 'PHP STRICT error : ';
                $buffer .= '<span class="pd-php-user-error"> /!\\ '. $errorlevel. $infos[1] . ' /!\\ </span>';
                break;

            default:
                $errorlevel = 'PHP errorlevel = '. $infos[0]. ' : ';
                $buffer .= $errorlevel. ' is not implemented in PHP_Debug ('. __FILE__. ','. __LINE__. ')';
                break;
        }
        
        return $buffer;
    }

    /**
     * Show a super array
     * 
     * @param string $SuperArrayType Type of super en array to add
     * @since V2.0.0 - 07 Apr 2006
     */ 
    private function showSuperArray($SuperArrayType)    
    {
        // Lang
        $txtVariable   = 'Var';
        $txtNoVariable = 'NO VARIABLE';
        $NoVariable    = " -- $txtNoVariable -- ";
        $SuperArray    = null;
        $buffer        = '';

        $ArrayTitle = PHP_Debug::$globalEnvConstantsCorresp[$SuperArrayType];
        $SuperArray = $GLOBALS["$ArrayTitle"];
        $Title = "$ArrayTitle $txtVariable";
        $SectionBasetitle = "<b>$Title (". count($SuperArray). ') :';

        if (count($SuperArray)) {
            $buffer .= $SectionBasetitle. '</b>';
            $buffer .= '<pre>'. PHP_Debug::dumpVar($SuperArray, $ArrayTitle, false,PHP_DEBUG_DUMP_STR). '</pre>';
        } else {
            $buffer .= $SectionBasetitle. "$NoVariable</b>";
        }
        
        return $buffer;
    }

    /**
     * Show a super array
     * 
     * @param string $SuperArrayType Type of super en array to add
     * @since V2.0.0 - 07 Apr 2006
     */ 
    private function showArray($array, $name)    
    {
        // Lang
        $txtNoVariable = 'NO VARIABLE';
        $NoVariable    = " -- $txtNoVariable -- ";
        $buffer        = '';
        $SectionBasetitle = '<b>'. $name. '('. count($array). ') :';

        if (count($array)) {
            $buffer .= $SectionBasetitle. '</b>';
            $buffer .= '<pre>'. PHP_Debug::dumpVar($array, $name, false, PHP_DEBUG_DUMP_STR). '</pre>';
        } else {
            $buffer .= $SectionBasetitle. $NoVariable. '</b>';
        }
        
        return $buffer;
    }

    /**
     * Return the style sheet of the HTML_TABLE debug object
     * 
     * @return string The stylesheet
     *
     * @since 13 Apr 2006
     */    
    public function getStyleSheet()
    {
        return $this->options['HTML_DIV_stylesheet'];
    }
}
?>
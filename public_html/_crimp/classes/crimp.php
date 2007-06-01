<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: crimp.php,v 1.26 2007-06-01 21:57:48 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

define('HTTP_EXIT_UNKNOWN',     -1);
define('HTTP_EXIT_OK',          200);
define('HTTP_EXIT_NO_CONTENT',  204);
define('HTTP_EXIT_FORBIDDEN',   403);
define('HTTP_EXIT_NOT_FOUND',   404);
define('HTTP_EXIT_SERVER_ERROR',500);

/**
 *the plugin configuration scopes
 */
define('SCOPE_SECTION',         1);
define('SCOPE_CRIMP',           0);
define('MAX_SCOPE_VALUE',       1);

/**
 *CRIMP's main class
 */
class Crimp {
    /**
     *html headers like <meta /> tags, <script></script> tags and etc.
     */
    protected $htmlheaders = array(
        '<script type="text/javascript" src="/crimp_assets/js/mootools.js"></script>',
        '<script type="text/javascript" src="/crimp_assets/js/html_div.js"></script>',
        '<script type="text/javascript" src="/crimp_assets/js/ajax-click-handler.js"></script>',
        '<link rel="stylesheet" type="text/css" href="/crimp_assets/debug-css/html_div.css" />',
        '<link rel="stylesheet" type="text/css" href="/crimp_assets/debug-css/html_table.css" />',
    );
    
    /**
     *this is for all the content that will be sent to the user's browser
     *upon completion of execution of all plugins.
     */
    public $_output;
    
    /**
     *the title of the page - appended to by setTitle()
     */
    protected $pageTitle;
    /**
     *the Content-type returned to the browser upon completion
     */
    protected $_contentType = 'text/html';
    /**
     *this value is sent to the browser at the end in an HTTP header.
     *200 for OK, 404 for Not Found, 500 for Internal Server Error etc.
     */
    protected $_exitCode = '204';
    /**
     *$_HTTPRequest contains the full URL of the requested document minus the
     *server info, eg. /path/to/some/document.html
     */
    protected $_HTTPRequest;
    protected $RemoteHost;
    protected $serverName;
    protected $serverSoftware;
    protected $serverProtocol;
    protected $userAgent;
    protected $debugMode = 'Div';
    protected $debugSwitch = false;
    
    public $_config;
    protected $varDir;
    protected $errordir;
    protected $templatedir;
    protected $defaultLang;
    /**
     *the deepest URL path that has been defined in the config file which
     *matches the current request.
     */
    protected $_userConfig;
    /**
     *$pluginLock is for plugins to add to if they are to be called only once.
     *basically the idea is that a plugin will call
     *  $this->crimp->pluginLock('pluginname', true);
     *which will create
     *  $this->_pluginLock['pluginname'] = true;
     *the plugin should then check this value on loading and error out if it's
     *set to true.
     */
    protected $_pluginLock;
    /**
     *a plugin can set it's name in this array if it is to be deferred until the
     *end of execution. designed for plugins like buttonBar which needs to be
     *executed after the template has been applied
     */
    protected $deferredPlugins;
    /**
     *the list of executed plugins and how many times they've been executed
     *(array of arrays: the first key is the scope, and the second key is the
     *plugin name, the value of which is the number of times the plugin has been
     *executed in this scope.)
     */
    protected $executedPlugins;
    /**
     *debug object
     */
    protected $debug;
    /**
     *default header
     */
    public $defaultHTMLHeader = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
</head>
<body>';
    /**
     *default footer
     */
    public $defaultHTMLFooter = '</body></html>';
    
    /**
     * default form headers and footers appended to every non-ajaxed page
     */
    public $contentHeader = '';
    public $contentFooter = '</span></form>';
    
    /**
     *default page content
     */
    public $defaultHTMLContent = '<!--startMenuContent-->
<!--endMenuContent-->
<!--startPageContent-->
<!--endPageContent-->';
    /**
     *default full html page
     */
    public $defaultHTML = '';
    
    /**
     *HTTP status indicator codes and their names/descriptions
     */
    protected $HTTP_EXIT_CODES = array(
        HTTP_EXIT_UNKNOWN       => array('text' => 'Unknown', 'desc' => 'Unknown HTTP Error Code'),
        HTTP_EXIT_OK            => array('text' => 'OK', 'desc' => null),
        HTTP_EXIT_NO_CONTENT    => array('text' => 'No Content', 'desc' => null),
        HTTP_EXIT_FORBIDDEN     => array('text' => 'Forbidden', 'desc' => 'You do not have permission to view this resource.'),
        HTTP_EXIT_NOT_FOUND     => array('text' => 'Not Found', 'desc' => 'The file you were trying to view cannot be found.'),
        HTTP_EXIT_SERVER_ERROR  => array('text' => 'Internal Server Error', 'desc' => 'The server encountered an error with your request. Please try again.')
    );
    
    /**
     *are we ajaxed of not?
     */
    public $ajax = false;
    
    /**
     *constructor
     */
    function __construct() {
        if (isset($_GET['crimpq'])) {
            $this->_HTTPRequest = $_GET['crimpq'];
        }
        unset($_GET['crimpq']);
        
        if (isset($_POST['crimpPostback']) && isset($_POST['crimpURL']) && ($_POST['crimpURL'] != '')) {
            $this->_HTTPRequest = $_POST['crimpURL'];
            $this->ajax = true;
        }
        
        if (!$this->_HTTPRequest) $this->_HTTPRequest = '/';
        
        $me = $_SERVER['PHP_SELF'];
        
        /**
         * apply a form into the contentHeader with an action of the root index.php file
         */
        $this->contentHeader = <<<contentheader
<form id='crimp' action='$me'>
<input type='hidden' name='crimpPostback' value='true' />
<input type='hidden' id='crimpURL' name='crimpURL' value='' />
<span id='crimpPageContent'>
contentheader;
        
        $this->defaultHTML          = implode("\n", array($this->defaultHTMLHeader,$this->contentHeader,$this->defaultHTMLContent,$this->contentFooter,$this->defaultHTMLFooter));
        
        $this->_output              = $this->defaultHTMLContent;
        
        /**
         *initialise the executedPlugins array of arrays
         */
        for($i = 0; $i <= MAX_SCOPE_VALUE; $i++) $this->executedPlugins[$i] = array();
    }
    
    public function setup() {
        $this->parseConf();
        $this->debug = new PHP_Debug(array('render_mode' => (($this->debugMode) ? $this->debugMode : 'Div'),
                                           'replace_errorhandler' => true));
        $this->parseUserConfig();
        $this->applyConfig();
        
        $this->remoteHost           = $_ENV['REMOTE_ADDR'];
        $this->serverName           = $_ENV['SERVER_NAME'];
        $this->serverSoftware       = $_ENV['SERVER_SOFTWARE'];
        $this->serverProtocol       = $_ENV['SERVER_PROTOCOL'];
        $this->userAgent            = $_ENV['HTTP_USER_AGENT'];
        
        define('REMOTE_HOST',       $this->remoteHost);
        define('SERVER_NAME',       $this->serverName);
        define('SERVER_SOFTWARE',   $this->serverSoftware);
        define('PROTOCOL',          $this->serverProtocol);
        define('USER_AGENT',        $this->userAgent);
        define('HTTP_REQUEST',      $this->_HTTPRequest);
        
        PASS("Remote Host: {$this->remoteHost}
Server Name: {$this->serverName}
Server Software: {$this->serverSoftware}
User Agent: {$this->userAgent}
Requested Document: {$this->_HTTPRequest}
UserConfig: {$this->_userConfig}");
    }
    
    public function PASS($message) {
        if (isset($this->debug)) {
            $this->debug->add($message);
        }
    }
    public function WARN($message) {
        if (isset($this->debug)) {
            $this->debug->add($message, PHP_DebugLine::TYPE_WARNING);
        }
    }
    public function FAIL($message) {
        if (isset($this->debug)) {
            $this->debug->error($message);
        }
    }
    public function DUMP($variable, $varname = '') {
        if (isset($this->debug)) {
            $this->debug->dump($variable, $varname);
        }
    }
    public function StopTimer() {
        if (isset($this->debug)) {
            $this->debug->stopTimer();
        }
    }
    
    /**
     *parse the configuration to set some values
     */
    private function applyConfig() {
        $this->errorDir     = ( $cfg = $this->Config('errordir', SCOPE_CRIMP) ) ? $cfg : CRIMP_HOME.'/errordocs';
        define('ERROR_DIR', $this->errorDir);
        $this->templateDir  = ( $cfg = $this->Config('templatedir', SCOPE_CRIMP) ) ? $cfg : CRIMP_HOME.'/templates';
        define('TEMPLATE_DIR', $this->templateDir);
        $this->varDir       = ( $cfg = $this->Config('vardir', SCOPE_CRIMP) ) ? $cfg : CRIMP_HOME.'/var';
        define('VAR_DIR', $this->varDir);
        $this->defaultLang  = ( $cfg = $this->Config('defaultlanguage', SCOPE_SECTION) ) ? $cfg : 'en';
        define('DEFAULT_LANG', $this->defaultLang);
        $this->setTitle( ( $cfg = $this->Config('title', SCOPE_SECTION) ) ? $cfg : '', true );
    }
    
    /**
     *figure out which <section> from the config file the requested document
     *falls under. this will find the most specific declaration, eg. if '/' and
     *'/blog' are both defined, '/blog/blah' in the HTTPRequest will set the
     *userConfig to '/blog'. similarly, if '/blog' and '/blog/some/document' are
     *defined, the same HTTPRequest will still match '/blog'. this function
     *will default to '/', so this section should _always_ have a listing in the
     *configuration file.
     */
    private function parseUserConfig() {
        $tmpstr = $userConfig = '';
        /**
         *remove the index.php from the request string
         */
        $this->_HTTPRequest = preg_replace('|^/?.*?index.php5?|', '', $this->_HTTPRequest, 1);
        
        $req = explode('/', $this->_HTTPRequest);
        foreach( $req as $_ ) {
            if ( $_ ) $tmpstr = implode('/',array($tmpstr,$_));
            if ( $this->_config->xpath("/crimp/section[@name='$tmpstr']") )
                $userConfig = $tmpstr;
        }
        
        $this->_userConfig = ($userConfig) ? $userConfig : '/';
    }
    
    /**
     *set the document's title for inclusion in the <title></title> tags
     */
    public function setTitle($title, $overwrite = false) {
        if ( $overwrite ) {
            PASS("setTitle(): Overwriting page title with '$title'");
            $this->pageTitle = $title;
        } else {
            $sep = ' - ';
            if ( $conf = $this->Config('titleseparator', SCOPE_SECTION) ) $sep = $conf;
            
            $cur = $this->pageTitle;
            PASS("setTitle(): Adding '$title' to page title");
            $this->pageTitle = ( $this->Config('titleorder', SCOPE_SECTION) == 'forward' )
                ? "$cur$sep$title" : "$title$sep$cur";
        }
    }
    
    /**
     *add content to the html page
     */
    public function addContent($htmlcontent, $location = 'bottom') {
        $loc = $location;
        if ($loc === true) $loc = 'overwrite';
        PASS("Adding content ($loc)");
        
        $br = "\n<br />\n";
        
        if ( !$this->_output || $this->_output == $this->defaultHTMLContent ) {
            $this->_output = $this->defaultHTMLContent;
            $location = 'top';
            $br = '';
        } elseif ( $loc == 'overwrite' ) {
            $this->_output = $this->defaultHTMLContent;
            $loc = 'top';
            $br = '';
        }
        
        $var = 1;
        if ( $loc == 'top' ) {
            $this->_output = str_replace('<!--startPageContent-->',"<!--startPageContent-->$htmlcontent$br",$this->_output, $var);
        } else {
            $this->_output = str_replace('<!--endPageContent-->',"$br$htmlcontent<!--endPageContent-->",$this->_output, $var);
        }
        
        $this->debug->stopTimer();
    }
    
    /**
     *add content to the menu which appears above the page content,
     *eg. for fileList plugin
     */
    public function addMenu($menu, $location = 'last') {
        if ( ($location == 'first') ) {
            PASS('Adding MenuContent (top)');
            $this->_output = preg_replace('|<!--startMenuContent-->|i', "$0\n$menu<br />\n", $this->_output);
	} else {
            PASS('Adding MenuContent (bottom)');
            $this->_output = preg_replace('|<!--endMenuContent-->|i', "<br />\n$menu\n$0", $this->_output);
        }
    }
    
    /**
     *add a new header for inclusion into the final html document
     */
    public function addHeader($header) {
        PASS("addHeader(): adding html header:\n$header");
        array_push($this->htmlheaders, $header);
    }
    
    /**
     *if we get an error, call this function and it will negotiate a language
     *with the browser and send an error document in that language if one
     *exists. if there isn't a document in that language, the default language
     *is tried, and finally falling back to english. if none of these match,
     *then a generic error message is displayed.
     *
     *IMPORTANT: this function stops all execution immediately. no more plugins
     *will be called afterwards.
     */
    public function errorPage($package, $errorCode = '500') {
        PASS("errorPage(): package: $package; errorCondition: $errorCode");

        if ( $package ) $package = "-$package";
        $languages = array();
        $errordir = $this->errorDir;
        if ( $dir = @opendir($errordir) ) {
            while ( ($file = readdir($dir)) !== false ) if ($file != "." && $file != "..") {
                if ( is_dir("$dir/$file") ) $languages[$file] = true;
            }
            closedir($dir);unset($file);
        }
        
        $deflang = $this->defaultLang;
        $clientLang = HTTP::negotiateLanguage($languages, $deflang);
        
        if ( isset($_COOKIE['preferred_language']) ) $clientLang = $_COOKIE['preferred_language'];
        
        $errorFiles = array(
            "$errordir/$clientLang/$errorCode$package.html",
            "$errordir/$clientLang/$errorCode.html",
            "$errordir/$deflang/$errorCode$package.html",
            "$errordir/$deflang/$errorCode.html",
            "$errordir/en/$errorCode$package.html",
            "$errordir/en/$errorCode.html",
        );
        unset($errordir, $clientLang, $deflang, $plugin);
        
        $content = false;
        foreach ( $errorFiles as $file ) {
            if ( $content ) next;
            if ( file_exists($file) ) list($title, $content) = $this->stripHeaderFooter($this->pageRead($file));
        }
        unset($errorFiles, $file);
        
        if ( ! $content ) {
            global $http;
            $title = "Error '$errorCode'";
            if (isset($this->HTTP_EXIT_CODES[$errorCode])) {
                $errorName = $this->HTTP_EXIT_CODES[$errorCode]['text'];
                $errorDescription = $this->HTTP_EXIT_CODES[$errorCode]['desc'];
            } else {
                $errorName = 'Unknown';
                $errorDescription = 'An unknown error status has been encountered.';
            }
            $content = "
<h1>Error '$errorCode': $errorName</h1>
<p>$errorDescription</p>
<p>Additionally, a 404: Not Found error was encountered while trying to use a 'friendly' error document for this request.</p>
";
        }
        
        $this->debug->stopTimer();
        $this->addContent($content, true);
        $this->setTitle($title, true);
        $this->exitCode($errorCode);
        $this->sendDocument(false);
    }
    
    /**
     *this one speaks for itself - iterates through the deferredPlugins array
     *executing the plugins that have manually set themselves to 'deferred'
     *status. No check to determine if the deferredPlugins var is an array!!
     */
    public function executeDeferredPlugins() {
        /**
         *no test here for a pluginLock, as a plugin that sets a deferred
         *status should not be locking itself as well
         */
        if ($this->deferredPlugins && is_array($this->deferredPlugins)) {
            PASS("Executing deferred plugins...");
            foreach ( $this->deferredPlugins as $plugin ) {
                $this->executePlugin($plugin['name'], $plugin['num'],
                                     $plugin['scope'], true);
            }
        }
    }
    
    /**
     *this is the meat of the application. a simple routine that calls all the
     *defined plugins in the order listed in the config file. it starts with
     *the plugins defined for the section requested (userConfig), then continues
     *with those from the <globals> section of the configuration file, and
     *finally those that are not in a sub-branch of the config file.
     */
    public function executePlugins() {
        /**
         *check if a <plugin> declaration has been made for this section
         */
        if (   !$this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']")
            || !$this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']/plugin")
            || !$this->_config->xpath('/crimp/plugin') ) {
            FAIL('You forgot to add at least one <plugin> section for this url.');
            return;
        }
        
        if ( $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']")
            && $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']/plugin") )
            $this->doPluginsFromXpath("/crimp/section[@name='{$this->userConfig()}']/plugin", SCOPE_SECTION);
        
        if ( $this->_config->xpath('/crimp/plugin') )
            $this->doPluginsFromXpath('/crimp/plugin', SCOPE_CRIMP);
    }
    
    protected function doPluginsFromXpath($xpath, $scope) {
        foreach ( $this->_config->xpath($xpath) as $plugin ) {
            if ( $plugin['name'] ) {
                $plugName = (string) $plugin['name'];
                
                if (!isset($this->executedPlugins[$scope][$plugName]))
                    $this->executedPlugins[$scope][$plugName] = 0;
                
                /**
                 *sanity check for instances where a plugin name may break out
                 *of the plugin directory.
                 */
                if ( !preg_match('/^[\/]*\.\.[\/]+.*$/', $plugName) ) {
                    if ( !$this->pluginLock( $plugName ) ) {
                        $this->executePlugin($plugName, $this->executedPlugins[$scope][$plugName]++,
                                             $scope, false);
                    }
                } else WARN("'$plugName' is a malformed plugin name");
            } else WARN('the plugin declaration has no "name" attribute');
        }
    }

    /**
     *complete the document and send to the browser
     */
    public function sendDocument($doDeferred = true) {
        PASS('Tidying up and exiting cleanly');
        
        $exitCode = $this->exitCode();
        
        if ( !$this->_contentType ) $this->_contentType = 'text/html';
        
        if ( $this->_contentType == 'text/html' ) {
            /**
             *make sure the _output var is filled
             */
            if ( ! $this->_output ) {
                $this->_output = $this->defaultHTMLContent;
                if ( $exitCode == HTTP_EXIT_NO_CONTENT ) $exitCode = HTTP_EXIT_OK;
            }
            
            if ($this->ajax) {
                /**
                 * Note 'AJAX200':
                 * exit code fixed to 200 for ajax. This is due to the
                 * fact that we need the javascript engine to work with the
                 * result even if it is a 404 page. If we set to 404 Exit Code,
                 * the javascript engine may decide to ignore the response
                 * thinking that it is a server error page, and not what it's
                 * expecting.
                 */
                $exitCode = 200;
            } else {
                /**
                 *apply the template
                 */
                $this->applyTemplate();
                
                /**
                 *set the title tags
                 */
                /**
                 *problem in php5.2 on my dev box: "fatal error: only variables can be passed by reference"
                 *this occurs when passing "1" to the str_ireplace() function.
                 *instead, we need to create a variable containing the value "1",
                 *and pass that instead. stupid, huh?
                 */
                $one = 1;
                $this->_output = str_ireplace('<title>', '<title>'.$this->pageTitle, $this->_output, $one);
                
                /**
                 *add headers to the actual output
                 */
                foreach ($this->htmlheaders as $header) {
                    $this->_output = str_ireplace('</head>',implode("\n",array($header,'</head>')), $this->_output, $one);
                }
                unset ($one);
                
                /**
                 *CHEAT CODES
                 */
                $version = '$Id: crimp.php,v 1.26 2007-06-01 21:57:48 diddledan Exp $';
                $this->_output = preg_replace('/<!--VERSION-->/i', $version, $this->_output);
            }
            
            $this->debug->stopTimer();
            
            /**
             *do the deferred plugin thing
             */
            if ($doDeferred) {
                $this->executeDeferredPlugins();
            }
            
            /**
             *apply the debug output
             */
            if ($exitCode >= 200 && $exitCode < 300) {
                if ($this->ajax) {
                    PASS("HTTP Exit Code: $exitCode for AJAX Response");
                } else {
                    PASS("HTTP Exit Code: $exitCode");
                }
            } else {
                WARN("HTTP Exit Code: $exitCode. This indicates a non successful transaction.");
            }
            
            if ($dbg = $this->getDebugString()) {
                $this->addContent($dbg);
            }
        }
        
        /**
         *send the http headers
         */
        $this->head($this->_contentType, $exitCode);
        
        /**
         *send the content to the browser
         */
        if (preg_match('/^on$/i', $this->Config('fullajax', SCOPE_CRIMP))) {
            $this->_output = preg_replace('/<\/body>/i', '<script type="text/javascript">resetAjaxHandlers()</script></body>', $this->_output);
        }
        echo $this->_output;
        exit;
    }
    
    protected function getDebugString() {
        if ($this->debugSwitch) {
            return $this->debug->getOutput();
        } else return;
    }
    
    protected function applyTemplate() {
        if ( !$this->_config ) { $templ = 'none'; }
        elseif ( !($templ = $this->Config('template', SCOPE_SECTION)) ) {
            $this->_output = implode("\n", array($this->defaultHTMLHeader, $this->_output, $this->defaultHTMLFooter));
            WARN('Please define a <template></template> tag in the config.xml file');
            return;
        }
        
        /**
         *if the user has explicitly turned off the template
         */
        if ( $templ == 'none' || $templ == 'off' ) {
            $this->_output = implode("\n", array($this->defaultHTMLHeader, $this->_output, $this->defaultHTMLFooter));
            PASS("$pluginName template turned off. Not applying a template");
            return;
        }
        
        /**
         *check that the template file is readable
         */
        if ( !is_file($templ) || !is_readable($templ) ) {
            WARN("$templ is not readable by this program");
            return;
        }
        
        /**
         *get the template content
         */
        if ( !($template = file_get_contents($templ)) ) {
            WARN('template file is empty');
            return;
        }
        
        $one = 1;
	    $this->_output = str_replace('@@PAGE_CONTENT@@', implode("\n", array($this->contentHeader,$this->_output,$this->contentFooter)), $template, $one);
    }

    ##### HELPER FUNCTIONS #####

    /**
     *set/get the exitCode of the application. If a value is defined, it will
     *override any previous values, and will become the code used in the final
     *HTTP header unless a subsequent call overwrites it again.
     */
    public function exitCode($code = null) {
        if ( $code ) $this->_exitCode = $code;
        return $this->_exitCode;
    }
    /**
     *set or get the Content-type currently defined for the document. this
     *should only be touched if we are going to send something other than html
     */
    public function contentType($ct = null) {
        if ( $ct ) $this->_contentType = $ct;
        return $this->_contentType;
    }
    /**
     *get or set the lock on a plugin
     */
    public function pluginLock($plugName, $lockit = false) {
        if ( !$lockit ) {
            if ( isset($this->_pluginLock[$plugName]) ) return true;
            return false;
        }

        $this->_pluginLock[$plugName] = true;
        return true;
    }
    /**
     *sets a plugin as 'deferred', ie. will halt execution now and restart
     *later, after all the other plugins have been executed.
     */
    public function setDeferral($plugName, $pluginNum, $scope) {
        PASS("adding deferral for '$plugName' in scope '$scope'");
        $this->deferredPlugins[] = array('name' => $plugName,
                                         'num' => $pluginNum,
                                         'scope' => $scope);
    }
    
    /**
     *parse the configuration file
     * - debug routines won't work here
     */
    function parseConf() {
        try {
            $xml = file_get_contents(CRIMP_HOME.'/config.xml');
        } catch (Exception $e) {
            $this->errorPage('config.xml');
        }
        try {
            $SimpleXML = new SimpleXMLElement($xml);
        } catch (Exception $e) {
            $this->errorPage('config.xml');
        }
        $this->_config = $SimpleXML;
        
        if (preg_match('/^on$/i', $this->Config('debug', SCOPE_SECTION))
            || preg_match('/^on$/i', $this->Config('debug', SCOPE_SECTION, false, false, 'switch'))) {
            $this->debugSwitch = true;
        } else {
            $this->debugSwitch = false;
        }
        
        if ( $cfg = $this->Config('debug', SCOPE_SECTION, false, false, 'mode') ) {
            $this->debugMode = $cfg;
        }
    }
    
    /**
     *get a configuration value
     */
    public function Config($key, $scope = SCOPE_SECTION, $plugin = false, $pluginNum = false, $subkey = false) {
        if ( ! $this->_config ) return false;
        
        $configVal = false;
        $blah = '';
        /**
         *if the plugin name has been given:
         */
        if ( $plugin ) {
            /**
             *this switch statement acts as a 'fallthrough'. ie. it will move
             *down to the least restrictive option and then act on all of the
             *options from there to the bottom. it will stop when any of the
             *statements below each step matches.
             */
            switch ($scope) {
                case SCOPE_SECTION:
                    if ( $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']") ) {
                        if ($this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']/plugin[@name='$plugin']")) {
                            $plugcfg = $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']/plugin[@name='$plugin']");
                            
                            if ( !$pluginNum ) {
                                $pluginNum = 0;
                            }
                            if ( isset($plugcfg[$pluginNum]) ) {
                                if ( $plugcfg[$pluginNum]->$key ) {
                                    if ($subkey !== false) {
                                        if ($plugcfg[$pluginNum]->$key->$subkey) {
                                            $configVal = (string) $retVal;
                                            break;
                                        }
                                        break;
                                    }
                                    $configVal = $plugcfg[$pluginNum]->$key;
                                    break;
                                }
                            }
                        }
                    }
                case SCOPE_CRIMP:
                default:
                    if ( $this->_config->xpath("/crimp/plugin[@name='$plugin']") ) {
                        $plugcfg = $this->_config->xpath("/crimp/plugin[@name='$plugin']");
                        if ( !$pluginNum ) {
                            $pluginNum = 0;
                        }
                        if ( isset($plugcfg[$pluginNum]) && $plugcfg[$pluginNum]->$key ) {
                            if ($subkey !== false) {
                                if ($plugcfg[$pluginNum]->$key->$subkey) {
                                    $configVal = (string) $plugcfg[$pluginNum]->$key->$subkey;
                                    break;
                                }
                                break;
                            }
                            $configVal = (string) $plugcfg[$pluginNum]->$key;
                            break;
                        }
                    }
            }
        } else {
            /**
             *if the plugin name wasn't defined we search for just the key name.
             *the difference between this and the above, is that this allows
             *fallthrough, so that if the key isn't found in the 'section' scope
             *it'll fallthrough to check the 'crimp' scope.
             */
            switch ($scope) {
                case SCOPE_SECTION:
                    if ( $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']") ) {
                        $sectcfg = $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']");
                        if ( isset($sectcfg[0]) && $sectcfg[0]->$key ) {
                            if ($subkey !== false) {
                                if ($sectcfg[0]->$key->$subkey) {
                                    $configVal = (string) $sectcfg[0]->$key->$subkey;
                                }
                                break;
                            }
                            $configVal = (string) $sectcfg[0]->$key;
                            break;
                        }
                    }
                case SCOPE_CRIMP:
                default:
                    if ( $this->_config->xpath("/crimp/$key") ) {
                        $cfg = $this->_config->xpath("/crimp/$key");
                        if ($subkey !== false) {
                            if ($cfg[0]->$subkey) {
                                $configVal = (string) $cfg[0]->$subkey;
                            }
                            break;
                        }
                        $configVal = (string) $cfg[0];
                        break;
                    }
            }
        }
        
        /**
         *we've searched for it, now return it
         */
        if ($configVal !== false) {
            PASS("Found config for key: $key (subkey: '$subkey') in scope $scope for plugin: $plugin($pluginNum)");
        } else {
            WARN("No config for key: $key (subkey: '$subkey') in scope $scope for plugin: $plugin($pluginNum)");
        }
        return $configVal;
    }
    
    /**
     *returns the calculated section name of the request
     *(may not be complete URL path)
     */
    public function userConfig() {
        return $this->_userConfig;
    }
    /**
     *return the full URL path of the request
     */
    public function HTTPRequest() {
        return $this->_HTTPRequest;
    }
    
    /**
     *get the short and long description of an HTTP exit code
     */
    function errorCode($code) {
        if ( !$this->HTTP_EXIT_CODES[$code] )
            return array($this->HTTP_EXIT_CODES['-1']['text'], $this->HTTP_EXIT_CODES['-1']['desc']);
        return array($this->HTTP_EXIT_CODES[$code]['text'], $this->HTTP_EXIT_CODES[$code]['desc']);
    }
    
    /**
     *send the appropriate headers to the browser for the content-type and
     *http exit status code
     */
    function head($contentType, $exitCode = HTTP_EXIT_OK) {
        /**
         *check that the headers have not been sent already
         */
        if ( headers_sent() ) return false;
        
        $status = ( isset($this->HTTP_EXIT_CODES[$exitCode]) ) ? $this->HTTP_EXIT_CODES[$exitCode]['text'] : 'Unknown';
        header("HTTP/1.1 $exitCode $status");
        header("Content-type: $contentType");
        
        return true;
    }
    
    /**
     *strips out everything before and after (inclusive of) the <body></body>
     *tags in the supplied html code. returns an array containing the content of
     *any <title></title> tags and the new html minus the cruft before and after
     *the <body></body> tags.
     */
    public function stripHeaderFooter($html) {
        /**
         *parse headers storing the title of the page
         */
	preg_match('|<title>(.*?)</title>|si', $html, $title);
	/**
         *remove everything down to <body>
         */
	$html = preg_replace('|.*?<body.*?>|si', '', $html);
	/**
         *remove everything after </body>
         */
	$html = preg_replace('|</body>.*|si','',$html);
        /**
         *return the title and the trimmed html content
         */
        return array($title[1], $html);
    }
    
    /**
     *read the contents of a file or returns an error document explaining that
     *the file was unavailable.
     */
    public function pageRead($file) {
        PASS("pageRead(): File: $file");
        
        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        
        WARN('File is either non-existant or unreadable (permissions?)');
        
        $this->errorPage('PageRead', 404);
        return false;
    }
    
    
    
    /**
     * plugin execution
     */
    protected function executePlugin($plugName, $pluginNum, $scope, $deferred = false) {
        $file = CRIMP_HOME."/plugins/$plugName/plugin.php";
        if ( file_exists($file) || is_readable($file) ) {
            $this->executePHPPlugin($file, $plugName, $pluginNum, $scope, $deferred);
            return;
        }
        
        $file = CRIMP_HOME."/plugins/$plugName/plugin.pm";
        if ( file_exists($file) || is_readable($file) ) {
            $this->executePerlPlugin($file, $plugName, $pluginNum, $scope, $deferred);
            return;
        }
        
        WARN("Plugin file for '$plugName' inaccessible, or plugin type unsupported by this version of CRIMP.");
    }
    
    protected function executePHPPlugin($file, $plugName, $pluginNum, $scope, $deferred = false) {
        if (!include_once($file)) {
            WARN("Could not include($file)");
            return;
        }
        
        if (!$newplugin = new $plugName( )) {
            WARN("Failed to instantiate an object for plugin '$plugName' class");
            return;
        }
        
        $newplugin->setup( $scope,
                           $pluginNum,
                           $deferred );
        
        PASS("Calling '$plugName' plugin");
        $newplugin->execute();
    }
}

?>
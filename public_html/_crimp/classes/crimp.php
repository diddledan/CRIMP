<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: crimp.php,v 1.30 2007-08-22 12:38:49 diddledan Exp $
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
define('MAX_SCOPE_VALUE',       SCOPE_SECTION);

/**
 *debug routines
 */
require_once('PHP/Debug.php');

/**
 *negotiate language
 */
require_once('HTTP.php');

/**
 *plugin architecture
 */
require_once('plugin.php');

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
        '<link rel="stylesheet" type="text/css" href="/crimp_assets/debug/css/html_div.css" />',
        '<link rel="stylesheet" type="text/css" href="/crimp_assets/debug/css/html_table.css" />',
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

    public $_config = false;
    protected $varDir;
    protected $errorDir = './_crimp/errordocs/';
    protected $defaultLang = 'en';
    public $friendlyUrls;
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
    protected $debug = false;
    protected $debugSwitch = true;

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
        $this->debug = new PHP_Debug(array('render_type' => 'HTML',
                                           'render_mode' => 'Table',
                                           'replace_errorhandler' => true,
                                           'HTML_DIV_images_path' => '/crimp_assets/debug/images',
                                           'HTML_DIV_css_path' => '/crimp_assets/debug/css',
                                           'HTML_DIV_js_path' => '/crimp_assets/debug/js',
                                           'HTML_TABLE_css_path' => '/crimp_assets/debug/css'));
        if (isset($_GET['crimpq'])) {
            $this->_HTTPRequest = $_GET['crimpq'];
        }
        unset($_GET['crimpq']);

        if (isset($_POST['crimpPostback']) && isset($_POST['crimpURL']) && ($_POST['crimpURL'] != '')) {
            $this->_HTTPRequest = urldecode($_POST['crimpURL']);
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

        /**
         *stuff imported from the setup() function
         */
        $this->parseConf();
        $this->parseUserConfig();
        if (preg_match('/^on$/i', $this->Config('debug', SCOPE_SECTION, false, false, 'switch'))) {
            $this->debugSwitch = true;
        } else {
            $this->debugSwitch = false;
        }

        if (!$dbgtype = $this->Config('debug',SCOPE_SECTION,false,false,'type')) {
            $dbgtype = 'HTML';
        }
        if (!$dbgmode = $this->Config('debug',SCOPE_SECTION,false,false,'mode')) {
            $dbgmode = 'Div';
        }
        $this->DebugMode($dbgtype,$dbgmode);
        $this->applyConfig();

        $this->remoteHost           = isset($_ENV['REMOTE_ADDR'])?$_ENV['REMOTE_ADDR']:'unset';
        $this->serverName           = isset($_ENV['SERVER_NAME'])?$_ENV['SERVER_NAME']:'unset';
        $this->serverSoftware       = isset($_ENV['SERVER_SOFTWARE'])?$_ENV['SERVER_SOFTWARE']:'unset';
        $this->serverProtocol       = isset($_ENV['SERVER_PROTOCOL'])?$_ENV['SERVER_PROTOCOL']:'unset';
        $this->userAgent            = isset($_ENV['HTTP_USER_AGENT'])?$_ENV['HTTP_USER_AGENT']:'unset';

        define('REMOTE_HOST',       $this->remoteHost);
        define('SERVER_NAME',       $this->serverName);
        define('SERVER_SOFTWARE',   $this->serverSoftware);
        define('PROTOCOL',          $this->serverProtocol);
        define('USER_AGENT',        $this->userAgent);
        define('HTTP_REQUEST',      $this->_HTTPRequest);

        $this->PASS("Remote Host: {$this->remoteHost}
Server Name: {$this->serverName}
Server Software: {$this->serverSoftware}
User Agent: {$this->userAgent}
Requested Document: {$this->_HTTPRequest}
UserConfig: {$this->_userConfig}");
    }

    public function PASS($message) {
        if ($this->debug) {
            $this->debug->add($message);
        }
    }
    public function WARN($message) {
        if ($this->debug) {
            $this->debug->add($message, PHP_DebugLine::TYPE_WARNING);
        }
    }
    public function FAIL($message) {
        if ($this->debug) {
            $this->debug->error($message);
        }
    }
    public function DUMP($variable, $varname = '') {
        if ($this->debug) {
            $this->debug->dump($variable, $varname);
        }
    }
    public function StopTimer() {
        if ($this->debug) {
            $this->debug->stopTimer();
        }
    }

    /**
     *run
     */
    public function run() {
        $this->executePlugins();
        $this->sendDocument();
    }

    /**
     *parse the configuration to set some values
     */
    private function applyConfig() {
        $this->errorDir     = ( $cfg = $this->Config('errordir', SCOPE_CRIMP) ) ? $cfg : CRIMP_HOME.'/errordocs';
        define('ERROR_DIR', $this->errorDir);
        $this->varDir       = ( $cfg = $this->Config('vardir', SCOPE_CRIMP) ) ? $cfg : CRIMP_HOME.'/var';
        define('VAR_DIR', $this->varDir);
        $this->defaultLang  = ( $cfg = $this->Config('defaultlanguage', SCOPE_SECTION) ) ? $cfg : 'en';
        define('DEFAULT_LANG', $this->defaultLang);
        $this->setTitle( ( $cfg = $this->Config('title', SCOPE_SECTION) ) ? $cfg : '', true );

        $this->friendlyUrls = (preg_match('/^\s*on\s*$/i', $this->Config('friendlyUrls', SCOPE_CRIMP))) ? 'on' : 'off';
        $this->PASS("Frienly URL System is turned {$this->friendlyUrls}");
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
            if ( $this->_config->xpath("/crimp/section[@baseuri='$tmpstr']") )
                $userConfig = $tmpstr;
        }

        $this->_userConfig = ($userConfig) ? $userConfig : '/';
    }

    /**
     *set the document's title for inclusion in the <title></title> tags
     */
    public function setTitle($title, $overwrite = false) {
        if ( $overwrite ) {
            $this->PASS("setTitle(): Overwriting page title with '$title'");
            $this->pageTitle = $title;
        } else {
            $sep = ' - ';
            if ( $conf = $this->Config('titleseparator', SCOPE_SECTION) ) $sep = $conf;

            $cur = $this->pageTitle;
            $this->PASS("setTitle(): Adding '$title' to page title");
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
        $this->PASS("Adding content ($loc)");

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

        StopTimer();
    }

    /**
     *add content to the menu which appears above the page content,
     *eg. for fileList plugin
     */
    public function addMenu($menu, $location = 'last') {
        if ( ($location == 'first') ) {
            $this->PASS('Adding MenuContent (top)');
            $this->_output = preg_replace('|<!--startMenuContent-->|i', "$0\n$menu<br />\n", $this->_output);
	} else {
            $this->PASS('Adding MenuContent (bottom)');
            $this->_output = preg_replace('|<!--endMenuContent-->|i', "<br />\n$menu\n$0", $this->_output);
        }
    }

    /**
     *add a new header for inclusion into the final html document
     */
    public function addHeader($header) {
        $this->PASS("addHeader(): adding html header:\n$header");
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
        $this->PASS("errorPage(): package: $package; errorCondition: $errorCode");

        $languages = array();
        $errordir = $this->errorDir;
        if ( $dir = @opendir($errordir) ) {
            while ( ($file = readdir($dir)) !== false ) if ($file != "." && $file != "..") {
                if ( is_dir("$errordir/$file") ) $languages[$file] = true;
            }
            closedir($dir);unset($file, $dir);
        }

        $defLang = $this->defaultLang;
        $clientLang = HTTP::negotiateLanguage($languages, $defLang);

        if ( isset($_COOKIE['preferred_language']) ) $clientLang = $_COOKIE['preferred_language'];

        $errorFiles = array();
        if ( $clientLang ) { array_push($errorFiles, "$errordir/$clientLang/$errorCode-$package.html"); }
        if ( $defLang && $defLang != $clientLang ) { array_push($errorFiles, "$errordir/$deflang/$errorCode-$package.html"); }

	if ( $clientLang ) { array_push($errorFiles, "$errordir/$clientLang/$errorCode.html"); }
	if ( $defLang && $defLang != $clientLang ) { array_push($errorFiles, "$errordir/$deflang/$errorCode.html"); }
        unset($errordir, $clientLang, $deflang);

        $content = false;
        foreach ( $errorFiles as $file ) {
            if ( file_exists($file) ) {
            	$ret = $this->stripHeaderFooter($this->pageRead($file));
            	$title = $ret[0];
            	$content = $ret[1];
            	unset ( $ret );
            	break;
            }
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
<p>$errorDescription (Package: $package)</p>
<p>Additionally, a 404: Not Found error was encountered while trying to use a 'friendly' error document for this request.</p>
";
        }

	StopTimer();
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
            $this->PASS("Executing deferred plugins...");
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
        if (   !$this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']/plugin")
            && !$this->_config->xpath('/crimp/plugin') ) {
            FAIL('You forgot to add at least one <plugin> section for this url.');
            return;
        }

        if ( $this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']/plugin") )
            $this->doPluginsFromXpath("/crimp/section[@baseuri='{$this->userConfig()}']/plugin", SCOPE_SECTION);

        if ( $this->_config->xpath('/crimp/plugin') )
            $this->doPluginsFromXpath('/crimp/plugin', SCOPE_CRIMP);
    }

    protected function doPluginsFromXpath($xpath, $scope) {
        foreach ( $this->_config->xpath($xpath) as $plugin ) {
            if ( $plugin->name ) {
                $plugName = (string) $plugin->name;

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
                } else $this->WARN("'$plugName' is a malformed plugin name");
            } else {
                DUMP($plugin, 'No "name" attribute');
            }
        }
    }

    /**
     *complete the document and send to the browser
     */
    public function sendDocument($doDeferred = true) {
        $this->PASS('Tidying up and exiting cleanly');

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
                $version = '$Id: crimp.php,v 1.30 2007-08-22 12:38:49 diddledan Exp $';
                $this->_output = preg_replace('/<!--VERSION-->/i', $version, $this->_output);
            }

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
                    $this->PASS("HTTP Exit Code: $exitCode for AJAX Response");
                } else {
                    $this->PASS("HTTP Exit Code: $exitCode");
                }
            } else {
                $this->WARN("HTTP Exit Code: $exitCode. This indicates a non successful transaction.");
            }

            if (preg_match('/^on$/i', $this->Config('fullajax', SCOPE_CRIMP))) {
                $this->_output = preg_replace('/<\/body>/i', '<script type="text/javascript">resetAjaxHandlers()</script></body>', $this->_output);
            }

            if ($dbg = $this->getDebugString()) {
                $this->addContent($dbg);
            }
        }

        /**
         *send the http headers
         */
        $this->head($this->_contentType, 200);

        /**
         *send the content to the browser
         */
        echo $this->_output;
        exit;
    }

    protected function getDebugString() {
        if ($this->debugSwitch && $this->debug) {
            return $this->debug->getOutput();
        }
        return;
    }

    protected function applyTemplate() {
        $templ = $this->Config('template', SCOPE_SECTION);
        if ( !isset($templ) || !$templ ) {
            $this->_output = implode("\n", array($this->defaultHTMLHeader, $this->_output, $this->defaultHTMLFooter));
            $this->WARN('No template configuration value was found in runtime configuration. Check Config.xml file.');
            return;
        }

        /**
         *if the user has explicitly turned off the template
         */
        if ( $templ == 'none' || $templ == 'off' ) {
            $this->_output = implode("\n", array($this->defaultHTMLHeader, $this->_output, $this->defaultHTMLFooter));
            $this->PASS("Template turned off. Not applying a template");
            return;
        }

        /**
         *check that the template file is readable
         */
        if ( !is_file($templ) || !is_readable($templ) ) {
            $this->WARN("$templ is not readable by this program");
            return;
        }

        /**
         *get the template content
         */
        if ( !($template = file_get_contents($templ)) ) {
            $this->WARN('template file is empty');
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
        $this->PASS("adding deferral for '$plugName' in scope '$scope'");
        $this->deferredPlugins[] = array('name' => $plugName,
                                         'num' => $pluginNum,
                                         'scope' => $scope);
    }

    /**
     *update the debugmode setting
     *
     * @param $type string  the class of render mode
     * @param $mode string  the render mode of the class chosen
     *
     * @see _crimp/classes/PHP/Debug.php $defaultOptions array
     */
    function DebugMode($type = 'HTML', $mode = 'Div') {
        $this->debug->updateOptions(array('render_type' => $type,
                                          'render_mode' => $mode));
    }
    /**
     *parse the configuration file
     * - debug routines won't work here
     */
    function parseConf() {
        try {
            $xml = @file_get_contents(CRIMP_HOME.'/config.xml');
        } catch (Exception $e) {
            $this->errorPage('Config.xml');
        }
        try {
            $SimpleXML = new SimpleXMLElement($xml);
        } catch (Exception $e) {
            $this->errorPage('Config.xml');
        }
        $this->_config = $SimpleXML;
    }

    /**
     *get a configuration value
     */
    public function Config($key, $scope = SCOPE_SECTION, $plugin = false, $pluginNum = false, $subkey = false) {
        if ( ! $this->_config ) { return false; }

        $configVal = false;
        /**
         *TODO: does this next variable actually do anything???? it certainly isn't named very well
         */
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
                    if ( $this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']") ) {
                        if ($this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']/plugin")) {
                            $plugs = $this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']/plugin");

                            $plugcfg = array();
                            foreach ($plugs as $plug) {
                                if ((string) $plug->name == $plugin) {
                                    $plugcfg[] = $plug;
                                }
                            }

                            if ( !$pluginNum ) $pluginNum = 0;
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
                    if ( $this->_config->xpath("/crimp/plugin") ) {
                        $plugs = $this->_config->xpath("/crimp/plugin");

                        $plugcfg = array();
                    	foreach ($plugs as $plug) {
                            if ((string) $plug->name == $plugin) {
                                $plugcfg[] = $plug;
                            }
			}

                        if ( !$pluginNum ) $pluginNum = 0;
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
                    if ( $this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']") ) {
                        $sectcfg = $this->_config->xpath("/crimp/section[@baseuri='{$this->userConfig()}']");
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
            $this->PASS("Found config for key: $key (subkey: '$subkey') in scope (see definitions at top of crimp.php) $scope for plugin: $plugin($pluginNum)");
        } else {
            $this->WARN("No config for key: $key (subkey: '$subkey') in scope (see definitions at top of crimp.php) $scope for plugin: $plugin($pluginNum)");
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
        $this->PASS("pageRead(): File: $file");

        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);

        $this->WARN('File is either non-existant or unreadable (permissions?)');

        $this->errorPage('PageRead', 404);
        return false;
    }

    /**
	 * create links (taking into account friendlyUrls setting)
	 */
	public function makeLink($link) {
		return ($this->friendlyUrls == 'on') ? $link : './index.php?crimpq='.urlencode($link);
	}


    /**
     * plugin execution
     */
    protected function executePlugin($plugName, $pluginNum, $scope, $deferred = false) {
        $file = CRIMP_HOME."/plugins/$plugName/plugin";
        if ( file_exists("$file.php") && is_readable("$file.php")) {
			if (!include_once("$file.php")) {
				$this->WARN("Could not include($file.php)");
				return;
	        }

			if (!$newplugin = new $plugName()) {
				$this->WARN("Failed to instantiate an object for plugin '$plugName' class");
				return;
			}

			$newplugin->setup( $scope,
				               $pluginNum,
				               $deferred );

			$this->PASS("Calling '$plugName' plugin");
			$newplugin->execute();
			return;
		}

        if ( !file_exists($file) || !is_readable($file) ) {
            $this->WARN("Plugin file for '$plugName' inaccessible");
            return;
        }

        $proc = proc_open(CRIMP_HOME."/plugins/$pluginName/$file", $descriptorspec, $pipes, CRIMP_HOME);

        if ( !is_resource($proc) ) {
            $this->WARN('could not spawn perl-php-wrapper.pl');
            return;
        }

        fwrite($pipes[0], $postquery);
        while (!feof($pipes[1])) {
            $xml = stream_get_line($pipes[1], 1000000000, '</crimprequests>');
            $xml .= '</crimprequests>';

            try {
                $SimpleXML = new SimpleXMLElement($xml);
            } catch(Exception $ex) {
                $this->WARN("Failed to read xml config data from perl plugin: $ex");
                continue;
            }

            $xml = '<crimpresults></crimpresults>';
            $resultset = new SimpleXMLElement($xml);

            foreach($SimpleXML->request as $request) {
				$xml = '<crimpresult></crimpresult>';
				$resXML = new SimpleXMLElement($xml);

                if ($request->type) {
					$reqPluginName	= ($request->pluginName)	? (string) $request->pluginName	: '';
                    $reqPluginNum	= ($request->pluginNum)		? (int) $request->pluginNum		: 0;
                    $reqScope		= ($request->scope)			? (int) $request->scope			: 0;

                    $resXML->addChild('type', (string) $request->type);
                    $resXML->addChild('pluginName', $reqPluginName);
					$resXML->addChild('pluginNum', $reqPluginNum);
					$resXML->addChild('scope', $reqScope);

                    switch ((string) $request->type) {
                        case 'Config':
                            $reqKey		= ($request->key)		? (string) $request->key	: '';
                            $reqSubkey	= ($request->subkey)	? (string) $request->subkey	: '';

                            $cfgres = $crimp->Config($reqKey, $reqScope, $reqPluginName, $reqPluginNum, $reqSubkey);

                            $resXML->addChild('key', $reqKey);
                            $resXML->addChild('subkey', $reqSubkey);
                            $resXML->addChild('data', $cfgres);
                            break;
                        case 'PageRead':
							$reqFile = ($request->file) ? (string) $request->file : '';
							$resXML->addChild('file', $reqFile);
							$resXML->addChild('data', $this->PageRead($reqFile));
							break;
						case 'Defer':
							$this->setDeferral($reqPluginName, $reqPluginNum, $reqScope);
							$resXML->addChild('data', 'done');
							break;
						case 'MakeLink':
							$link = $this->makeLink((string) $request->url);
							$resXML->addChild('url', (string) $request->url);
							$resXML->addChild('data', $link);
							break;
						case 'ErrorCode':
							$resXML->addChild('code', (int) $request->code);
							$code = $this->errorCode((int) $request->code);
							$resXML->addChild('ErrName', $code[0]);
							$resXML->addChild('data', $code[1]);
							break;
						case 'HTTPRequest':
							$resXML->addChild('data', $this->HTTPRequest());
							break;
                        default:
							$resXML->addChild('error', 'Action type unsupported');
                    }
                } else {
					$resXML->addChild('error', 'No Action Type specified');
				}
				$resultset->addChild($resXML);
            }

            fputs($pipes[0], $resultset->asXML());
        }
        fclose($pipes[1]);
        fclose($pipes[0]);
        $retval = proc_close($proc);

        $level = ( $retval == 0 ) ? PASS : WARN;

        $level("Plugin subprocess returned $retval");
    }
}

?>
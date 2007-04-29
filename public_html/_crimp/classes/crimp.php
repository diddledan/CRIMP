<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: crimp.php,v 1.14 2007-04-29 20:37:32 diddledan Exp $
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
 *crimp specific debug constants
 */
define('INFO',                      PHP_DEBUGLINE_STD);
define('PASS',                      PHP_DEBUGLINE_PASS);
define('WARN',                      PHP_DEBUGLINE_WARN);
define('FAIL',                      PHP_DEBUGLINE_FAIL);

/**
 *CRIMP's main class
 */
class Crimp {
    /**
     *this is for all the content that will be sent to the user's browser
     *upon completion of execution of all plugins.
     */
    public $_output;
    /**
     *html headers like <meta /> tags, <script></script> tags and etc.
     */
    protected $_headers;
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
    protected $debugMode = 'inline';
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
    public $debug;
    public $defaultHTML = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
</head>
<body>
<!--startMenuContent-->
<!--endMenuContent-->
<!--startPageContent-->
<!--endPageContent-->
</body>
</html>';
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
     *constructor
     */
    function __construct() {
        $this->debug = new PHP_Debug;
        $this->parseConf();

        $this->_output              = $this->defaultHTML;
        $this->remoteHost           = $_ENV['REMOTE_ADDR'];
        $this->serverName           = $_ENV['SERVER_NAME'];
        $this->serverSoftware       = $_ENV['SERVER_SOFTWARE'];
        $this->serverProtocol       = $_ENV['SERVER_PROTOCOL'];
        $this->userAgent            = $_ENV['HTTP_USER_AGENT'];
        $this->_HTTPRequest         = preg_replace('|/+|', '/', '/'.urldecode($_GET['crimpq']));

        unset ($_GET['crimpq']);

        define('REMOTE_HOST',       $this->remoteHost);
        define('SERVER_NAME',       $this->serverName);
        define('SERVER_SOFTWARE',   $this->serverSoftware);
        define('PROTOCOL',          $this->serverProtocol);
        define('USER_AGENT',        $this->userAgent);
        define('HTTP_REQUEST',      $this->_HTTPRequest);

        $this->debug->addDebug("Remote Host: {$this->remoteHost}
Server Name: {$this->serverName}
Server Software: {$this->serverSoftware}
User Agent: {$this->userAgent}
Requested Document: {$this->_HTTPRequest}", PASS);

        $this->applyConfig();
        $this->parseUserConfig();
        /**
         *initialise the executedPlugins array of arrays
         */
        for($i = 0; $i <= MAX_SCOPE_VALUE; $i++) $this->executedPlugins[$i] = array();
        $this->pluginSystem = new crimpPlugins($this);
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
        $this->defaultLang  = ( $cfg = $this->Config('defaultlanguage', SCOPE_CRIMP) ) ? $cfg : 'en';
        define('DEFAULT_LANG', $this->defaultLang);
        $this->setTitle( ( $cfg = $this->Config('sitetitle', SCOPE_CRIMP) ) ? $cfg : '', true );
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
        $req = explode('/', $this->_HTTPRequest);
        foreach( $req as $_ ) {
            if ( $_ ) $tmpstr = "$tmpstr/$_";
            //if ( [$tmpstr]) )
                $userConfig = $tmpstr;
        }

        if ( !$userConfig ) $userConfig = '/';
        $this->_userConfig = $userConfig;

        $this->debug->addDebug('UserConfig: '.$this->_userConfig, PASS);
    }

    /**
     *set the document's title for inclusion in the <title></title> tags
     */
    public function setTitle($title, $overwrite = false) {
        if ( $overwrite ) {
            $this->debug->addDebug("setTitle(): Overwriting page title with '$title'", PASS);
            $this->pageTitle = $title;
        }
        else {
            $sep = ' - ';
            if ( $conf = $this->Config('titleseparator', SCOPE_CRIMP) ) $sep = $conf;

            $cur = $this->pageTitle;
            $this->debug->addDebug("setTitle(): Adding '$title' to page title", PASS);
            $this->pageTitle = ( $this->Config('titleorder', SCOPE_CRIMP) == 'forward' )
                ? "$cur$sep$title" : "$title$sep$cur";
        }
    }

    /**
     *add content to the html page
     */
    public function addContent($htmlcontent, $location = 'bottom') {
        $br = "\n<br />\n";

        if ( !$this->_output || $this->_output == $this->defaultHTML ) {
            $this->debug->addDebug('addContent(): creating initial page', PASS);
            $this->_output = $this->defaultHTML;
            $location = 'top';
            $br = '';
        } elseif ( $location === true ) {
            $this->debug->addDebug('addContent(): OVERWRITING page', PASS);
            $this->_output = $this->defaultHTML;
            $location = 'top';
            $br = '';
        }

        if ( $location == 'top' ) {
            $this->debug->addDebug('addContent(): adding to the TOP of the page', PASS);
            $this->_output = preg_replace('/(<!--startPageContent-->)/',"$1$htmlcontent$br",$this->_output);
        } else {
            $this->debug->addDebug('addContent(): adding to the BOTTOM of the page', PASS);
            $this->_output = preg_replace('/(<!--endPageContent-->)/',"$br$htmlcontent$1",$this->_output);
        }
    }

    /**
     *add content to the menu which appears above the page content,
     *eg. for fileList plugin
     */
    public function addMenu($menu, $location = 'last') {
        if ( ($location == 'first') ) {
	    $this->debug->addDebug('Adding MenuContent (top)', PASS);
	    $this->_output = preg_replace('|<!--startMenuContent-->|i', "$0\n$menu<br />\n", $this->_output);
	} else {
	    $this->debug->addDebug('Adding MenuContent (bottom)', PASS);
            $this->_output = preg_replace('|<!--endMenuContent-->|i', "<br />\n$menu\n$0", $this->_output);
        }
    }

    /**
     *add a new header for inclusion into the final html document
     */
    public function addHeader($header) {
        $this->debug->addDebug("addHeader(): adding html header:\n$header", PASS);
        $this->_headers = implode("\n", array($this->_headers, $header));
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
        $this->debug->addDebug("errorPage(): package: $package; errorCondition: $errorCode", PASS);

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

        $this->addContent($content, true);
        $this->setTitle($title, true);
        $this->_exitCode = $errorCode;
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
        foreach ( $this->deferredPlugins as $plugin ) {
            $this->pluginSystem->execute($plugin['name'], $plugin['num'],
                                         CRIMP_HOME."/plugins/{$plugin['name']}.php",
                                         $plugin['scope'], true);
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
            $this->debug->addDebug('You forgot to add at least one <plugin> section for this url.', FAIL);
            return;
        }
        
        if ( $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']")
            && $this->_config->xpath("/crimp/section[@name='{$this->userConfig()}']/plugin") )
            $this->doPluginsFromXpath("/crimp/section[@name='{$this->userConfig()}']/plugin", SCOPE_SECTION);
        
        if ( $this->_config->xpath('/crimp/plugin') )
            $this->doPluginsFromXpath('/crimp/plugin', SCOPE_CRIMP);
    }
    
    private function doPluginsFromXpath($xpath, $scope) {
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
                        $this->pluginSystem->execute($plugName, $this->executedPlugins[$scope][$plugName]++,
                                                     CRIMP_HOME."/plugins/$plugName.php",
                                                     $scope, false);
                    }
                } else $this->debug->addDebug("'$plugName' is a malformed plugin name", WARN);
            } else $this->debug->addDebug('the plugin declaration has no "name" attribute', WARN);
        }
    }

    /**
     *complete the document and send to the browser
     */
    public function sendDocument($doDeferred = true) {
        $this->debug->addDebug('Tidying up and exiting cleanly', PASS);

        $exitCode = $this->_exitCode;

        if ( $this->_output && $exitCode == HTTP_EXIT_NO_CONTENT ) $exitCode = HTTP_EXIT_OK;
        if ( !$this->_contentType ) $this->_contentType = 'text/html';

        if ( $this->_contentType == 'text/html' ) {
            /**
             *add headers
             */
            if ( $this->debugMode == 'javascript' )
                $this->addHeader('<link rel="stylesheet" type="text/css" href="/crimp_assets/debug-hidden.css" />');
            $this->addHeader('<link rel="stylesheet" type="text/css" href="/crimp_assets/debug.css" />');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/prototype/prototype.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/moo/moo.fx.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/moo/moo.fx.pack.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/debug.js"></script>');
            
            /**
             *make sure the _output var is filled
             */
            if ( ! $this->_output ) { $this->_output = $this->defaultHTML; }

            /**
             *apply the template
             */
            $this->applyTemplate();

            /**
             *do the deferred plugin thing now that the template has been applied
             */
            if ($doDeferred && is_array($this->deferredPlugins)) $this->executeDeferredPlugins();

            /**
             *set the title tags
             */
            $title = $this->pageTitle;
            $this->_output = preg_replace('/(<title>)/i',"$1$title", $this->_output, 1);

            /**
             *add headers to the actual output
             */
            $headers = $this->_headers;
            $this->_output = preg_replace('|(</head>)|i',"$headers\n$1", $this->_output, 1);

            /**
             *apply the debug output
             */
            $cruft = '';
            if (399 < $exitCode || $exitCode < 200) $cruft = 'This exit code is outside the range 200-399, which indicates something amiss. Check the rest of this debug statement for information on what may have gone wrong.';
            $this->debug->addDebug("HTTP Exit Code: $exitCode. $cruft",PASS);
            unset($cruft);
            $debugString = $this->stripHeaderFooter($this->debug->getDisplay());
            $this->_output = preg_replace('|(</body>)|i', "{$debugString[1]}$1", $this->_output, 1);

            /**
             *CHEAT CODES
             */
            $ver = '$Id: crimp.php,v 1.14 2007-04-29 20:37:32 diddledan Exp $';
            $this->_output = preg_replace('/<!--VERSION-->/i', $ver, $this->_output);
        }

        /**
         *send the http headers
         */
        $this->head($this->_contentType, $exitCode);

        /**
         *send the content to the browser
         */
        echo $this->_output;
        exit;
    }

    protected function applyTemplate() {
        if ( !$this->_config ) { $templ = 'none'; }
        elseif ( !($templ = $this->Config('template', SCOPE_SECTION)) ) {
            $this->debug->addDebug('Please define a <template></template> tag in the config.xml file', WARN);
            return;
        }

        /**
         *if the user has explicitly turned off the template
         */
        if ( $templ == 'none' || $templ == 'off' ) {
            $this->debug->addDebug("$pluginName turned off. Not applying a template", PASS);
            return;
        }

        /**
         *check the content-type: we don't want to mess up an image stream,
         *for instance.
         */
        $ct = $this->contentType();
        if ( ($ct != 'text/html') && ($ct != 'text/xhtml+xml') ) {
	    $this->debug->addDebug("Skipped applying template for ContentType: $ct");
	    return;
	}

        /**
         *check that the template file is readable
         */
        if ( !is_file($templ) || !is_readable($templ) ) {
            $this->debug->addDebug("$templ is not readable by this program", WARN);
            return;
        }

        /**
         *get the template content
         */
        if ( !($template = file_get_contents($templ)) ) {
            $this->debug->addDebug('template file is empty', WARN);
            return;
        }

        list($null,$content) = $this->stripHeaderFooter($this->_output);
	$this->_output = preg_replace('/@@PAGE_CONTENT@@/', $content, $template);
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
        $this->debug->addDebug("adding deferral for '$plugName' in scope '$scope'", PASS);
        $this->deferredPlugins[] = array('name' => $plugName,
                                         'num' => $pluginNum,
                                         'scope' => $scope);
    }
    
    /**
     *parse the configuration file
     */
    function parseConf() {
        try {
            $xml = file_get_contents('config.xml');
        } catch (Exception $e) {
            $this->debug->add($e, FAIL);
            $this->errorPage('crimp');
        }
        $SimpleXML = new SimpleXMLElement($xml);
        $this->_config = $SimpleXML;
    }

    /**
     *get a configuration value
     */
    public function Config($key, $scope = SCOPE_SECTION, $plugin = false, $pluginNum = false) {
        $cfg = $this->Config2($key, $scope, $plugin, $pluginNum);
        if (!$cfg) {
            $this->debug->add("nothing configured for\nkey:$key,\nscope:$scope,\nplugin:$plugin,\npluginNum:$pluginNum", INFO);
            return;
        } else {
            $this->debug->add("configuration found for\nkey:$key,\nscope:$scope,\nplugin:$plugin,\npluginNum:$pluginNum", INFO);
            return $cfg;
        }
    }
    protected function Config2($key, $scope = SCOPE_SECTION, $plugin = false, $pluginNum = false) {
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
                            if ( $pluginNum && isset($plugcfg[$pluginNum]) && $plugcfg[$pluginNum]->$key )
                                return $plugcfg[$pluginNum]->$key;
                            else if ($plugcfg[0]->$key) return (string) $plugcfg[0]->$key;
                        }
                    }
                    break;
                case SCOPE_CRIMP:
                    if ( $this->_config->xpath("/crimp/plugin[@name='$plugin']") ) {
                        $plugcfg = $this->_config->xpath("/crimp/plugin[@name='$plugin']");
                        if ( isset($plugcfg[$pluginNum]) && $plugcfg[$pluginNum]->$key )
                            return $plugcfg[$pluginNum]->$key;
                        else if ($plugcfg[0]->$key) return (string) $plugcfg[0]->$key;
                    }
                    break;
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
                        if ( isset($sectcfg[0]) && $sectcfg[0]->$key )
                            return (string) $sectcfg[0]->$key;
                    }
                case SCOPE_CRIMP:
                default:
                    if ( $this->_config->xpath("/crimp/$key") ) {
                        $cfg = $this->_config->xpath("/crimp/$key");
                        return $cfg[0];
                    }
            }
        }

        /**
         *we've searched for it, now return false to indicate that the config
         *value was not found
         */
        return false;
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
        $this->debug->addDebug("pageRead(): File: $file", PASS);

        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        else $this->debug->addDebug('File is either non-existant or unreadable (permissions?)', WARN);
        
        $ecode = HTTP_EXIT_NOT_FOUND;
        $desc = $this->HTTP_EXIT_CODES[$ecode];

        $file = ERRORDIR."/$ecode.html";
        $crimp->exitCode($ecode);

        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        else $this->debug->addDebug("Error page file is either non-existant or unreadable (permissions?)\nFilename: $file", WARN);

        $newhtml = <<<EOF
<h1>$ecode - $desc</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
EOF;

        $PageContent = $crimp->defaultHTML;
        $PageContent = preg_replace('/(<body>)/i', "$1$newhtml", $PageContent);
        $PageContent = preg_replace('/(<title>)/i', "$1$ecode - $desc", $PageContent);
        return $PageContent;
    }
}

?>

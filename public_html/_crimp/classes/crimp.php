<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: crimp.php,v 1.9 2006-12-15 12:22:06 diddledan Exp $
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

define('HTTP_EXIT_OK',          '200');
define('HTTP_EXIT_NO_CONTENT',  '204');
define('HTTP_EXIT_FORBIDDEN',   '403');
define('HTTP_EXIT_NOT_FOUND',   '404');
define('HTTP_EXIT_SERVER_ERROR','500');

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
    /**
     *array containing the configuration file in an indexed form
     */
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
        $this->_output = $this->defaultHTML;

        $this->debug = new Debug;
        $config = new crimpConf;
        if ( ! $config ) {
            $dbg->addDebug("Configuration Parser failed to read the configuration:<br />&nbsp;&nbsp;&nbsp;&nbsp;{$this->root->getMessage()}", FAIL);
            $dbg->render();
            die();
        }

        $this->_config = $config->get();
        unset ($config);

        $this->remoteHost           = $_ENV['REMOTE_ADDR'];
        $this->serverName           = $_ENV['SERVER_NAME'];
        $this->serverSoftware       = $_ENV['SERVER_SOFTWARE'];
        $this->serverProtocol       = $_ENV['SERVER_PROTOCOL'];
        $this->userAgent            = $_ENV['HTTP_USER_AGENT'];
        $this->_HTTPRequest         = urldecode($_GET['crimpq']);
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
        $this->pluginSystem = new crimpPlugins($this);
    }

    /**
     *parse the configuration to set some values
     */
    private function applyConfig() {
        $this->errorDir     = ( $this->Config('errordir', SCOPE_GLOBALS) ) ? $this->Config('errordir', SCOPE_GLOBALS) : CRIMP_HOME.'/errordocs';
        define('ERROR_DIR', $this->errorDir);
        $this->templateDir  = ( $this->Config('templatedir', SCOPE_GLOBALS) ) ? $this->Config('templatedir', SCOPE_GLOBALS) : CRIMP_HOME.'/templates';
        define('TEMPLATE_DIR', $this->templateDir);
        $this->varDir       = ( $this->Config('vardir', SCOPE_GLOBALS) ) ? $this->Config('vardir', SCOPE_GLOBALS) : CRIMP_HOME.'/var';
        define('VAR_DIR', $this->varDir);
        $this->defaultLang  = ( $this->Config('defaultlanguage', SCOPE_GLOBALS) ) ? $this->Config('defaultlanguage', SCOPE_GLOBALS) : 'en';
        define('DEFAULT_LANG', $this->defaultLang);
        $this->setTitle( ( $this->Config('sitetitle', SCOPE_GLOBALS) ) ? $this->Config('sitetitle', SCOPE_GLOBALS) : '', true );
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
            if ( isset($this->_config['section'][$tmpstr]) )
                $userConfig = $tmpstr;
        }

        if ( !$userConfig ) $userConfig = '/';
        $this->userConfig = $userConfig;

        $this->debug->addDebug('UserConfig: '.$this->userConfig, PASS);
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
            if ( $conf = $this->Config('titleseparator', SCOPE_GLOBALS) ) $sep = $conf;

            $cur = $this->pageTitle;
            $this->debug->addDebug("setTitle(): Adding '$title' to page title", PASS);
            $this->pageTitle = ( $this->Config('titleorder', SCOPE_GLOBALS) == 'forward' )
                ? "$cur$sep$title" : "$title$sep$cur";
        }
    }

    /**
     *add content to the html page
     */
    public function addContent($htmlcontent, $location = 'bottom') {
        $br = "\n<br />\n";

        if ( $this->_output == $this->defaultHTML ) {
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
            $this->_output = preg_replace('/(<!--endPageContent-->)/',"$br$htmlcontent\n$1",$this->_output);
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
            "$errorDir/$clientLang/$errorCode$package.html",
            "$errorDir/$clientLang/$errorCode.html",
            "$errorDir/$deflang/$errorCode$package.html",
            "$errorDir/$deflang/$errorCode.html",
            "$errorDir/en/$errorCode$package.html",
            "$errorDir/en/$errorCode.html",
        );
        unset($errorDir, $clientLang, $deflang, $plugin);

        $content = false;
        foreach ( $errorFiles as $file ) {
            if ( $content ) next;
            if ( file_exists($file) ) list($title, $content) = HTML::stripHeaderFooter(HTML::pageRead($file));
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
        $this->sendDocument();
        die();
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
            $this->pluginSystem->execute($plugin['name'],
                                         $plugin['num'],
                                         CRIMP_HOME."/plugins/{$plugin['name']}.php",
                                         $plugin['scope'],
                                         true);
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
        if ( !isset($this->_config['section'][$this->userConfig]['plugin'])
            && !isset($this->_config['globals']['plugin'])
            && !isset($this->_config['plugin']) ) {
            $this->debug->addDebug('You forgot to add at least one <plugin> section for this url.', FAIL);
            return;
        }

        /**
         *config scope - this is so that a plugin can determine where it's
         *config root is.
         *from conf.php:
         *  define('SCOPE_SECTION',  1);
         *  define('SCOPE_GLOBALS',  2);
         *  define('SCOPE_ROOT',     3);
         *hopefully we won't have to change these values, as incrementation
         *for successively higher levels works out nicely.
         */
        $scope = 0;

        foreach ( array($this->_config['section'][$this->userConfig],
                        $this->_config['globals'],
                        $this->_config) as $plugins ) {
            $scope++;
            if ( isset($plugins['plugin']) ) {
                $i = 0;
                foreach( $plugins['plugin'] as $plugin ) {
                    if ( isset($plugin['name']) ) {
                        if ( !$this->pluginLock($plugin['name']) ) {
                            $this->pluginSystem->execute($plugin['name'],
                                                         $i,
                                                         CRIMP_HOME."/plugins/{$plugin['name']}.php",
                                                         $scope,
                                                         false);
                        }
                    } else $this->debug->addDebug('the plugin declaration has no "name" element', WARN);
                    $i++;
                }
            }
        }
    }

    /**
     *complete the document and send to the browser
     */
    public function sendDocument() {
        $this->debug->addDebug('Tidying up and exiting cleanly', PASS);

        $exitCode = $this->_exitCode;
        if ( $this->_output && $exitCode == '204' ) $exitCode = '200';
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
             *apply the template
             */
            $this->applyTemplate();

            /**
             *do the deferred plugin thing now that the template has been applied
             */
            if (is_array($this->deferredPlugins)) $this->executeDeferredPlugins();

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
            $this->debug->addDebug("HTTP Exit Code: $exitCode",PASS);
            $debugString = $this->stripHeaderFooter($this->debug->getDisplay());
            unset ($junk);
            $this->_output = preg_replace('|(</body>)|i', "{$debugString[1]}$1", $this->_output, 1);

            /**
             *CHEAT CODES
             */
            $ver = '$Id: crimp.php,v 1.9 2006-12-15 12:22:06 diddledan Exp $';
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
    }

    protected function applyTemplate() {
        if ( !($templ = $this->Config('template', SCOPE_SECTION)) ) {
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
        if ( !is_file($templ) || ! is_readable($templ) ) {
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
	$this->_output = preg_replace('/<!--PAGE_CONTENT-->/i', $content, $template);
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
     *cycle through the config array looking for a specific plugin, and return
     *the value of the hash element who's name is stored in $key
     */
    /**
     *TODO: fix this for multiple invocations of the same plugin within the same
     *scope. eg. two 'perl' plugins calling different modules
     */
    protected function getPlugConf($pluginName, $key, $config, $pluginNum = false) {
        if ( $pluginNum ) {
            if ( isset($config[$pluginNum]) &&
                 isset($config[$pluginNum]['name']) &&
                 $config[$pluginNum]['name'] == $pluginName &&
                 isset($config[$pluginNum][$key]) )
                return $config[$pluginNum][$key];
        } else {
            foreach ($config as $plugin)
                if ( isset($plugin['name']) &&
                     $plugin['name'] == $pluginName &&
                     isset($plugin[$key]) )
                    return $plugin[$key];
        }
        return false;
    }
    /**
     *get a configuration value - subcalls the protected getPlugConf() above
     */
    public function Config($key, $scope = SCOPE_SECTION, $plugin = false, $pluginNum = false) {
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
                    if ( isset($this->_config['section'][$this->userConfig]['plugin']) )
                        if ( $conf = $this->getPlugConf($plugin, $key, $this->_config['section'][$this->userConfig]['plugin'], $pluginNum) )
                            return $conf;
                case SCOPE_GLOBALS:
                    if ( isset($this->_config['globals']['plugin']) )
                        if ( $conf = $this->getPlugConf($plugin, $key, $this->_config['globals']['plugin'], $pluginNum) )
                            return $conf;
                case SCOPE_ROOT:
                    if ( isset($this->_config['plugin']) )
                        if ( $conf = $this->getPlugConf($plugin, $key, $this->_config['plugin'], $pluginNum) )
                            return $conf;
            }
        } else {
            /**
             *if the plugin name wasn't defined we search for just the key name
             *in the same manner as above.
             */
            switch ($scope) {
                case SCOPE_SECTION:
                    if ( isset($this->_config['section'][$this->userConfig][$key]) )
                        return $this->_config['section'][$this->userConfig][$key];
                case SCOPE_GLOBALS:
                    if ( isset($this->_config['globals'][$key]) )
                        return $this->_config['globals'][$key];
                case SCOPE_ROOT:
                    if ( isset($this->_config[$key]) )
                        return $this->_config[$key];
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
    function head($contentType, $exitCode = '200') {
        /**
         *check that the headers have not been sent already
         */
        if ( headers_sent() ) return false;

        $err = ( isset($this->HTTP_EXIT_CODES[$exitCode]) ) ? $this->HTTP_EXIT_CODES[$exitCode]['text'] : 'Unknown';
        header("HTTP/1.1 $exitCode $err");
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

        $file = ERRORDIR.'/404.html';
        $crimp->exitCode('404');

        if ( is_file($file) && is_readable($file) )
            return file_get_contents($file);
        else $this->debug->addDebug("Error page file is either non-existant or unreadable (permissions?)\nFilename: $file", WARN);

        $newhtml = <<<EOF
<h1>404 - Page Not Found</h1>
<p>The document you are looking for has not been found.
Additionally a 404 Not Found error was encountered while trying to
use an error document for this request</p>
EOF;

        $FileRead = $crimp->defaultHTML;
        $FileRead = preg_replace('/(<body>)/i', "$1$newhtml", $FileRead);
        $FileRead = preg_replace('/(<title>)/i', '${1}404 - Page Not Found', $FileRead);
        return $FileRead;
    }
}

?>

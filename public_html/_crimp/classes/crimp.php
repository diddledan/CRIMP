<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: crimp.php,v 1.4 2006-12-01 10:49:17 diddledan Exp $
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

/**
 *CRIMP's main class
 */
class Crimp {
    /**
     *this is for all the content that will be sent to the user's browser
     *upon completion of execution of all plugins.
     */
    protected $_output;
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
    protected $sectionNames;
    protected $RemoteHost;
    protected $serverName;
    protected $serverSoftware;
    protected $serverProtocol;
    protected $userAgent;
    protected $debugMode = 'inline';
    protected $debugSwitch = false;
    protected $Config;
    protected $errordir;
    protected $templatedir;
    protected $defaultLang;
    protected $userConfig;
    /**
     *$pluginLock is for plugins to add to if they are to be called only once.
     *basically the idea is that a plugin will create
     *  $crimp->pluginLock['pluginname'] = true;
     *the plugin should then check this value on loading and error out if it's
     *set to true.
     */
    public $pluginLock;
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
     *constructor
     */
    function Crimp() {
        global $dbg, $config;
        
        $this->_output = $this->defaultHTML;
        
        $this->remoteHost           = $_ENV['REMOTE_ADDR'];
        $this->serverName           = $_ENV['SERVER_NAME'];
        $this->serverSoftware       = $_ENV['SERVER_SOFTWARE'];
        $this->serverProtocol       = $_ENV['SERVER_PROTOCOL'];
        $this->userAgent            = $_ENV['HTTP_USER_AGENT'];
        $this->_HTTPRequest         = $_GET['crimpq'];
        
        define('REMOTE_HOST',       $this->remoteHost);
        define('SERVER_NAME',       $this->serverName);
        define('SERVER_SOFTWARE',   $this->serverSoftware);
        define('PROTOCOL',          $this->serverProtocol);
        define('USER_AGENT',        $this->userAgent);
        define('HTTP_REQUEST',      $this->_HTTPRequest);
        
        $dbg->addDebug("Remote Host: {$this->remoteHost}
Server Name: {$this->serverName}
Server Software: {$this->serverSoftware}
User Agent: {$this->userAgent}
Requested Document: {$this->_HTTPRequest}", PASS);
        
        $this->Config = $config->get();
        $this->applyConfig();
        $this->parseUserConfig();
    }
    
    /**
     *parse the configuration to set some values
     */
    private function applyConfig() {
        $this->errorDir     = ( isset($this->Config['globals']['errordir']) && $this->Config['globals']['errordir'] ) ? $this->Config['globals']['errordir'] : CRIMP_HOME.'/errordocs';
        define('ERROR_DIR', $this->errorDir);
        $this->templateDir  = ( isset($this->Config['globals']['templatedir']) && $this->Config['globals']['templatedir'] ) ? $this->Config['globals']['templatedir'] : CRIMP_HOME.'/templates';
        define('TEMPLATE_DIR', $this->templateDir);
        $this->varDir       = ( isset($this->Config['globals']['vardir']) && $this->Config['globals']['vardir'] ) ? $this->Config['globals']['templatedir'] : CRIMP_HOME.'/var';
        define('VAR_DIR', $this->varDir);
        $this->defaultLang  = ( isset($this->Config['globals']['defaultlanguage']) && $this->Config['globals']['defaultlanguage'] ) ? $this->Config['globals']['defaultlanguage'] : 'en';
        define('DEFAULT_LANG', $this->defaultLang);
        $this->setTitle($this->Config['globals']['sitetitle'], true);
        
        # force to be an array
        if ( isset($this->Config['section']['name']) )
            $this->Config['section'] = array($this->Config['section']);
        
        /**
         *cycle through all the defined <section> elements in the config to
         *work out which url paths have been defined
         */
        foreach ( $this->Config['section'] as $num => $array )
            $this->sectionNames[$array['name']] = $num;
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
        global $dbg;
        
        $tmpstr = $userConfig = '';
        $req = explode('/', $this->_HTTPRequest);
        foreach( $req as $_ ) {
            if ( $_ ) $tmpstr = "$tmpstr/$_";
            if ( isset($this->sectionNames[$tmpstr]) )
                $userConfig = $tmpstr;
        }
        
        if ( !$userConfig ) $userConfig = '/';
        $this->userConfig = $userConfig;
        
        $dbg->addDebug('UserConfig: '.$this->userConfig, PASS);
    }
    
    /**
     *set the document's title for inclusion in the <title></title> tags
     */
    public function setTitle($title, $overwrite = false) {
        global $dbg;
        
        if ( $overwrite ) {
            $dbg->addDebug("<b>setTitle()</b> Overwriting page title with '$title'", PASS);
            $this->pageTitle = $title;
        }
        else {
            $sep = ( isset($this->Config['globals']['titleseparator']) && $this->Config['globals']['titleseparator'] )
                ? $this->Config['globals']['titleseperator'] : ' - ';
            $cur = $this->pageTitle;
            $dbg->addDebug("<b>setTitle()</b> Adding '$title' to page title", PASS);
            $this->pageTitle = ( isset($this->Config['globals']['titleorder']) && $this->Config['globals']['titleorder'] == 'forward' ) ? "$cur$sep$title" : "$title$sep$cur";
        }
    }
    
    /**
     *add content to the html page
     */
    public function addContent($htmlcontent, $location = 'bottom') {
        global $dbg;
        
        $br = "\n<br />\n";
        
        if ( $this->_output == $this->defaultHTML ) {
            $dbg->addDebug('<b>addContent()</b> creating initial page', PASS);
            $this->_output = $this->defaultHTML;
            $location = 'top';
            $br = '';
        } elseif ( $location === true ) {
            $dbg->addDebug('<b>addContent()</b> OVERWRITING page', PASS);
            $this->_output = $this->defaultHTML;
            $location = 'top';
            $br = '';
        }
        
        if ( $location == 'top' ) {
            $dbg->addDebug('<b>addContent()</b> adding to the TOP of the page', PASS);
            $this->_output = preg_replace('/(<!--startPageContent-->)/',"$1$htmlcontent$br",$this->_output);
        } else {
            $dbg->addDebug('addContent() adding to the BOTTOM of the page', PASS);
            $this->_output = preg_replace('/(<!--endPageContent-->)/',"$br$htmlcontent\n$1",$this->_output);
        }
    }
    
    /**
     *add content to the menu which appears above the page content,
     *eg. for fileList plugin
     */
    public function addMenu($menu, $location = 'last') {
        global $dbg;
        if ( ($location == 'first') ) {
	    $dbg->addDebug('Adding MenuContent (top)', PASS);
	    $this->_output = preg_replace('|<!--startMenuContent-->|i', "$0\n$menu<br />\n", $this->_output);
	} else {
	    $dbg->addDebug('Adding MenuContent (bottom)', PASS);
            $this->_output = preg_replace('|<!--endMenuContent-->|i', "<br />\n$menu\n$0", $this->_output);
        }
    }
    
    /**
     *add a new header for inclusion into the final html document
     */
    public function addHeader($header) {
        global $dbg;
        
        $dbg->addDebug("<b>addHeader()</b> adding html header:\n".htmlspecialchars($header), PASS);
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
        global $dbg;
        
        $dbg->addDebug("<b>errorPage()</b> package: $package; errorCondition: $errorCode", PASS);
        
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
        $clientLang = HTTP2::negotiateLanguage($languages, $deflang);
        
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
            list($errorName, $errorDescription) = $http->errorCode($errorCode);
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
     *this is the meat of the application. a simple routine that calls all the
     *defined plugins in the order listed in the config file. it starts with
     *the plugins defined for the section requested (userConfig), then continues
     *with those from the <globals> section of the configuration file.
     */
    public function executePlugins() {
        global $dbg;
        
        $pluginSystem = new crimpPlugins;
        
        $sectionConfig = $this->Config['section'][$this->sectionNames[$this->userConfig]];
        if ( !isset($sectionConfig['plugin']) ) {
            $dbg->addDebug('You forgot to add at least one <plugin> section for this url.', FAIL);
            return;
        }
        foreach ( array($sectionConfig, $this->Config['globals']) as $plugins )
            if ( isset($plugins['plugin']['name']) )
                $pluginSystem->execute( $plugins['plugin']['name'],
                                        CRIMP_HOME."/plugins/{$plugins['plugin']['name']}.php",
                                        $this->userConfig,
                                        $this->_HTTPRequest,
                                        $plugins['plugin'] );
            elseif ( isset($plugins['plugin']) )
                foreach( $plugins['plugin'] as $plugin )
                    if ( isset($plugin['name']) )
                        $pluginSystem->execute( $plugin['name'],
                                                CRIMP_HOME."/plugins/{$plugin['name']}.php",
                                                $this->userConfig,
                                                $this->_HTTPRequest,
                                                $plugin );
                    else $dbg->addDebug('the plugin declaration has no "name" element', WARN);
    }
    
    /**
     *complete the document and send to the browser
     */
    public function sendDocument() {
        global $dbg, $http;
        
        $dbg->addDebug('Tidying up and exiting cleanly', PASS);
        
        $exitCode = $this->_exitCode;
        if ( $this->_output && $exitCode == '204' ) $exitCode = '200';
        if ( !$this->_contentType ) $this->_contentType = 'text/html';
        
        if ( $this->_contentType == 'text/html' ) {
            ## add headers
            if ( $this->debugMode == 'javascript' )
                $this->addHeader('<link rel="stylesheet" type="text/css" href="/crimp_assets/debug-hidden.css" />');
            $this->addHeader('<link rel="stylesheet" type="text/css" href="/crimp_assets/debug.css" />');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/prototype/prototype.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/moo/moo.fx.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/moo/moo.fx.pack.js"></script>');
            $this->addHeader('<script type="text/javascript" src="/crimp_assets/javascript/debug.js"></script>');
            
            $dbg->addDebug("HTTP Exit Code: $exitCode",PASS);
            list($junk,$debugString) = HTML::stripHeaderFooter($dbg->getDisplay());
            unset ($junk);
            $this->_output = preg_replace('|(</body>)|i', "$debugString$1", $this->_output, 1);
            
            $menuString = $this->_menu;
            $this->_output = preg_replace('/(<body>)/i',"$1$menuString", $this->_output, 1);
            $title = $this->pageTitle;
            $this->_output = preg_replace('/(<title>)/i',"$1$title", $this->_output, 1);
            
            $headers = $this->_headers;
            $this->_output = preg_replace('|(</head>)|i',"$headers\n$1", $this->_output, 1);
            
            ## CHEAT CODES
            $ver = '$Id: crimp.php,v 1.4 2006-12-01 10:49:17 diddledan Exp $';
            $this->_output = preg_replace('/<!--VERSION-->/i', $ver, $this->_output);
            ##
        }
        
        $http->head($this->_contentType, $exitCode);
        
        echo $this->_output;
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
}

?>
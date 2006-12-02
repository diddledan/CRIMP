<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: perl.php,v 1.5 2006-12-02 00:21:28 diddledan Exp $
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

class perl implements iPlugin {
    protected $deferred;
    protected $scope;
    protected $crimp;

    function __construct(&$crimp, $scope = SCOPE_ROOT, $deferred = false) {
        $this->deferred = $deferred;
        $this->scope = $scope;
        $this->crimp = &$crimp;
    }
    
    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;
        
        $pluginName = 'perl';
        
        if ( !($config = $crimp->Config('plugin', $this->scope, $pluginName)) ) {
            $dbg->addDebug('You need to set a "plugin" key in the config file for this plugin', WARN);
            return;
        }
        if ( !($parameter = $crimp->Config('parameter', $this->scope, $pluginName)) ) {
            $dbg->addDebug("You need to set a \"parameter\" key in the config file for the perl plugin declaration of '$config'");
            return;
        }
        
        /**
         *Uncomment this if construct if this plugin should defer itself
         */
        #if ( !$this->deferred ) {
        #    $crimp->setDeferral($pluginName, $this->scope);
        #    return;
        #}
        
        $descriptorspec = array(
            0 => array('pipe', 'r'), // client's stdin
            1 => array('pipe', 'w'), // client's stdout
            /*2 => array('file', '/tmp/stderr', 'a'), // client's stderr*/
        );
        
        $querystring = $postquery = $cookies = '';
        foreach($_GET as $key => $value)
            $querystring .= ($querystring) ? "&$key=$value" : "$key=$value";
        foreach($_POST as $key => $value)
            $postquery .= ($postquery) ? "&$key=$value" : "$key=$value";
        foreach($_COOKIE as $key => $value)
            $cookies .= ($cookies) ? "&$key=$value" : "$key=$value";
        
        $env = array(
            'userConfig'        => $crimp->userConfig(),
            'plugin'            => $config,
            'parameters'        => $parameter,
            'QUERY_STRING'      => $querystring,
            'COOKIES'           => $cookies,
            'VAR_DIR'           => VAR_DIR,
            'TEMPLATE_DIR'      => TEMPLATE_DIR,
            'ERROR_DIR'         => ERROR_DIR,
            'CONTENT_TYPE'      => $crimp->contentType(),
            'REMOTE_HOST'       => REMOTE_HOST,
            'SERVER_NAME'       => SERVER_NAME,
            'SERVER_SOFTWARE'   => SERVER_SOFTWARE,
            'PROTOCOL'          => PROTOCOL,
            'USER_AGENT'        => USER_AGENT,
            'HTTP_REQUEST'      => HTTP_REQUEST,
            'CONTENT_LENGTH'    => strlen($postquery),
        );
        
        $cwd = CRIMP_HOME.'/plugins/perl_plugins';
        
        $proc = proc_open(CRIMP_HOME.'/plugins/perl_plugins/perl-php-wrapper.pl', $descriptorspec, $pipes, $cwd, $env);
        
        if ( !is_resource($proc) ) {
            $dbg->addDebug('could not spawn perl-php-wrapper.pl', WARN);
            return;
        }
        
        fwrite($pipes[0], $postquery);
        fclose($pipes[0]);
        $returned = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $retval = proc_close($proc);
        if ( $returned === false ) {
            $dbg->addDebug('error occurred while reading from subprocess');
            return;
        }
        
        $level = ( $retval == 0 ) ? PASS : WARN;
        $dbg->addDebug("perl-php-wrapper.pl exited with code '$retval'", $level);
        $dbg->addDebug("PHP code to be evaluated:\n$returned");
        eval($returned);
    }
}

?>
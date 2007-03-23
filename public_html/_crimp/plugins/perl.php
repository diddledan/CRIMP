<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2007 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: perl.php,v 1.10 2007-03-23 14:11:14 diddledan Exp $
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
    protected $pluginNum;
    protected $scope;
    protected $crimp;

    function __construct(&$crimp, $scope = SCOPE_ROOT, $pluginNum = false, $deferred = false) {
        $this->deferred = $deferred;
        $this->pluginNum = $pluginNum;
        $this->scope = $scope;
        $this->crimp = &$crimp;
    }

    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;
        $pluginNum = $this->pluginNum;
        $pluginName = 'perl';

        if ( !($config = $crimp->Config('plugin', $this->scope, $pluginName, $pluginNum)) ) {
            $dbg->addDebug('You need to set a "plugin" key in the config file for this plugin', WARN);
            return;
        }
        if ( !($parameter = $crimp->Config('parameter', $this->scope, $pluginName, $pluginNum)) ) {
            $dbg->addDebug("You need to set a \"parameter\" key in the config file for the perl plugin declaration of '$config'", WARN);
            return;
        }

        /**
         *deferral check
         */
        $defer = $crimp->Config('defer', $this->scope, $pluginName, $pluginNum);
        if ( $defer == 'yes' &&  !$this->deferred ) {
            $crimp->setDeferral($pluginName, $pluginNum, $this->scope);
            return;
        }

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
            'USERCONFIG'        => $crimp->userConfig(),
            'PLUGIN'            => $config,
            'PARAMETER'         => $parameter,
            'QUERY_STRING'      => $querystring,
            'COOKIES'           => $cookies,
            'CONTENT_TYPE'      => $crimp->contentType(),
            'REMOTE_HOST'       => REMOTE_HOST,
            'SERVER_NAME'       => SERVER_NAME,
            'SERVER_SOFTWARE'   => SERVER_SOFTWARE,
            'PROTOCOL'          => PROTOCOL,
            'USER_AGENT'        => USER_AGENT,
            'HTTP_REQUEST'      => HTTP_REQUEST,
            'CONTENT_LENGTH'    => strlen($postquery),
            'DOCUMENT_ROOT'     => $_SERVER['DOCUMENT_ROOT'],
        );

        /**
         *the following three 'if' constructs check if the path given is
         *relative or not.
         *if it begins with './', we add '../.' to the
         *beginning forcing it to read '../../' so that we come up two dirs
         *from the perl_plugins dir (which means the _crimp dir).
         *if it begins with '../', we add another pair of '../'s so that the
         *relative path becomes relative to the perl_plugins dir, just like
         *what we did above.
         *if neither of these matches, then the path must be fully defined.
         */
        if (strpos(VAR_DIR, './') === 0) $env['VAR_DIR'] = '../.'.VAR_DIR;
        elseif (strpos(VAR_DIR, '../') === 0) $env['VAR_DIR'] = '../../'.VAR_DIR;
        else $env['VAR_DIR'] = VAR_DIR;
        if (strpos(TEMPLATE_DIR, './') === 0) $env['TEMPLATE_DIR'] = '../.'.TEMPLATE_DIR;
        elseif (strpos(TEMPLATE_DIR, '../') === 0) $env['TEMPLATE_DIR'] = '../../'.TEMPLATE_DIR;
        else $env['TEMPLATE_DIR'] = TEMPLATE_DIR;
        if (strpos(ERROR_DIR, './') === 0) $env['ERROR_DIR'] = '../.'.ERROR_DIR;
        elseif (strpos(ERROR_DIR, '../') === 0) $env['ERROR_DIR'] = '../../'.ERROR_DIR;
        else $env['ERROR_DIR'] = ERROR_DIR;

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
        eval($returned);
    }
}

?>

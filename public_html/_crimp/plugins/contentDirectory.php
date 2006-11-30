<?php
# CRIMP - Content Redirection Internet Management Program
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
#
#####
#
# Revision info: $Id: contentDirectory.php,v 1.1 2006-11-30 16:48:09 diddledan Exp $
#
##################################################################################
# This library is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU Lesser General Public                     #
# License as published by the Free Software Foundation; either                   #
# version 2.1 of the License, or (at your option) any later version.             #
#                                                                                #
# This library is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU              #
# Lesser General Public License for more details.                                #
#                                                                                #
# You should have received a copy of the GNU Lesser General Public               #
# License along with this library; if not, write to the Free Software            #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA #
##################################################################################

class contentDirectory extends plugin implements iPlugin {
    public function execute() {
        global $dbg, $crimp, $http;
        
        $path = '';

        $path = $this->httpRequest;
        $userConfig = $this->userConfig;
        $path = preg_replace("|^$userConfig|i", '', $path);
        $dbg->add($path);

        if ( !$path ) $path = '/index.html';

        $requested = implode('/', array($this->config['directory'], $path));
        unset ($slash);

        if ( is_dir($requested) ) $requested = implode('/', array($requested, 'index.html'));



        $dbg->addDebug("contentDirectory\nUsing File: $requested", PASS);



        if ( !is_file($requested) ) {
            $dbg->addDebug('File requested does not exist.', WARN);
            $crimp->errorPage('contentDirectory', '404');
            return;
        }
        if ( !is_readable($requested) ) {
            $dbg->addDebug('File requested is not readable. (Check permissions?)', WARN);
            $crimp->errorPage('contentDirectory', '500');
            return;
        }

        if ( !($display_content = HTML::pageRead($requested)) ) {
            $crimp->errorPage('contentDirectory', '500');
            return;
        }

        list($title, $content) = HTML::stripHeaderFooter($display_content);
        if ( $title ) $crimp->setTitle($title);
        $crimp->addContent($content);

        if ( $crimp->exitCode() != '404' ) $crimp->exitCode('200');
    }
}

?>
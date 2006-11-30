<?php
# http2.php - extension to the HTTP PEAR module designed for use with crimp
# Copyright (C) 2005-2006 The CRIMP Team
# Authors:       The CRIMP Team
# Project Leads: Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
#                Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
# HomePage:      http://crimp.sf.net/
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

require_once('HTTP.php');
class HTTP2 extends HTTP {
    var $ERROR_CODES = array(
        '200' => array('text' => 'OK', 'desc' => ''),
        '204' => array('text' => 'No Content', 'desc' => ''),
        '403' => array('text' => 'Forbidden', 'desc' => 'You do not have permission to view this resource.'),
        '404' => array('text' => 'Not Found', 'desc' => 'The file you were trying to view cannot be found.'),
        '500' => array('text' => 'Internal Server Error', 'desc' => 'The server encountered an error with your request. Please try again.'),
        );

    function errorCode($code) {
        if ( !$this->ERROR_CODES[$code] ) return array('Unknown', 'An Unknown error condition has been reached.');
        return array($this->ERROR_CODES[$code]['text'], $this->ERROR_CODES[$code]['desc']);
    }

    function head($contentType, $exitCode = '200') {
        if ( headers_sent() ) return false;

        $err = $this->ERROR_CODES[$exitCode]['text'];
        header("HTTP/1.0 $exitCode $err");
        header("Content-type: $contentType");

        return true;
    }
}
?>
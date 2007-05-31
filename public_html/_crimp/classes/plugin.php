<?php
/**
 * CRIMP - Content Redirection Internet Management Program
 * Copyright (C) 2005-2007 The CRIMP Team
 * Authors:          The CRIMP Team
 * Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                   Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 * HomePage:         http://crimp.sf.net/
 *
 * Revision info: $Id: plugin.php,v 1.9 2007-05-31 16:33:14 diddledan Exp $
 *
 * This file is released under the LGPL License.
 */

/**
 *this class must be extended by all would-be plugins
 */
abstract class Plugin {
    protected $Crimp;
    protected $ConfigurationScope;
    protected $ExecutionCount;
    protected $IsDeferred;
    
    public function setup($scope, $num, $isDeferred) {
        global $crimp;
        $this->Crimp = &$crimp;
        $this->ConfigurationScope = $scope;
        $this->ExecutionCount = $num;
        $this->IsDeferred = $isDeferred;
    }
    
    abstract public function execute();
}
?>
<?php
/**
 * This file is released under the PHP license
 * Originally found in PEAR::HTTP
 */

class HTTP {
function negotiateLanguage($supported, $default = 'en')
{
    $supp = array();
    foreach ($supported as $lang => $isSupported) {
        if ($isSupported) {
            $supp[strToLower($lang)] = $lang;
        }
    }
    
    if (!count($supp)) {
        return $default;
    }
    
    $matches = array();
    if (isset($_SERVER['HTTP_ACCEPT_LANGUAGE'])) {
        foreach (explode(',', $_SERVER['HTTP_ACCEPT_LANGUAGE']) as $lang) {
            $lang = array_map('trim', explode(';', $lang));
            if (isset($lang[1])) {
                $l = strtolower($lang[0]);
                $q = (float) str_replace('q=', '', $lang[1]);
            } else {
                $l = strtolower($lang[0]);
                $q = null;
            }
            if (isset($supp[$l])) {
                $matches[$l] = isset($q) ? $q : 1000 - count($matches);
            }
        }
    }
    
    if (count($matches)) {
        asort($matches, SORT_NUMERIC);
        return $supp[end($l = array_keys($matches))];
    }
    
    if (isset($_SERVER['REMOTE_HOST'])) {
        $lang = strtolower(end($h = explode('.', $_SERVER['REMOTE_HOST'])));
        if (isset($supp[$lang])) {
            return $supp[$lang];
        }
    }
    
    return $default;
}
}
?>
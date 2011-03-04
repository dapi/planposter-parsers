<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of HtmlParser
 *
 * @author J0nny
 */


class HttpLib
{
    // tcp connection
    protected $session;
    protected $curl_log;
    protected $headers_log;

    function  __construct()
    {
        $this->session = curl_init();
        $this->curl_log = fopen("tmp/curl.log", "w");
        $this->headers_log = fopen("tmp/headers.log", "w");
    }
    function  __destruct()
    {
        fclose($this->curl_log);
        fclose($this->headers_log);
        curl_close($this->session);
    }
    function dumpheader($s)
    {
//        fwrite($this->headers_log, "QUERY:\n"
//                . curl_getinfo($this->session, CURLINFO_HEADER_OUT)
//                ."RESPONSE:\n"
//                . $s);
        //print_r(curl_getinfo($this->session));
    }
    function init($cookieFile)
    {
        curl_setopt($this->session, CURLOPT_HEADER, true);
        //curl_setopt($this->session, CURLOPT_NOBODY, true);
        curl_setopt($this->session, CURLOPT_CONNECTTIMEOUT, 30);
        curl_setopt($this->session, CURLOPT_COOKIEJAR, $cookieFile);
        curl_setopt($this->session, CURLOPT_COOKIEFILE, $cookieFile);
        $s[] = "Accept-Charset:	utf-8";
        $s[] = "Connection: keep-alive";
        $s[] = "Keep-Alive: 300";
        $s[] = "Expect: ";
        curl_setopt($this->session, CURLOPT_HTTPHEADER, $s);
        // curl_setopt($this->session, CURLOPT_REFERER, $referer);
        curl_setopt($this->session, CURLOPT_AUTOREFERER, true);
        curl_setopt($this->session, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($this->session, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($this->session, CURLOPT_TIMEOUT, 30);
        curl_setopt($this->session, CURLINFO_HEADER_OUT, true);
        curl_setopt($this->session, CURLOPT_VERBOSE, true);
        curl_setopt($this->session, CURLOPT_COOKIESESSION, true);
        // curl_setopt($this->session, CURLOPT_STDERR, $this->curl_log);
    }

    function loadFromUrl($url)
    {
        curl_setopt($this->session, CURLOPT_URL, $url);
        for($i=0;$i < 3;++$i)
        {
            $data = curl_exec($this->session);
            if($data) 
                break;
        }
        if(!$data)
            throw new Exception(curl_error($this->session) . ": $url");
        $this->dumpheader(substr($data, 0, curl_getinfo($this->session,CURLINFO_HEADER_SIZE)));
        return substr($data, curl_getinfo($this->session,CURLINFO_HEADER_SIZE));
    }
    function getUrl()
    {
        return curl_getinfo ( $this->session, CURLINFO_EFFECTIVE_URL );
    }
    function setCookie($cookie)
    {
        curl_setopt($this->session, CURLOPT_COOKIE, $cookie);
    }
    function postData($url, $s)
    {
        curl_setopt ($this->session, CURLOPT_POSTFIELDS, $s);
        curl_setopt ($this->session, CURLOPT_POST, true);
        curl_setopt ($this->session, CURLOPT_URL, $url);
        $data = curl_exec($this->session);
        if(!$data)
            throw new Exception("postData failed: $url, $s");
        $this->dumpheader(substr($data, 0, curl_getinfo($this->session,CURLINFO_HEADER_SIZE)));
        curl_setopt($this->session, CURLOPT_HTTPGET, true);
        return substr($data, curl_getinfo($this->session,CURLINFO_HEADER_SIZE));
    }
    function setTimeOut($secs)
    {
        curl_setopt($this->session, CURLOPT_TIMEOUT, $secs);
    }
}
?>

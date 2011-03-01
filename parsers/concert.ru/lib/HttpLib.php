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
    //"concert_ru.cookies"
    // 'http://concert.ru/Default.aspx'
    // маскировка под firefox
    function init($cookieFile, $referer)
    {
        curl_setopt($this->session, CURLOPT_HEADER, true);
        //curl_setopt($this->session, CURLOPT_NOBODY, true);
        curl_setopt($this->session, CURLOPT_CONNECTTIMEOUT, 30);
        curl_setopt($this->session, CURLOPT_COOKIEJAR, $cookieFile);
        curl_setopt($this->session, CURLOPT_COOKIEFILE, $cookieFile);
        $s[] = "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3";
        $s[] = "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
        $s[] = "Accept-Language: ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3";
        $s[] = "Accept-Encoding: gzip,deflate";
        $s[] = "Accept-Charset:	windows-1251,utf-8;q=0.7,*;q=0.7";
        $s[] = "Connection: keep-alive";
        $s[] = "Keep-Alive: 300";
        $s[] = "Expect: ";
        curl_setopt($this->session, CURLOPT_HTTPHEADER, $s);
        // curl_setopt($this->session, CURLOPT_REFERER, $referer);
        curl_setopt($this->session, CURLOPT_AUTOREFERER, true);
        curl_setopt($this->session, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($this->session, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($this->session, CURLOPT_TIMEOUT, 10);
        curl_setopt($this->session, CURLINFO_HEADER_OUT, true);
        curl_setopt($this->session, CURLOPT_VERBOSE, true);
        curl_setopt($this->session, CURLOPT_COOKIESESSION, true);
        // curl_setopt($this->session, CURLOPT_STDERR, $this->curl_log);
    }

    function loadFromUrl($url)
    {
        curl_setopt($this->session, CURLOPT_URL, $url);
        $data = curl_exec($this->session);
        if(!$data)
            throw new Exception("ошибка при загрузке страницы: $url");
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
}
?>

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

class Href
{
    protected $title;
    protected $url;
    function  __construct($Url, $Title) {
        $this->title = trim($Title);
        $this->url = trim($Url);
    }
    function Title()    { return $this->title; }
    function Url()      { return $this->url; }
    function SetTitle($s) { $this->title = $s; }
}

class Html
{
    // tcp connection
    protected $session;
    protected $cookie;
    
    function  __construct()
    {
        $this->cookie = '';
        $this->session = curl_init();
        curl_setopt($this->session, CURLOPT_HEADER, true);
        curl_setopt($this->session, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($this->session, CURLOPT_FOLLOWLOCATION, 1);
        //curl_setopt($this->session, CURLOPT_NOBODY, true);
        curl_setopt($this->session, CURLOPT_CONNECTTIMEOUT, 30);
    }
    function  __destruct()
    {
        curl_close($this->session);
    }
    function loadFromUrl($url)
    {
        curl_setopt($this->session, CURLOPT_URL, $url);
        if($this->cookie)
                curl_setopt($this->session, CURLOPT_COOKIE, "_tnp_session=" . $this->cookie);

        $data = curl_exec($this->session);
        $header = substr($data, 0, curl_getinfo($this->session,CURLINFO_HEADER_SIZE));

        preg_match_all("/Set-Cookie: _tnp_session=(.*?);/i",$header,$res);

        $this->cookie = isset($res[1][0]) ? $res[1][0] : '';

        return substr($data, curl_getinfo($this->session,CURLINFO_HEADER_SIZE));
    }
    function xpath_from_url($url)
    {
        $data = $this->loadFromUrl($url);
        $xmlDoc = new DOMDocument;
        if (!@$xmlDoc->loadHTML($data)) {
            throw new Exception('Ошибка при загрузке xml');
        }
        $xmlDoc->normalizeDocument();
        return new DOMXPath($xmlDoc);
    }

    function xpath_from_string($data)
    {
        $xmlDoc = new DOMDocument;
        if (!@$xmlDoc->loadHTML($data)) {
            throw new Exception('Ошибка при загрузке xml');
        }
        $xmlDoc->normalizeDocument();
        return new DOMXPath($xmlDoc);
    }
    function getUrl()
    {
        return curl_getinfo ( $this->session, CURLINFO_EFFECTIVE_URL );
    }
}
?>

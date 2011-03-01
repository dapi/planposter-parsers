<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Parser
 *
 * @author Olg3andr
 */
include_once 'HttpLib.php';

class ParserBase
{
    protected $html;
    protected $xpath;
    protected $snapshot;
    protected $debug_log;
    protected $debug_mode;
    protected $extractHelper;
    protected $xmlDoc;

    function  __construct($debug_mode = true)
    {
        $this->debug_mode = $debug_mode;
        $this->html = new HttpLib();
        
//        if($this->debug_mode)
//            $this->debug_log = fopen("debug.log", "w+");
    }

    function  __destruct() {
        if ($this->debug_mode)
//            fclose($this->debug_log);
            unset($this->html);
            unset($this->snapshot);
    }

    protected function deb($str)
    {
        if ($this->debug_mode)
            print "[". date("H:i:s")."] ". $str. "\n";
//            fwrite($this->debug_log, "[". date("H:i:s")."] ". $str. "\n");
    }

    function xpath_from_url($url)
    {
        return $this->xpath_from_string( $this->html->loadFromUrl($url) );
    }

    function xpath_from_string($data)
    {
        $this->xmlDoc = new DOMDocument;
        if (!@$this->xmlDoc->loadHTML($data)) {
            throw new Exception('Ошибка при загрузке xml');
        }
        $this->xmlDoc->normalizeDocument();
        return new DOMXPath($this->xmlDoc);
    }

    // извлечь данные из переданной страницы, используя модель $outerDescription

    protected function parsePage($url, $json)
    {
        return $this->parsePageFromString($this->html->loadFromUrl($url), $json);
    }

    protected function  parsePageFromString($data, $json)
    {
        $this->snapshot     = $data;
        if(!$data)
            throw new Exception ("parsePageFromString: empty data passed");
        $this->xpath        = $this->xpath_from_string($this->snapshot);
        $contents = file_get_contents($json);
        if(!$contents)
            throw new Exception("failed to load json descripion module: $json");
        $description = json_decode($contents);
        if(!$description)
            throw new Exception("failed to decode json descripion module: $json");
        $rootContext = $this->xpath->query("/");
        if(!$rootContext)
            throw new Exception("parsePage: failed to query root context");
        return $this->extract($description, $rootContext->item(0));
    }

    protected function extract($outerDescription, DOMNode $xpathContext)
    {
        if(is_null($xpathContext))
        {
            throw new Exception("null context: inner description = ". http_build_query($outerDescription) .".\n");
        }

        if(isset ($outerDescription->context))
        {
            $nodes       = $this->xpath->query($outerDescription->context, $xpathContext);
            $innerDescription = $outerDescription->data;
            if(is_array($innerDescription))
            {
                $a = array();
                for($i=0; $i < $nodes->length; ++$i)
                {
                    $a[$i] = $this->extract($innerDescription[0], $nodes->item($i));
                }
                return $a;
            }
            elseif(is_object($innerDescription))
            {
                if($nodes->length)
                    return $this->extract($innerDescription, $nodes->item(0));
                else
                    return array();
            }
            // Ошибка формата
            else
                throw new Exception;
        }
        else
        {
            $o = array();
            foreach($outerDescription as $k => $v)
            {
                // "key" : {...}
                if(is_object($v))
                {
                    $o[$k] = $this->extract( $v, $xpathContext);
                }
                elseif(is_array($v))
                {
                    // "key" : ["xpath_context:xpath_expr"]
                    if(is_string($v[0]))
                    {
                        list($ctx, $expr) = explode(":", $v[0]);
                        $nodes = $this->xpath->query($ctx, $xpathContext);
                        $o[$k] = array();
                        for($i=0; $i < $nodes->length; ++$i)
                            $o[$k][$i] = $this->xpath->evaluate($expr, $nodes->item($i));
                    }
                    // "key" : [{...}]
                    elseif(is_object($v[0]))
                    {
                        if(!isset($v[0]->context) || !isset($v[0]->data))
                                throw new Exception("descr: no context");
                        $o[$k] = array();
                        $nodes  = $this->xpath->query($v[0]->context, $xpathContext);
                        $nc = $nodes->length;
                        for($i=0; $i < $nc; ++$i)
                            $o[$k][$i] = $this->extract($v[0]->data, $nodes->item($i));
                    }
                    else
                    {
                        throw new Exception("descr: неправильный формат описания");
                    }
                }
                // "key" : "xpath_expr"
                elseif(is_string($v))
                {
                    $data = $this->xpath->evaluate($v, $xpathContext);
                    if(is_string($data))
                        $data = trim($data);
                    $o[$k]= $data;
                }
                else
                    throw new Exception;
            }
            return $o;
        }
    }

    function parse() {}
    
}

?>

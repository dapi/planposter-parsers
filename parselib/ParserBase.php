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
    protected $stdout;

    function  __construct($debug_mode = true)
    {
        $this->debug_mode = $debug_mode;
        $this->html = new HttpLib();

        if(!is_dir("data/") && !mkdir ("data/", 0777))
            throw new Exception("Ошибка создания директории data. Возможно нет прав на создание директории...");
        if(!is_dir("tmp/") && !mkdir ("tmp/", 0777))
            throw new Exception("Ошибка создания директории tmp. Возможно нет прав на создание директории...");

//        if($this->debug_mode)
//            $this->debug_log = fopen("debug.log", "w+");
        if($this->debug_mode)
        {
            $this->debug_log = fopen("debug.log", "w+");
            $this->stdout = fopen('php://stdout', 'w');
        }
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

    // извлечь данные из переданной страницы, используя правила $rules

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

    protected function extract($rules, DOMNode $contextNode)
    {
        if(is_null($contextNode))
        {
            throw new Exception("null context node\n");
        }

        if(isset ($rules->context))
        {
            $nodes  = $this->xpath->query($rules->context, $contextNode);
            if(!isset($rules->data))
            {
                throw new Exception("отсутсвуют правила для контекста");
            }
            if(is_array($rules->data))
            {
                $a = array();
                foreach($nodes as $node)
                {
                    //$b = array();
                    //foreach($rules->data as $rule)
                    //    $b[] = $this->extract($rule, $node);
                    $a[] = $this->extract($rules->data[0], $node);
                }
                return $a;
            }
            elseif(is_object($rules->data))
            {
                $a = array();
                if($nodes->length)
                    $a = $this->extract($rules->data, $nodes->item(0));
                return $a;
            }
            // Ошибка формата
            else
                throw new Exception;
        }
        else
        {
            $a = array();
            foreach($rules as $k => $v)
            {
                // "key" : {...}
                if(is_object($v))
                {
                    $a[$k] = $this->extract( $v, $contextNode);
                }
                elseif(is_array($v))
                {
                    if(!count($v))
                        $a[$k] = array();
                    // "key" : ["xpath_context:xpath_expr"]
                    elseif(is_string($v[0]))
                    {
                        list($ctx, $expr) = explode(":", $v[0]);
                        $nodes = $this->xpath->query($ctx, $contextNode);
                        $a[$k] = array();
                        foreach($nodes as $node)
                            $a[$k][] = $this->xpath->evaluate($expr, $node);
                    }
                    // || !isset($v[0]->data))
                    // "key" : [{...}]
                    elseif(is_object($v[0]) && isset($v[0]->context) && isset($v[0]->data))
                    {
                        $a[$k] = array();
                        $nodes  = $this->xpath->query($v[0]->context, $contextNode);
                        foreach($nodes as $node)
                            $a[$k][] = $this->extract($v[0]->data, $node);
                    }
                    else
                    {
                        throw new Exception("descr: неправильный формат описания");
                    }
                }
                // "key" : "xpath_expr"
                elseif(is_string($v))
                {
                    $data = $this->xpath->evaluate($v, $contextNode);
                    if(is_string($data))
                        $data = trim($data);
                    $a[$k]= $data;
                }
                else
                    throw new Exception;
            }
            return $a;
        }
    }

    function parse() {}

}

?>

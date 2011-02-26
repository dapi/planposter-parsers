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
include_once 'Html.php';

class Parser
{
    protected $html;
    protected $xpath;
    protected $snapshot;
    protected $debug_log;
    protected $debug_mode;
    protected $use_snapshot;
    protected $extractHelper;

    function  __construct($use_snapshot = false, $debug_mode = true)
    {
        $this->use_snapshot = $use_snapshot;
        $this->debug_mode = $debug_mode;
        $this->html = new Html();
        
        if($this->debug_mode)
            $this->debug_log = fopen("debug.log", "w+");
    }

    function  __destruct() {
        if ($this->debug_mode)
            fclose($this->debug_log);
    }

    protected function deb($str)
    {
        if ($this->debug_mode)
            fwrite($this->debug_log, "[". date("H:i:s")."] ". $str. "\n");
    }

    // извлечь данные из переданной страницы, используя модель $outerDescription

    protected function parsePage($url, $json)
    {
        $this->snapshot     = $this->html->loadFromUrl($url);
        $this->xpath        = $this->html->xpath_from_string($this->snapshot);
        $description = json_decode(file_get_contents($json));
        $rootContext = $this->xpath->query("//.");
        return $this->extract($description, $rootContext->item(0));
    }

    protected function extract($outerDescription, DOMNode $xpathContext)
    {
        // если объект содержит поле context,
        // то объект имеет след структуру
        // obj : {"context":"", "data":""}
        // иначе это данные
        //echo "enter:<br>";
//        print_r($outerDescription);
//        echo "<br>-------------------<br>";
//        print_r($xpathContext);
//        echo "<br>-------------------<br>";

        if(is_null($xpathContext))
        {
            throw new Exception("null context: inner description = ". http_build_query($outerDescription) .".\n");
        }

        if(isset ($outerDescription->context))
        {
            //echo "found context: $outerDescription->context<br>";
            $nodes       = $this->xpath->query($outerDescription->context, $xpathContext);
            //echo "nodes count: $nodes->length<br>";
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
                if(is_object($v))
                {
                    $o[$k] = $this->extract( $v, $xpathContext);
                }
                elseif(is_array($v))
                {
                    $nodes = $this->xpath->query($v[0], $xpathContext);
                    for($i=0; $i < $nodes->length; ++$i)
                        $o[$k][$i] = $nodes->item($i)->nodeValue;
                }
                elseif(is_string($v))
                    $o[$k]= trim($this->xpath->evaluate($v, $xpathContext));
                else
                    throw new Exception;
            }
            return $o;
        }
    }

    function parse() {}
    
}

?>

<?php
  header("Content-Type: text/xml;");
  $url="http://www.afisha.ru/msk/exhibitions/";
  $html=file_get_contents($url);

  $echoStr="";
  $echoStr.="<main>\n";

  $arrStr=explode("fulldate",$html);
  for ($i=1; $i<count($arrStr);$i++)
  {
    $st=strpos($arrStr[$i],'">');
    if ($st>=0)
    {
      $en=strpos($arrStr[$i],"</div>",$st);
      $str=substr($arrStr[$i],$st+2,$en-$st-2);
      $str=trim($str);
      $echoStr.="  <date day='".$str."'>\n";

      $arrStr2=explode("b-soon__users-list-block",$arrStr[$i]);
      for ($j=1; $j<count($arrStr2);$j++)
      {
        $st2=strpos($arrStr2[$j],'b-object-type');
        if ($st2>=0)
        {
          $en2=strpos($arrStr2[$j],"</p>",$st2);
          $str2=trim(substr($arrStr2[$j],$st2+15,$en2-$st2-15));
          $echoStr.="    <type>".$str2."</type>\n";
        }

        $st2=strpos($arrStr2[$j],'fn permalink');
        if ($st2>=0)
        {
          $en2=strpos($arrStr2[$j],"</a>",$st2);
          $str2=trim(substr($arrStr2[$j],$st2+14,$en2-$st2-14));
          $echoStr.="    <name>".$str2."</name>\n";
        }

        $st2=strpos($arrStr2[$j],'b-soon__links b-soon__links_after');
        if ($st2>=0)
        {
          $en2=strpos($arrStr2[$j],"</p>",$st2);
          $str2=trim(substr($arrStr2[$j],$st2+35,$en2-$st2-35));
          $echoStr.="    <links>".$str2."</links>\n";
        }

        $st2=strpos($arrStr2[$j],'summary');
        if ($st2>=0)
        {
          $en2=strpos($arrStr2[$j],"</p>",$st2);
          $str2=trim(substr($arrStr2[$j],$st2+9,$en2-$st2-9));
          $echoStr.="    <summary>".$str2."</summary>\n";
        }

      }
      $echoStr.="  </date>\n";

    }
  }
  $echoStr.="</main>";

  echo $echoStr;

?>
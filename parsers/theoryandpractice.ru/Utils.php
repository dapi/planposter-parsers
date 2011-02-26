<?php
/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

function decodeDanishMonth($s)
{
    static $p = array(  '/jan.+/i','/feb.+/i','/Marts/i','/April/i',
                '/Maj/i','/Juni/i','/Juli/i','/August/i',
                '/September/i','/Oktober/i','/November/i','/November/i');

    static $r = array('01','02','03','04','05','06','07','08','09','10', '11','12');

    return preg_replace($p, $r, $s);
}
function decodeMonth($s)
{
    static $p = array(  '/янв.+/i','/фев.+/i','/мар.+/i','/апр.+/i',
                        '/мая/i','/июн.+/i','/июл.+/i','/авг.+/i',
                        '/сен.+/i','/окт.+/i','/ноя.+/i','/дек.+/i');

    static $r = array('01','02','03','04','05','06','07','08','09','10', '11','12');

    $rs = preg_replace($p, $r, $s);
    if($rs == $s)
        $rs = decodeDanishMonth($s);
    return $rs;
}

function decodeDate($s)
{
    $date = '';
    if (preg_match("/\s*([0-9]{1,2})\s+(\S+)\s*([0-9]{4})?/", $s, $matches))
    {
        $n = sizeof($matches) - 1;

        if ($n == 3)
            $date .= $matches[3] . "-";
        else
            $date .= date("Y"). "-";
        $date .=    decodeMonth($matches[2]);

        $tmp = $matches[1];
        $date .= "-" . preg_replace("/^\d$/", "0".$matches[1], $tmp );
    }
    return $date;
}
function isValidTimeFormat($s)
{
    return preg_match("/^\s*([0-9]{2})\s*:\s*([0-9]{2})\s*$/", $s, $matches);
}

function json_fix_cyr($json_str)
{
     $cyr_chars = array (
            '\u0430' => 'а', '\u0410' => 'А',
            '\u0431' => 'б', '\u0411' => 'Б',
            '\u0432' => 'в', '\u0412' => 'В',
            '\u0433' => 'г', '\u0413' => 'Г',
            '\u0434' => 'д', '\u0414' => 'Д',
            '\u0435' => 'е', '\u0415' => 'Е',
            '\u0451' => 'ё', '\u0401' => 'Ё',
            '\u0436' => 'ж', '\u0416' => 'Ж',
            '\u0437' => 'з', '\u0417' => 'З',
            '\u0438' => 'и', '\u0418' => 'И',
            '\u0439' => 'й', '\u0419' => 'Й',
            '\u043a' => 'к', '\u041a' => 'К',
            '\u043b' => 'л', '\u041b' => 'Л',
            '\u043c' => 'м', '\u041c' => 'М',
            '\u043d' => 'н', '\u041d' => 'Н',
            '\u043e' => 'о', '\u041e' => 'О',
            '\u043f' => 'п', '\u041f' => 'П',
            '\u0440' => 'р', '\u0420' => 'Р',
            '\u0441' => 'с', '\u0421' => 'С',
            '\u0442' => 'т', '\u0422' => 'Т',
            '\u0443' => 'у', '\u0423' => 'У',
            '\u0444' => 'ф', '\u0424' => 'Ф',
            '\u0445' => 'х', '\u0425' => 'Х',
            '\u0446' => 'ц', '\u0426' => 'Ц',
            '\u0447' => 'ч', '\u0427' => 'Ч',
            '\u0448' => 'ш', '\u0428' => 'Ш',
            '\u0449' => 'щ', '\u0429' => 'Щ',
            '\u044a' => 'ъ', '\u042a' => 'Ъ',
            '\u044b' => 'ы', '\u042b' => 'Ы',
            '\u044c' => 'ь', '\u042c' => 'Ь',
            '\u044d' => 'э', '\u042d' => 'Э',
            '\u044e' => 'ю', '\u042e' => 'Ю',
            '\u044f' => 'я', '\u042f' => 'Я',

            '\r' => '',
            '\n' => '\\n',
            '\t' => ''
      );

    foreach ($cyr_chars as $cyr_char_key => $cyr_char) {
      $json_str = str_replace($cyr_char_key, $cyr_char, $json_str);
    }
    return $json_str;
}

?>

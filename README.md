# Изменения:

В хеше событий id переименован в uid.

Парсер запускается в том-же каталоге что находится сам. Это можно учитывать в путях.

Данные передаются не массивом хешей, а каждый хеш сохраняется в отдельном файле с расширением .json в папке ./data/


Назание файла уникальное для текущей сесси сбора. Варианты наименования файла:

1. Простой инкремент 1.json, 2.json
2. По uid события (если оно есть и уникальное)
3. По url-у события (если оно уникальное)
4. По url + subject события (ну это точно должно быть уникальное)

На STDOUT можно выводить лог записи этих файлов, чтобы наблюдать за процессом сбора.

Аттрибут dump передавать только в случае запуска в дебаг-режиме (устанавливается аргументом, нипа -d)

    {
       source: 'http://concert.ru/',            // ОБЯЗАТЕЛЬНО
       url: 'http://concert.ru/страница.html',  // ОБЯЗАТЕЛЬНО
       uid: 'уникальный инедтификатор события', // Есть есть
       image_url: 'Адрес картинки события',     // Очень желательно
       subject: 'Тема, название события',       // ОБЯЗАТЕЛЬНО
       category: "Тим события",                 // ОБЯЗАТЕЛЬНО
       place: 'Место где проходит',             // ОБЯЗАТЕЛЬНО
       address: 'Адрес где проходит',           // ОБЯЗАТЕЛЬНО
       city: 'Москва',                          // ОБЯЗАТЕЛЬНО
       date: дата,                              // ОБЯЗАТЕЛЬНО // Дата отпарсенная в формате  2011-02-24 (YYYY-MM-DD)
       time: время,                             // ОБЯЗАТЕЛЬНО // Например 12:00
       period: длительность в минутах,          // Очень жалательно
       details: "дополнительные детали",        // Очень жалательно. Простой текст
       dump: "дамп страницы или блока отуда выдрали информацию",  // В любом формате, только укажите его
       dump_type: "text/ruby/xml"
    }

Если событие встречается в более чем одной катеории, то или оно выводится для каждой категории отдельно,
либо категории передаютя массивом.

# Источники:

https://spreadsheets.google.com/ccc?key=0ArR1ApxjK8jPdEpWbk9kN1dGNEQwdmhEa19icTAxZlE&hl=en#gid=0

# Примеры и примеры:

[Пример json-результата](https://github.com/dapi/planposter-parsers/raw/master/utils/example.json)

Парсинг данных:

    cd ./parsers/timeout.ru
    parser.rb

Загрузка всех отпарсенных данных:

    RACK_ENV=test ./collect.rb ./parsers/timeout.ru/data/

или, для загрузки конкретного файла:

    ./collect.rb 123.json

после удачной загрузки файла коллектор его удаляет.



#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'

event = {
  :subject  => 'Мадонна в каташе',
  :place    => 'Конюшня дяди Степы',
  :source   => 'http://concert.ru/',
  :url      => 'http://concert.ru/конкретная страница откуда свиснули',
  :image_url=> 'http://pix.timeout.ru/249655.jpeg',
  :subject  => 'Тема, название события',
  :place    => 'Место где проходит',
  :category => "Тим события",
  :address  => 'Адрес где проходит',
  :city     => 'Москва',
  :date     => Date.parse('2010/11/12'),
  :time     => '17:00',
  :period   => 60,
  :details  => "дополнительные детали",
  :dump     => "дамп страницы или блока отуда выдрали информацию"

}


data = 10.times.map { event }

puts data.to_json

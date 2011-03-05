#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'json/add/rails'

event = {
  :source    => 'http://concert.ru/',
  :url       => 'http://concert.ru/123.html',
  :image_url => 'http://pix.timeout.ru/249655.jpeg',
  :subject   => 'Мадонна в каташе',
  :category  => "Тим события",
  :place     => 'Конюшня дяди Степы',
  :address   => 'Адрес где проходит',
  :city      => 'Москва',
  :date      => Date.parse('2010/11/22'),
  :time      => '17:00',
  :period    => 60,
  :details   => "дополнительные детали",
  :dump      => "дамп страницы или блока отуда выдрали информацию",
  :dump_type => 'text'
}


data = 3.times.map { event }

puts data.to_json

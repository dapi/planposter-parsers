# -*- coding: utf-8 -*-
class ParserRunner
  attr_accessor :script

  def initialize(file)
    @script = file
  end
  
  def run
    puts "Запускаю парсер #{script}"
    # http://tech.natemurray.com/2007/03/ruby-shell-commands.html
    data = `#{script}`
    if $?==0
      puts "Разбираю.."
      load_events JSON.parse(data)
    else
      puts "Ошибка: #{$?}"
    end
  end
  
  private
  
  def load_events(events)
    puts "Событий #{events.count}"
    events.each do |event|
      Event.create_from_parser script, event
    end
  end

end

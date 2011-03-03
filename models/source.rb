# -*- coding: utf-8 -*-

class Source
  include DataMapper::Resource

  property :id,          Serial
  property :url,         String
  property :enabled,     Boolean
  property :state,       String
  property :parsing_started_at, Time
  property :parsing_finished_at, Time
  property :parsing_result, Integer
  property :import_started_at, Time
  property :import_finished_at, Time
  property :imported_count, Integer
  property :not_imported_count, Integer
  property :events_count, Integer, :default => 0

  has n, :events


  def run_parser parser_file
    # парсинг
    state = 'parsing'
    parsing_started_at = Time.now
    parsing_finished_at = nil
    save

    `./#{parser_file}`
  rescue Exception => e
    puts "parsing_error: #{e}"
    save_parser_result $?.to_i==0 ? -998 : $? || -999
  ensure
    save_parser_result $?
  end

  def collect_data
    state='importing'
    import_started_at = Time.now
    imported_count = 0
    not_imported_count = 0
    save
    parser = ParseUtils.new(true)
    Dir.glob('data/*.json').sort.each do |file|
      if parser.load_file file
        imported_count += 1
      else
        not_imported_count += 1
      end
    end
    state = imported_count > 0 ? 'imported' : 'not_imported'
    import_finished_at = Time.now
    imported_count = imported_count
    not_imported_count = not_imported_count
    save
  end


  def save_parser_result result=0
    state = result == 0 ? 'parsing_error' : 'parsing_ok'
    parsing_result = result
    parsing_finished_at = Time.now
    save
  end

end

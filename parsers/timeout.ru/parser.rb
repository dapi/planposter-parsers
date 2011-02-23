$KCODE = 'u'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'

timeout_schedules = [
  'http://www.timeout.ru/books/schedule/',
  'http://www.timeout.ru/childs/schedule/',
  'http://www.timeout.ru/theatre/schedule/',
  'http://www.timeout.ru/exhibition/schedule/',
  'http://www.timeout.ru/music/schedule/',
  'http://www.timeout.ru/clubs/schedule/',
  'http://www.timeout.ru/cinema/schedule/',
  'http://www.timeout.ru/city/schedule/'
]

def puts_event( event )
  puts <<-EOS
  {
    source:   '#{event['source']}',
    url:      '#{event['page']}',
    image_url:'#{event['image_url']}',
    subject:  '#{event['subject']}',
    place:    '#{event['place']}',
    category: '#{event['category']}',
    address:  '#{event['address']}',
    city:     '#{event['city']}',
    date:     '#{event['date']}',
    time:     '#{event['time']}',
    period:   '#{event['period']}',
    details:  '#{event['details']}',
    dump:     '#{event['dump']}'
  }
  EOS
end

categories = [
  'books',
  'childs',
  'theatre',
  'exhibition',
  'music',
  'clubs',
  'cinema',
  'city'
]

@host_url = 'http://www.timeout.ru'

begin
  @places = YAML.load_file('places.yml')
rescue
  @places = {}
end

def get_place( place_type, place_id )
  place = {}
  if @places.include?(place_type)
    if @places[place_type].include?(place_id)
      place = {
        'name'   => @places[place_type][place_id]['name'],
        'address' => @places[place_type][place_id]['address']
      }
      return place
    end
  else
    @places[place_type] = {}
  end
  
  place_url = [@host_url, place_type, 'place', place_id].join('/')
  doc = Nokogiri::HTML( open(place_url) )
  doc = doc.css("div[class='vcard context'] div.single")[0]
  place['name'] = doc.css("div.headingH2 h1").text
  place['address'] = doc.css("div.contento p.adr").text
  @places[place_type][place_id] = place
  return place
end

all_events = {}

def category_parse( category_name )
  category_events = []
  category_url = [@host_url, category_name, 'schedule'].join('/')
  doc = Nokogiri::HTML( open(category_url) )
  dates = doc.css("select[name='date'] option")
  dates.each do |date|
    category_url = [@host_url, category_name, 'schedule', date['value']].join('/')
    doc = Nokogiri::HTML( open(category_url) )
    events = doc.css("div.w-list div[class~='w-list-block']")
    events.each do |event|
      next if not ['kino', 'teatr'].include?( event['class'].split()[1] )
      event_id = event.css("h3 a")[0]['href'].split('/')[-1]
      if not category_events.include?(event_id)
        category_events.push( event_id )
        event_url = [@host_url, category_name, 'event', event_id].join('/')
        doc = Nokogiri::HTML( open(event_url) )
        doc = doc.css("div[class='vcard context'] div.single")[0]
        event = {
          'url'  => [],
          'dump' => []
        }
        event['source'] = @host_url
        event['url'].push( event_url )
        event['image_url'] = doc.css("div#fpic img")[0]['src']
        event['subject'] = doc.css("div.headingH2 h1")[0].text
        event['category'] = category_name
        details = []
        period = nil
        doc.css("div.contento").children.reverse.each do |element|
          break if element.name == 'div'
          break if element['class'] != nil
          data = element.text().strip
          details = [data] + details if not data.empty?
        end
        event['details'] = details.reverse().join("\n")
        event_schedule_url = [@host_url, category_name, 'event', event_id, 'schedule'].join('/')
        doc = Nokogiri::HTML( open(event_schedule_url) )
        event_dates = doc.css("div.single div.line-choice select option")
        event_dates.each do |event_date|
          event['date'] = event_date['value']
          event_schedule_url = [@host_url, category_name, 'event', event_id, 'schedule', event['date']].join('/')
          doc = Nokogiri::HTML( open(event_schedule_url) )
          event_places = doc.css("div.line-schedule div.shedule")
          event_places.each do |event_place|
            place_type = event_place.css("a.as")[0]['href'].split('/')[1]
            place_id   = event_place.css("a.as")[0]['href'].split('/')[-1]
            place = get_place( place_type, place_id )
            event['city'] = "Москва"
            event['place'] = place['name']
            event['address'] = place['address']
            #######################
            #######################
            puts_event( event )####
            #######################
            #######################
          end
        end
      end
    end
  end
end

category_parse("cinema")

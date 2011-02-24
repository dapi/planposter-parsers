$KCODE = 'u'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'json'

#$stdout = File.open('output.json', 'w')

@categories = [
  'childs',
  'theatre',
  'music',
  'clubs',
  'cinema',
  'city'
]

@category_translate = {
  'childs'  => 'Дети',
  'theatre' => 'Театр',
  'music'   => 'Концерты',
  'clubs'   => 'Клубы',
  'cinema'  => 'Кино',
  'city'    => 'Город'
}

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
        'name'    => @places[place_type][place_id]['name'],
        'address' => @places[place_type][place_id]['address']
      }
      return place
    end
  else
    @places[place_type] = {}
  end
  
  place_url = [@host_url, place_type, 'place', place_id].join('/')
  doc = Nokogiri::HTML( open(place_url) )
  doc = doc.css("div[class='vcard context'] div.single").first()
  place['name'] = doc.css("div.headingH2 h1").text().strip
  place['address'] = doc.css("div.contento p.adr").text().strip
  @places[place_type][place_id] = place
  return place
end

begin
  @events_details = YAML.load_file('events_details.yml')
rescue
  @events_details = {}
end

def get_event_details( event_category, event_id )
  result = {}
  if @events_details.include?(event_category)
    if @events_details[event_category].include?(event_id)
      result = {
        'image_url' => @events_details[event_category][event_id]['image_url'],
        'details'   => @events_details[event_category][event_id]['details'],
        'period'    => @events_details[event_category][event_id]['period']
      }
      return result
    end
  else
    @events_details[event_category] = {}
  end
  
  event_url = [@host_url, event_category, 'event', event_id].join('/')
  doc = Nokogiri::HTML( open(event_url) )
  doc = doc.css("div[class='vcard context'] div.single").first()
  image_element = doc.css("div#fpic img").first()
  result['image_url'] = image_element['src'] if image_element != nil
  details = []
  period = nil
  doc.css("div.contento").children.reverse.each do |element|
    break if element.name == 'div'
    break if element['class'] != nil
    data = element.text().strip
    data.gsub!(/\s+/, ' ')
    if not data.scan(/^Продолжительность:/).empty?
      period = data.scan(/\d+/).join().to_i
      next
    end
    details = [data] + details if not data.empty?
  end
  result['details'] = details.join("\n")
  result['period']  = period
  result['dump']    = doc.css("div.contento").to_s
  @events_details[event_category][event_id] = result
  return result
end

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
      next if event['class'].scan(/kino|teatr/).empty?
      result_event = {}
      result_event['source']    = @host_url
      result_event['url']       = [category_url]
      result_event['date']      = date['value']
      result_event['dump_type'] = 'text'
      
      result_event['dump'] = [event.css("h3").to_s]
      if event.css("h3 a").empty?
        event_id = nil
      else
        event_id = event.css("h3 a").first()['href'].split('/')[-1]
        result_event['url'] += [ @host_url+event.css("h3 a").first()['href'] ]
      end
      result_event['subject'] = event.css("h3 i").text().strip
      result_event['category'] = @category_translate[category_name]
      
      if event_id
        event_category = event.css("h3 a").first()['href'].split('/')[1]
        details = get_event_details( event_category, event_id )
        result_event['details']   = details['details']
        result_event['image_url'] = details['image_url']
        result_event['period']    = details['period']
        result_event['dump']     += [details['dump']]
      end
      
      event_dump = result_event['dump']
      event.css("div[class~='w-row']").each do |point|
        place_type = point.css("a.w-place").first()['href'].split('/')[1]
        place_id   = point.css("a.w-place").first()['href'].split('/')[-1]
        place = get_place( place_type, place_id )
        result_event['city']    = "Москва"
        result_event['place']   = place['name']
        result_event['address'] = place['address']
        result_event['dump']    = event_dump + [point.to_s]
        times = point.css(".w-time-lime").text().split(',')
        times.each do |time|
          result_event['time'] = time.strip
          #####################################
          #####################################
          puts "#{result_event.to_json},\n"####
          #####################################
          #####################################
        end
      end
      
    end
  end
end

#category_parse('cinema')

puts "[\n"
@categories.each { |x| category_parse(x) }
puts "]"

places_yml = File.open('places.yml', 'w')
places_yml.write( @places.to_yaml )
places_yml.close()

events_details_yml = File.open('events_details.yml', 'w')
events_details_yml.write( @events_details.to_yaml )
events_details_yml.close()

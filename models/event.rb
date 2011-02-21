class Event
  include DataMapper::Resource

  property :id,         Serial
  property :subject,    String
  property :date,       Date
  property :time,       Time
  property :period,     Integer
  property :created_at, DateTime
  property :address,    String
  property :category,   String


  def create_from_parser(data)
    
  end

end

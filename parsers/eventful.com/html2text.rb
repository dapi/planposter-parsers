class SAXParser < Nokogiri::XML::SAX::Document
    attr :text
  
    def initialize
      @text = ""
    end
    
    def characters(string)
      @text += string.gsub(/\s+/m, ' ')
    end
    
    def end_element(name)
      case name
      when 'br', 'div', 'p'
        @text += "\n"
      end
    end
    
    def start_element(name, attrs = [])
      case name
      when 'div', 'p'
        @text += "\n"
      end
    end
    
    def end_document
      @text = @text.squeeze(' ').gsub(/([ ]\n[ ])|(\n[ ])|([ ]\n)/m,"\n").gsub(/\n{3,}/m,"\n\n").strip
    end
end


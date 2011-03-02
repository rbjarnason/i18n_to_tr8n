module I18nToTr8n
  class I18nTr8nConvertor
    attr_accessor :text
    
    GETTEXT_VARIABLES = /\%\{(\w+)\}*/
    
    def initialize(text, namespace = nil)
      @text = text
      @namespace = namespace
    end
    
    # The contents of the method call
    def contents
      #if result = /\_\([\"\']?([^\'\"]*)[\"\']?.*\)/.match(@text)
      
      #if result = /\_\(([\']?([^\']*)[\'])|([\"]?([^\"]*)[\"])?.*\)/.match(@text)
#      single_quotes = /\(\'([^']*)\'\,/.match(@text)
#      double_quotes = /\(\"([^"]*)\"\,/.match(@text)
      single_quotes = /\'([^']*)\'/.match(@text)
      double_quotes = /\"([^"]*)\"/.match(@text)
      symbol = /\:([^"]*)\)/.match(@text)
      
#      puts @text
      
      if single_quotes
#        puts "single"
        return single_quotes[1].strip
      elsif double_quotes
#        puts "double"
        return double_quotes[1].strip
      elsif symbol
#        puts "symbol"
        return symbol[1].strip
      else
#        puts "nil"
        return "nil"
      end
    end

    def contents_i18n
      c = contents
      unless c.nil?
        c.gsub!(GETTEXT_VARIABLES, '{{\1}}')
        c.gsub!(/^(\"|\')/, '')
        c.gsub!(/(\"|\')$/, '')
      else
        puts "No content: " + @text
        
      end
      c
    end
    

    
    # Returns the part after the method call, 
    # _('aaa' % :a => 'sdf', :b => 'agh') 
    # return :a => 'sdf', :b => 'agh'
    def variable_part
      @variable_part_cached ||= begin
#          result = /\%[\s]+\,(.*)\)/.match(@text)
          result = /\,(.*)\)/.match(@text)
          if result
              result[1].strip
          end
      end
    end
    
    # Extract the variables out of a gettext variable part
    # We cannot simply split the variable part on a comma, because it
    # can contain gettext calls itself.
    # Example: :a => 'a', :b => 'b' => [":a => 'a'", ":b => 'b'"]
    def get_variables_splitted
      return if variable_part.nil? 
      in_double_quote = in_single_quote = false
      method_indent = 0  
      s = 0
      vars = []
      variable_part.length.times do |i|
        token = variable_part[i..i]
        in_double_quote = !in_double_quote if token == "\""
        in_single_quote = !in_single_quote if token == "'"
        method_indent += 1 if token == "("
        method_indent -= 1 if token == ")"
        if (token == "," && method_indent == 0 && !in_double_quote && !in_single_quote) || i == variable_part.length - 1
          e = (i == variable_part.length - 1) ? (i ) : i - 1
          vars << variable_part[s..e]
          s = i + 1
        end
      end
      return vars
    end
    
    # Return a array of hashes containing the variables used in the
    # gettext call.
    def variables
      @variables_cached ||= begin
        vsplitted = get_variables_splitted
        return nil if vsplitted.nil?
        vsplitted.map! { |v| 
          r = v.match(/\s*:(\w+)\s*=>\s*(.*)/)
          {:name => r[1], :value => I18nTr8nConvertor.string_to_i18n(r[2], @namespace)}
        }
      end
    end
    
    # After analyzing the variable part, the variables
    # it is now time to construct the actual i18n call
    def to_i18n
      I18n.locale = "en"
#      puts "to_translate: #{self.contents} #{I18n.locale.to_s}"
      i18nified = I18n.t(self.contents)
#      puts "translated: #{i18nified}"
      if i18nified.instance_of?(String)
        i18nified_text = i18nified
      elsif i18nified.instance_of?(Hash)
        i18nified_text = "HASH"
        puts "HASH #{self.contents} #{i18nified}"
      else
        raise "Wrong type for I18n translate"
      end
      i18nified_text = i18nified_text.gsub("%{","{")
      output = "tr(\"#{i18nified_text}\",\"\""
      if !self.variables.nil?
          vars = self.variables.collect { |h| {:name => h[:name], :value => h[:value] }}
          output += ", " + vars.collect {|h| ":#{h[:name]} => #{h[:value]}"}.join(", ")
      end
#      output += ", " + @namespace.to_i18n_scope
      output += ")"
      return output
    end
    
    # Takes the gettext calls out of a string and converts
    # them to i18n calls
    def self.string_to_i18n(text, namespace)
      s = self.indexes_of(text, /t\(/)
      e = self.indexes_of(text, /\)/)
      r = self.indexes_of(text, /\(/)
      
      indent, indent_all,startindex, endinde, methods  = 0, 0, -1, -1, []
      
      output = ""
      level = 0
      gettext_blocks = []
      text.length.times do |i|
        token = text[i..i]
       
        in_gettext_block = gettext_blocks.size % 2 == 1
        if !in_gettext_block
          if ! /t\(/.match(token + text[i+1..i+1]).nil?
            gettext_blocks << i
            level = 0
          end
        else # in a block
          level += 1 if ! /\(/.match(token).nil? && gettext_blocks[gettext_blocks.length - 1] != i - 1
          gettext_blocks << i if level == 0 && /\)/.match(token)
          level -= 1 if /\)/.match(token) && level != 0
        end
      end
      
      i = 0
      output = text.dup
      offset = 0
      
      (gettext_blocks.length / 2).times do |i|
        
        s = gettext_blocks[i * 2]
        e = gettext_blocks[i * 2 + 1]
        to_convert = text[s..e]
       
        if [" ","=",".","{","(",","].include?(text[s-1..s-1]) 
          converted_block = I18nTr8nConvertor.new(to_convert, namespace).to_i18n
        else
          converted_block = to_convert
        end
          g = output.index(to_convert) - 1
          
          h = g + (e-s) + 2
        output = output[0..g] + converted_block + output[h..output.length]
      end
      output = output.gsub("I18n.","")
      output
    end    
    
    private 
    
    # Finds indexes of some pattern(regexp) in a string
    def self.indexes_of(str, pattern)
      indexes = []
      str.length.times do |i|
        match = str.index(pattern, i)
        indexes << match if !indexes.include?(match)
      end
      indexes
    end
    
  end
end
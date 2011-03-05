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
    
    def create_tr8n_translation_key(label)
      puts @namespace.to_i18n_scope
      key = Tr8n::TranslationKey.find_or_create(label,@namespace.to_tr8n_scope)
      puts key.inspect
      key
    end
    
    def create_tr8n_translation(key,label,to_locale,translator_email)
      current_language = Tr8n::Language.for(to_locale)
      current_translator = Tr8n::Translator.find_or_create(User.find_by_email(translator_email))
      translations = key.translations_for(current_language)
      source_url = "localhost"    
      translation = Tr8n::Translation.new(:translation_key => key, :language => current_language, :translator => current_translator)
    
      translation.label = label

      if translation.blank?
        puts "Your translation was empty and was not accepted"
        return
      end
      
      unless translation.uniq?
        puts "There already exists such translation for this phrase. Please vote on it instead or suggest an elternative translation."
        return
      end
      
      unless translation.clean?
        puts "Your translation contains prohibited words and will not be accepted"
        return 
      end

      translation.save_with_log!(current_translator)
      translation.reset_votes!(current_translator)
      puts "Saved translation #{translation}"      
    end
    
    def create_tr8n_permutations(key,label_one,label_many,to_locale,translator_email,count_token)
      current_language = Tr8n::Language.for(to_locale)
      current_translator = Tr8n::Translator.find_or_create(User.find_by_email(translator_email))
      
      puts "Before perm: #{current_language} #{current_translator} #{{"dependencies"=>{count_token=>{"number"=>"true"}}}}"
      new_translations = key.generate_rule_permutations(current_language, current_translator, {count_token=>{"number"=>"true"}})
      puts "new_translations #{new_translations}"
      if new_translations.nil? or new_translations.empty?
        puts "ERROR: new_translations empty"
      end
      new_translations.each do |translation|
        if translation.rules.first[:rule] and translation.rules.first[:rule].definition["part1"]=="is"
          translation.label = label_one
          translation.save
          puts "Created permution: #{translation.inspect}"
        elsif translation.rules.first[:rule] and translation.rules.first[:rule].definition["part1"]=="is_not"
          translation.label = label_many
          translation.save
          puts "Created permution: #{translation.inspect}"
        end
      end
    end
    
    def get_first_in_hash(hash)
      hash.each do |a,b|
        return b
      end
    end
    
    def get_i18nified_text(i18nified)
      if i18nified.instance_of?(String)
        i18nified_text = i18nified
      elsif i18nified.instance_of?(Hash)
        puts "HASH #{self.contents} #{i18nified}"
        if i18nified[:one] and i18nified[:other]
          i18nified_text = i18nified[:other]
        else
          i18nified_text = get_first_in_hash(i18nified)
        end
      else
        raise "Wrong type for I18n translate"
      end
      i18nified_text = gsub_all(i18nified_text)
    end

    def gsub_all(text)
      text.gsub("%{","{").gsub("\#{","{").squeeze(" ").strip
    end

    # After analyzing the variable part, the variables
    # it is now time to construct the actual i18n call
    def to_i18n
      output = ""
      ActiveRecord::Base.transaction do
        I18n.locale = "en"
        puts "to_translate: #{self.contents} #{I18n.locale.to_s}"
        i18nified = I18n.t(self.contents)
        puts "translated: #{i18nified}"
        i18nified_text = label = get_i18nified_text(i18nified)      
        translation_key = create_tr8n_translation_key(i18nified_text)
        roberts_email = "vefur@skuggathing.is"
        francoise_email = "firana18@hotmail.com"
  
        I18n.locale = "en"
        i18nified = I18n.t(self.contents)
        label = get_i18nified_text(i18nified)      
        puts "translated: #{label}"
        create_tr8n_translation(translation_key,label,I18n.locale.to_s,roberts_email)
        create_tr8n_permutations(translation_key,gsub_all(i18nified[:one]),gsub_all(i18nified[:other]),I18n.locale.to_s,roberts_email,"count") if i18nified.instance_of?(Hash) and i18nified[:one] and i18nified[:other]
  
        I18n.locale = "is"
        i18nified = I18n.t(self.contents)
        label = get_i18nified_text(i18nified)
        puts "translated: #{label}"
        unless label.include?("translation missing")    
          create_tr8n_translation(translation_key,label,I18n.locale.to_s,roberts_email)
          create_tr8n_permutations(translation_key,gsub_all(i18nified[:one]),gsub_all(i18nified[:other]),I18n.locale.to_s,roberts_email,"count") if i18nified.instance_of?(Hash) and i18nified[:one] and i18nified[:other]
        end
  
        I18n.locale = "fr"
        i18nified = I18n.t(self.contents)
        label = get_i18nified_text(i18nified)      
        puts "translated: #{label}"
        unless label.include?("translation missing")    
          create_tr8n_translation(translation_key,label,I18n.locale.to_s,francoise_email)
          create_tr8n_permutations(translation_key,gsub_all(i18nified[:one]),gsub_all(i18nified[:other]),I18n.locale.to_s,francoise_email,"count") if i18nified.instance_of?(Hash) and i18nified[:one] and i18nified[:other]
        end
  
        I18n.locale = "de"
        i18nified = I18n.t(self.contents)
        label = get_i18nified_text(i18nified)      
        puts "translated: #{i18nified}"
        unless label.include?("translation missing")    
          create_tr8n_translation(translation_key,label,I18n.locale.to_s,roberts_email)
          create_tr8n_permutations(translation_key,gsub_all(i18nified[:one]),gsub_all(i18nified[:other]),I18n.locale.to_s,roberts_email,"count") if i18nified.instance_of?(Hash) and i18nified[:one] and i18nified[:other]
        end
  
        output += "tr(\"#{gsub_all(i18nified_text)}\", \"#{@namespace.to_tr8n_scope}\""
        if !self.variables.nil?
          vars = self.variables.collect { |h| {:name => h[:name], :value => h[:value] }}
          output += ", " + vars.collect {|h| ":#{h[:name]} => #{h[:value]}"}.join(", ")
        end
        output += ")"
      end
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
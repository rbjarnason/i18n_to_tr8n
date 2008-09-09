module GettextToI18n
  class Convertor
   
   GETTEXT_METHOD = /\_\(([\''\%\{\}\=\>\:a-zA-Z0-9 \"]*)\)/
 
  # GETTEXT_VARIABLE_CONTENTS = /:(\w+)[ *]\=\>[ *]([a-zA-Z\_\-\:\'\(\)\"\.\#]+)/
  
   
   
   attr_reader :translations
   
   def initialize(file, translations, type, options = {})
     @type = type
     @translations = translations
     @file = file
     @options = options
   end
   
   def transform!
     File.read(@file).each do |line|
       
       # check if there is a gettext method in this line
       # TODO multiple line methods
       if result = get_translation_and_id(line)
          contents = I18nHelper.convert_contents(result[:contents])
          add_translation(result[:id], contents)
          # get namespace we live in
          i18n_namespace = I18nHelper.get_namespace([@type, Convertor.get_name(@file, @type)])
          i18ncall = I18nHelper.construct_call(result[:id], line, i18n_namespace)
          
          
          #puts "-----------"
          puts i18ncall
         
         
       end
     end
   end
   
   # Transforms the line from a gettext method to a i18n method
   # Adds the contents of the method to @translations and returns
   # a new i18n method. in the line
   def get_translation_and_id(line)
     if content = get_method_contents(line)
       id = get_id(content)
       return {:id => id, :contents => content}
     else
       return nil
     end
   end
   
   # Get the contents between the gettext method
   # Example: _('a') => \'a\'
   def get_method_contents(line)
     if result = GETTEXT_METHOD.match(line)
       return result[1]
     end
   end
   
   # generates an id for the content of the method
   def get_id(contents)
     id = "message_%s" % (get_namespace_translation_array.size)
     get_namespace_translation_array.each do |i,v|
       id = i if v == contents
     end
     
     return id
   end
   
   

   
   # Add translation, id cannot be used twice
   def add_translation(id, translation)
     get_namespace_translation_array[id] = translation
   end
   
   
   def get_namespace_translation_array
     file_name = Convertor.get_name(@file, @type)
     @translations[@type] = {} if @translations[@type].nil?
     @translations[@type][file_name] = {} if @translations[@type][file_name].nil?
     @translations[@type][file_name]
   end
   
 
   

   
 
   
   private
   
   # returns a name for a file
   # example: 
   # Base.get_name('/controllers/apidoc_controller.rb', 'controller') => 'apidoc'
   def self.get_name(file, type)
     case type
       
       when :controller
         if result = /application\.rb/.match(file)
           return 'application'
         else
           result = /([a-zA-Z]+)_controller.rb/.match(file)
           return result[1]
         end
         return ""
       when :helper
         result = /([a-zA-Z]+)_helper.rb/.match(file)
         return result[1]
       when :view
         result = /views\/([\_a-zA-Z]+)\//.match(file)
         return result[1]
     end
   end
   
   
 end
end
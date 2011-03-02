# Include hook code here
#require 'lib/gettext_to_i18n'
#require 'YAML'
#require File.dirname(__FILE__) + '/../../../config/boot'
require File.dirname(__FILE__) + '/lib/files'



require File.dirname(__FILE__) + '/lib/namespace'
require File.dirname(__FILE__) + '/lib/i18n_tr8n_convertor'
require File.dirname(__FILE__) + '/lib/base'

puts test_str = "<blah>blah blah <%= test('fdfdfd') %> ddfs <%= t('totranslate') %>fdsj <%=t(:totranfdsfdsdfsslate) %> fjds<%=t('totranfdsfds{dd}slate', :dd => 44) %>fksdj</blah> t( :symbi )"
puts I18nToTr8n::I18nTr8nConvertor.string_to_i18n(test_str,nil)

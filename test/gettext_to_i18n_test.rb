require 'test/unit'
require File.dirname(__FILE__) + '/../init.rb'
require 'YAML'

class I18nToTr8nTest < Test::Unit::TestCase
  def setup
    #@c = I18nToTr8n::Convertor.new(nil,nil,nil,nil)
  end
  def test_all_files
    files = I18nToTr8n::Files.all_files
    assert_not_nil files, "no files available"
    assert files.size > 0
   end
   
   
  def test_controller_files
    files = I18nToTr8n::Files.controller_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  
  def test_view_files
    files = I18nToTr8n::Files.view_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  
  def test_helper_files
    files = I18nToTr8n::Files.helper_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  def test_lib_files
    files = I18nToTr8n::Files.lib_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  
  def test_get_filename
    assert_equal 'apidoc', I18nToTr8n::Base.get_name('/controllers/apidoc_controller.rb', :controller)
    assert_equal 'application', I18nToTr8n::Base.get_name('/controllers/application.rb', :controller)
    assert_equal 'page', I18nToTr8n::Base.get_name('/views/page/index.html.erb', :view)
  end
  
  
  
  def test_transform
    a = I18nToTr8n::Base.new
    #puts a.dump_yaml
  end
   
  
 

 
  
end

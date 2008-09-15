require 'test/unit'
require File.dirname(__FILE__) + '/../init.rb'
require 'YAML'

class GettextToI18nTest < Test::Unit::TestCase
  def setup
    @c = GettextToI18n::Convertor.new(nil,nil,nil,nil)
  end
  def test_all_files
    files = GettextToI18n::Files.all_files
    assert_not_nil files, "no files available"
    assert files.size > 0
   end
   
   
  def test_controller_files
    files = GettextToI18n::Files.controller_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  
  def test_view_files
    files = GettextToI18n::Files.view_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  
  def test_helper_files
    files = GettextToI18n::Files.helper_files
    assert_not_nil files, "no files available"
    assert files.size > 0
  end
  
  def test_get_filename
    assert_equal 'apidoc', GettextToI18n::Convertor.get_name('/controllers/apidoc_controller.rb', :controller)
    assert_equal 'application', GettextToI18n::Convertor.get_name('/controllers/application.rb', :controller)
    assert_equal 'page', GettextToI18n::Convertor.get_name('/views/page/index.html.erb', :view)
  end
  
  
  
  def test_transform
    a = GettextToI18n::Base.new
    #puts a.dump_yaml
  end
   
  
  def test_line_transform
    convertor = GettextToI18n::Convertor.new('test', {}, :controller)  
    assert_equal "a", convertor.get_method_contents("_(a)")
    assert_equal "\"some translation\"", convertor.get_method_contents('_("some translation")')
    assert_equal '{"%{some}" % {:some => s}', convertor.get_method_contents('_({"%{some}" % {:some => s})')
    assert_nil convertor.get_method_contents('jes jes _(')
    
    line = "<%=link_to_fp_share image_tag(\"controlbar/icon-share.gif\"), :title => _('Sharing options') %>"
    assert_equal "'Sharing options'", convertor.get_method_contents(line)
    assert_equal [], GettextToI18n::GettextHelper.get_method_vars(line)
    
    
    line = "<%=_(\"You have %{days} days left of your trial period. Click %{link} to setup payments.\" % {:days => current_user.membership.days_till_end_trial, :link => link_to(_('here'), :controller => \"account\", :action => \"payment_subscription\") }) %>"
    assert GettextToI18n::GettextHelper.get_method_vars(line).size == 1
    
  end

 
  
end

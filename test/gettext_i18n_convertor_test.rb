require 'test/unit'
require File.dirname(__FILE__) + '/../init.rb'
require 'YAML'

module I18nToTr8n
  class GettextI18nTest < Test::Unit::TestCase
    
   
    
    def test_other_string
      assert_equal 'a   ', I18nTr8nConvertor.new("_('a   ')").contents
      #assert_equal 'a   ', I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd'})").contents
      assert_equal ":a => 'sdasd'", I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd'})").variable_part
    end
  
  
    def test_variables
      assert_equal ":a => 'sdasd', :b => 'sdasd'", I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd', :b => 'sdasd'})").variable_part
      assert_equal [{:name => "a", :value => "'sdasd'"}, {:name => "b", :value => "'sdasd'"}], I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd', :b => 'sdasd'})").variables
      assert_equal "t(:message_0, :a => 'sdasd', :scope => [:somenamespace])", I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd'})", Namespace.new("somenamespace")).to_i18n
      assert_equal "t(:message_0, :a => 'sdasd', :b => 'sd', :scope => [:somenamespace])", I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasd', :b => 'sd'})", Namespace.new("somenamespace")).to_i18n
      assert_equal ":a => 'sdf' + _(sdf)", I18nTr8nConvertor.new("_('aaa' % {:a => 'sdf' + _(sdf)}) %>", Namespace.new("somenamespace")).variable_part
    end
    
    def test_multiple_variables
      assert_equal "<%=t(:message_0, :a => 'sdf', :b => 'agh', :scope => [:somenamespace]) %>", I18nTr8nConvertor.string_to_i18n("<%=_('aaa' % {:a => 'sdf', :b => 'agh'}) %>", Namespace.new("somenamespace")) 
    end
    
    
    def test_recursive_gettext
      t = I18nTr8nConvertor.new("<%=_('aaa' % {:a => 'sdf' + _(sdfg) + _(sdfg), :b => '21'}) %>", Namespace.new("somenamespace"))
      assert_equal ":a => 'sdf' + _(sdfg) + _(sdfg), :b => '21'", t.variable_part
      assert_equal [{:value=>"'sdf' + t(:message_0, :scope => [:somenamespace]) + t(:message_1, :scope => [:somenamespace])", :name=>"a"},  {:value=>"'21'", :name=>"b"}], t.variables
      
      assert_equal "<%=t(:message_0, :a => 'sdf' + t(:message_1, :scope => [:somenamespace]) + t(:message_2, :scope => [:somenamespace]), :scope => [:somenamespace]) %>", I18nTr8nConvertor.string_to_i18n("<%=_('aaa' % {:a => 'sdf' + _(sdfg) + _(sdfg)}) %>", Namespace.new("somenamespace")) 
    
    end
    
    
    def test_variable_parts
      assert_equal "t(:message_0, :a => 'sdasddd', :b => 'sdasd' + t(:message_1, :scope => [:somenamespace]), :scope => [:somenamespace])" , I18nTr8nConvertor.new("_('a   ' % {:a => 'sdasddd', :b => 'sdasd' + _('sfd')})", Namespace.new("somenamespace")).to_i18n
    end
    
    
    def test_exceptions
      str = "<%=_(\"Invoice: %{desc}\" % {:desc => @invoice.description}) %>"
      t = I18nTr8nConvertor.new(str, Namespace.new("some"))
      
      
      str = "_(\"Information about advertising will soon follow, in the mean time, %{contact}.\" % {:contact => link_to(_(\"please contact us\"), contact_path)})"
      t = I18nTr8nConvertor.new(str, Namespace.new("some"))
      
      assert_equal ":contact => link_to(_(\"please contact us\"), contact_path)", t.variable_part
#      assert_equal [{:value=>"link_to(t(:message_0, :scope => [:some]), contact_path)", :name=>"contact"}], t.variables
      
    end
    
    
    def test_greedyness
      str = "_(\"%{project_name} (copy)\") % {:project_name => @project.name}"
      t= I18nTr8nConvertor.string_to_i18n(str, Namespace.new('d'))
      r = I18nTr8nConvertor.new(str, Namespace.new('sdf'))
    end
    
    
    def test_some_other_string
      str = "_('For more information on large volume plans, customized solutions or (media) partnerships.')"
      #str =  "_(\"%{project_name} (copy)\" % {:project_name => @project.name})"
      t =  I18nTr8nConvertor.string_to_i18n(str, Namespace.new('d'))
      str = "o << content_tag(:div, _(\"Plan your own home with the free floorplanner\"), :class => \"content\")"
      t =  I18nTr8nConvertor.string_to_i18n(str, Namespace.new('d'))
      puts t
      
    end
    
    
    def test_quotes
      
      n  =I18nToTr8n::Namespace.new("somenamespace")
      str = "_('The easiest way to <span class=\"highlight\">create</span> and<br /> <span class=\"highlight\">share</span> interactive floorplans')"
      t = I18nToTr8n::I18nTr8nConvertor.new(str, n)
      assert_equal 'The easiest way to <span class="highlight">create</span> and<br /> <span class="highlight">share</span> interactive floorplans', t.contents
      puts t.text
      
      
      t = I18nToTr8n::I18nTr8nConvertor.new("_(\"Save\")", n)
      assert_equal "Save", t.contents
      
    end
    
  end
end
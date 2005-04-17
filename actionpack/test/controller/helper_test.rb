require File.dirname(__FILE__) + '/../abstract_unit'

class TestController < ActionController::Base
  attr_accessor :delegate_attr
  def delegate_method() end
  def rescue_action(e) raise end
end

module Fun
  class GamesController < ActionController::Base
    def render_hello_world
      render_template "hello: <%= stratego %>"
    end

    def rescue_action(e) raise end
  end
end

module LocalAbcHelper
  def a() end
  def b() end
  def c() end
end

class HelperTest < Test::Unit::TestCase

  def setup
    # Increment symbol counter.
    @symbol = (@@counter ||= 'A0').succ!.dup

    # Generate new controller class.
    controller_class_name = "Helper#{@symbol}Controller"
    eval("class #{controller_class_name} < TestController; end")
    @controller_class = self.class.const_get(controller_class_name)

    # Generate new template class and assign to controller.
    template_class_name = "Test#{@symbol}View"
    eval("class #{template_class_name} < ActionView::Base; end")
    @template_class = self.class.const_get(template_class_name)
    @controller_class.template_class = @template_class

    # Set default test helper.
    self.test_helper = LocalAbcHelper
  end

  def teardown
    # Reset template class.
    #ActionController::Base.template_class = ActionView::Base
  end


  def test_deprecated_helper
    assert_equal helper_methods, missing_methods
    assert_nothing_raised { @controller_class.helper TestHelper }
    assert_equal [], missing_methods
  end

  def test_declare_helper
    require 'abc_helper'
    self.test_helper = AbcHelper
    assert_equal helper_methods, missing_methods
    assert_nothing_raised { @controller_class.helper :abc }
    assert_equal [], missing_methods
  end

  def test_declare_missing_helper
    assert_equal helper_methods, missing_methods
    assert_raise(MissingSourceFile) { @controller_class.helper :missing }
  end

  def test_declare_missing_file_from_helper
    require 'broken_helper'
    rescue LoadError => e
      assert_nil /\bbroken_helper\b/.match(e.to_s)[1]
  end

  def test_helper_block
    assert_nothing_raised {
      @controller_class.helper { def block_helper_method; end }
    }
    assert template_methods.include?('block_helper_method')
  end

  def test_helper_block_include
    assert_equal helper_methods, missing_methods
    assert_nothing_raised {
      @controller_class.helper { include TestHelper }
    }
    assert [], missing_methods
  end

  def test_helper_method
    assert_nothing_raised { @controller_class.helper_method :delegate_method }
    assert template_methods.include?('delegate_method')
  end

  def test_helper_attr
    assert_nothing_raised { @controller_class.helper_attr :delegate_attr }
    assert template_methods.include?('delegate_attr')
    assert template_methods.include?('delegate_attr=')
  end

  def test_helper_for_nested_controller
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.action = "render_hello_world"
    
    assert_equal "hello: Iz guuut!", Fun::GamesController.process(@request, @response).body
  end

  private
    def helper_methods;   TestHelper.instance_methods      end
    def template_methods; @template_class.instance_methods  end
    def missing_methods;  helper_methods - template_methods end

    def test_helper=(helper_module)
      old_verbose, $VERBOSE = $VERBOSE, nil
      self.class.const_set('TestHelper', helper_module)
      $VERBOSE = old_verbose
    end
end

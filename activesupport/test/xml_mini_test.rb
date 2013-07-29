require 'abstract_unit'
require 'active_support/xml_mini'
require 'active_support/builder'
require 'active_support/core_ext/array'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/big_decimal'

module XmlMiniTest
  class RenameKeyTest < ActiveSupport::TestCase
    def test_rename_key_dasherizes_by_default
      assert_equal "my-key", ActiveSupport::XmlMini.rename_key("my_key")
    end

    def test_rename_key_does_nothing_with_dasherize_true
      assert_equal "my-key", ActiveSupport::XmlMini.rename_key("my_key", :dasherize => true)
    end

    def test_rename_key_does_nothing_with_dasherize_false
      assert_equal "my_key", ActiveSupport::XmlMini.rename_key("my_key", :dasherize => false)
    end

    def test_rename_key_camelizes_with_camelize_true
      assert_equal "MyKey", ActiveSupport::XmlMini.rename_key("my_key", :camelize => true)
    end

    def test_rename_key_lower_camelizes_with_camelize_lower
      assert_equal "myKey", ActiveSupport::XmlMini.rename_key("my_key", :camelize => :lower)
    end

    def test_rename_key_lower_camelizes_with_camelize_upper
      assert_equal "MyKey", ActiveSupport::XmlMini.rename_key("my_key", :camelize => :upper)
    end

    def test_rename_key_does_not_dasherize_leading_underscores
      assert_equal "_id", ActiveSupport::XmlMini.rename_key("_id")
    end

    def test_rename_key_with_leading_underscore_dasherizes_interior_underscores
      assert_equal "_my-key", ActiveSupport::XmlMini.rename_key("_my_key")
    end

    def test_rename_key_does_not_dasherize_trailing_underscores
      assert_equal "id_", ActiveSupport::XmlMini.rename_key("id_")
    end

    def test_rename_key_with_trailing_underscore_dasherizes_interior_underscores
      assert_equal "my-key_", ActiveSupport::XmlMini.rename_key("my_key_")
    end

    def test_rename_key_does_not_dasherize_multiple_leading_underscores
      assert_equal "__id", ActiveSupport::XmlMini.rename_key("__id")
    end

    def test_rename_key_does_not_dasherize_multiple_trailing_underscores
      assert_equal "id__", ActiveSupport::XmlMini.rename_key("id__")
    end
  end

  class ToTagTest < ActiveSupport::TestCase
    def assert_xml(xml)
      assert_equal xml, @options[:builder].target!
    end

    def setup
      @xml = ActiveSupport::XmlMini
      @options = {:skip_instruct => true, :builder => Builder::XmlMarkup.new}
    end

    test "#to_tag accepts a callable object and passes options with the builder" do
      @xml.to_tag(:some_tag, lambda {|o| o[:builder].br }, @options)
      assert_xml "<br/>"
    end

    test "#to_tag accepts a callable object and passes options and tag name" do
      @xml.to_tag(:tag, lambda {|o, t| o[:builder].b(t) }, @options)
      assert_xml "<b>tag</b>"
    end

    test "#to_tag accepts an object responding to #to_xml and passes the options, where :root is key" do
      obj = Object.new
      obj.instance_eval do
        def to_xml(options) options[:builder].yo(options[:root].to_s) end
      end

      @xml.to_tag(:tag, obj, @options)
      assert_xml "<yo>tag</yo>"
    end

    test "#to_tag accepts arbitrary objects responding to #to_str" do
      @xml.to_tag(:b, "Howdy", @options)
      assert_xml "<b>Howdy</b>"
    end

    test "#to_tag should use the type value in the options hash" do
      @xml.to_tag(:b, "blue", @options.merge(type: 'color'))
      assert_xml( "<b type=\"color\">blue</b>" )
    end

    test "#to_tag accepts symbol types" do
      @xml.to_tag(:b, :name, @options)
      assert_xml( "<b type=\"symbol\">name</b>" )
    end

    test "#to_tag accepts boolean types" do
      @xml.to_tag(:b, true, @options)
      assert_xml( "<b type=\"boolean\">true</b>")
    end

    test "#to_tag accepts float types" do
      @xml.to_tag(:b, 3.14, @options)
      assert_xml( "<b type=\"float\">3.14</b>")
    end

    test "#to_tag accepts decimal types" do
      @xml.to_tag(:b, ::BigDecimal.new("1.2"), @options)
      assert_xml( "<b type=\"decimal\">1.2</b>")
    end

    test "#to_tag accepts date types" do
      @xml.to_tag(:b, Date.new(2001,2,3), @options)
      assert_xml( "<b type=\"date\">2001-02-03</b>")
    end

    test "#to_tag accepts datetime types" do
      @xml.to_tag(:b, DateTime.new(2001,2,3,4,5,6,'+7'), @options)
      assert_xml( "<b type=\"dateTime\">2001-02-03T04:05:06+07:00</b>")
    end

    test "#to_tag accepts time types" do
      @xml.to_tag(:b, Time.new(1993, 02, 24, 12, 0, 0, "+09:00"), @options)
      assert_xml( "<b type=\"dateTime\">1993-02-24T12:00:00+09:00</b>")
    end

    test "#to_tag accepts array types" do
      @xml.to_tag(:b, ["first_name", "last_name"], @options)
      assert_xml( "<b type=\"array\"><b>first_name</b><b>last_name</b></b>" )
    end

    test "#to_tag accepts hash types" do
      @xml.to_tag(:b, { first_name: "Bob", last_name: "Marley" }, @options)
      assert_xml( "<b><first-name>Bob</first-name><last-name>Marley</last-name></b>" )
    end

    test "#to_tag should not add type when skip types option is set" do
      @xml.to_tag(:b, "Bob", @options.merge(skip_types: 1))
      assert_xml( "<b>Bob</b>" )
    end

    test "#to_tag should dasherize the space when passed a string with spaces as a key" do
      @xml.to_tag("New   York", 33, @options)
      assert_xml "<New---York type=\"integer\">33</New---York>"
    end

    test "#to_tag should dasherize the space when passed a symbol with spaces as a key" do
      @xml.to_tag(:"New   York", 33, @options)
      assert_xml "<New---York type=\"integer\">33</New---York>"
    end
  end

  class WithBackendTest < ActiveSupport::TestCase
    module REXML end
    module LibXML end
    module Nokogiri end

    setup do
      @xml, @default_backend = ActiveSupport::XmlMini, ActiveSupport::XmlMini.backend
    end

    teardown do
      ActiveSupport::XmlMini.backend = @default_backend
    end

    test "#with_backend should switch backend and then switch back" do
      @xml.backend = REXML
      @xml.with_backend(LibXML) do
        assert_equal LibXML, @xml.backend
        @xml.with_backend(Nokogiri) do
          assert_equal Nokogiri, @xml.backend
        end
        assert_equal LibXML, @xml.backend
      end
      assert_equal REXML, @xml.backend
    end

    test "backend switch inside #with_backend block" do
      @xml.with_backend(LibXML) do
        @xml.backend = REXML
        assert_equal REXML, @xml.backend
      end
      assert_equal REXML, @xml.backend
    end
  end

  class ThreadSafetyTest < ActiveSupport::TestCase
    module REXML end
    module LibXML end

    setup do
      @xml, @default_backend = ActiveSupport::XmlMini, ActiveSupport::XmlMini.backend
    end

    teardown do
      ActiveSupport::XmlMini.backend = @default_backend
    end

    test "#with_backend should be thread-safe" do
      @xml.backend = REXML
      t = Thread.new do
        @xml.with_backend(LibXML) { sleep 1 }
      end
      sleep 0.1 while t.status != "sleep"

      # We should get `old_backend` here even while another
      # thread is using `new_backend`.
      assert_equal REXML, @xml.backend
    end

    test "nested #with_backend should be thread-safe" do
      @xml.with_backend(REXML) do
        t = Thread.new do
          @xml.with_backend(LibXML) { sleep 1 }
        end
        sleep 0.1 while t.status != "sleep"

        assert_equal REXML, @xml.backend
      end
    end
  end
end

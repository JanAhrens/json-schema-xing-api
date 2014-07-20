require 'minitest/autorun'
require_relative '../lib/deep_dereference'

class DeepDereferenceTest < MiniTest::Test
  def test_no_dereference_needed
    schema = { "type" => "string" }
    expected_result = { "type" => "string" }

    result = deep_dereference('LOCAL_FILE', schema)

    assert_equal expected_result, result
  end

  def test_singe_dereference
    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "string" }
      }
    }
    path = File.expand_path('../fixtures/simple.json', __FILE__)
    result = deep_dereference(path, JSON.parse(File.read(path)))

    assert_equal expected_result, result
  end

  def test_should_keep_example
    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "string", "example" => "bla" }
      }
    }

    path = File.expand_path('../fixtures/simple_with_example.json', __FILE__)
    result = deep_dereference(path, JSON.parse(File.read(path)))

    assert_equal expected_result, result
  end
end

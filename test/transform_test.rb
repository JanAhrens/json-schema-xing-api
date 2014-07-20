# -*- coding: utf-8 -*-
require 'minitest/autorun'
require_relative '../lib/transform'

class TransformNumberTest < MiniTest::Test
  def test_should_take_examples
    schema = { "type" => "number" }
    expected_result = { "type" => "number", "example" => 23.5 }

    result = transform(schema, "", 23.5.to_json)

    assert_equal expected_result, result
  end

  def test_existing_examples_have_precedence
    schema = { "type" => "number", "example" => 42.1 }
    expected_result = { "type" => "number", "example" => 42.1 }

    result = transform(schema, '', 23.5.to_json)

    assert_equal expected_result, result
  end
end

class TransformIntegerTest < MiniTest::Test
  def test_should_take_examples
    schema = { "type" => "integer" }
    expected_result = { "type" => "integer", "example" => 5 }

    result = transform(schema, '', 5.to_json)

    assert_equal expected_result, result
  end

  def test_existing_examples_have_precedence
    schema = { "type" => "integer", "example" => 23 }
    expected_result = { "type" => "integer", "example" => 23 }

    result = transform(schema, '', 5.to_json)

    assert_equal expected_result, result
  end
end

class TransformStringTest < MiniTest::Test
  def test_should_take_examples
    schema = { "type" => "string" }
    expected_result = { "type" => "string", "example" => "hello" }

    result = transform(schema, '', "hello".to_json)

    assert_equal expected_result, result
  end

  def test_existing_examples_have_precedence
    schema = { "type" => "string", "example" => "existing" }

    expected_result = { "type" => "string", "example" => "existing"  }

    result = transform(schema, '', "overwrite?".to_json)

    assert_equal expected_result, result
  end

  def test_should_validate_strings_containing_numbers
    # this is a regression
    schema = { "type" => "string", "example" => "1234" }

    result = transform(schema, '')

    assert_equal schema, result
  end
end

class TransformObjectTest < MiniTest::Test
  def test_simple_object
    schema = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer" },
        "bar" => { "type" => "string" }
      },
      "example" => {
        "foo" => 2,
        "bar" => "blubb"
      }
    }

    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer", "example" => 2 },
        "bar" => { "type" => "string", "example" => "blubb" }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_object_deep_nesting
    schema = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer" },
        "bar" => {
          "type" => "object",
          "properties" => {
            "a" => { "type" => "string" }
          }
        }
      },
      "example" => {
        "foo" => 2,
        "bar" => {
          "a" => "blubb"
        }
      }
    }

    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer", "example" => 2 },
        "bar" => {
          "type" => "object",
          "properties" => {
            "a" => { "type" => "string", "example" => "blubb" }
          }
        }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_transform_in_hash_properties
    schema = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer" },
        "bar" => {
          "example" => {"a" => "blubb"},
          "type" => "object",
          "properties" => {
            "a" => { "type" => "string" }
          }
        }
      }
    }

    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "integer" },
        "bar" => {
          "type" => "object",
          "properties" => {
            "a" => { "type" => "string", "example" => "blubb" }
          }
        }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_object_with_pattern_properties
    schema = {
      "type" => "object",
      "patternProperties" => {
        "^[a-z]{2}$" => { "enum" => [nil, "BASIC", "GOOD"]}
      },
      "example" => {
        "de" => "BASIC",
        "fr" => nil
      }
    }

    expected_result = {
      "type" => "object",
      "patternProperties" => {
        "^[a-z]{2}$" => { "enum" => [nil, "BASIC", "GOOD"]}
      },
      "properties" => {
        "de" => { "enum" => [nil, "BASIC", "GOOD"], "example" => "BASIC" },
        "fr" => { "enum" => [nil, "BASIC", "GOOD"], "example" => nil }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_should_not_fail_when_no_examples
    schema = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "string" },
        "bar" => { "type" => "number" }
      }
    }

    expected_result = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "string" },
        "bar" => { "type" => "number" }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_should_remove_properties_without_examples
    schema = {
      "type" => "object",
      "properties" => {
        "foo" => { "type" => "string" },
        "bar" => { "type" => "number" }
      },
      "example" => {
        "bar" => 5
      }
    }

    expected_result = {
      "type" => "object",
      "properties" => {
        "bar" => { "type" => "number", "example" => 5 }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end
end

class TransformArrayTest < MiniTest::Test
  def test_simple_array_transform_to_tuple_validation
    schema = {
      "type" => "array",
      "items" => { "type" => "string" },
      "example" => ["foo", "bar"]
    }
    expected_result = {
      "type" => "array",
      "items" => [
                  { "type" => "string", "example" => "foo" },
                  { "type" => "string", "example" => "bar"}
                 ]
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_should_take_examples_from_outside
    schema = {
      "type" => "array",
      "items" => { "type" => "string" }
    }
    expected_result = {
      "type" => "array",
      "items" => [
                  { "type" => "string", "example" => "foo" },
                  { "type" => "string", "example" => "bar" }
                 ]
    }

    result = transform(schema, '', ["foo", "bar"].to_json)

    assert_equal expected_result, result
  end

  def test_existing_example_has_precedence
    schema = {
      "type" => "array",
      "items" => { "type" => "string" },
      "example" => ["foo", "bar"]
    }
    expected_result = {
      "type" => "array",
      "items" => [{ "type" => "string", "example" => "foo" }, {"type" => "string", "example"=> "bar"}]
    }

    result = transform(schema, '', ['OTHER_STUFF'].to_json)

    assert_equal expected_result, result
  end

  def test_should_transform_items
    schema = {
      "type" => "array",
      "items" => {
        "type" => "object",
        "properties" =>{
          "foo" => { "type" => "string" }
        },
        "example" => { "foo" => "bar" }
      },
    }
    expected_result = {
      "type" => "array",
      "items" => {
        "type" => "object",
        "properties" => {
          "foo" => {"type" => "string", "example" => "bar" }
        }
      }
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_deep_dup
    schema = {
      "type" => "array",
      "items" => { "type" => 'object', 'properties' => {
          "name" => {"type" => ["string", "null"]}}
      },
      "example" => [{"name" => "foo"}, {"name" => nil}]
    }

    expected_result = {
      "type" => "array",
      "items" => [
                  { "type" => "object", "properties" => {"name" => { "type" => "string", "example" => "foo"}} },
                  { "type" => "object", "properties" => {"name" => { "type" => "null", "example" => nil}}}
                 ]
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end
end

class TransformBooleanTest < MiniTest::Test
  def test_should_take_external_examples
    schema = { "type" => "boolean" }
    expected_result = { "type" => "boolean", "example" => false }

    result = transform(schema, '', false.to_json)

    assert_equal expected_result, result
  end
end

class TransformEnumTest < MiniTest::Test
  def test_enums_dont_need_to_be_transformed
    schema = { "enum" => [nil, 5, "A"] }
    expected_result = { "enum" => [nil, 5, "A"] }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_should_take_external_examples
    schema = { "enum" => [nil, 5, "A"] }
    expected_result = { "enum" => [nil, 5, "A"], "example" => 5 }

    result = transform(schema, '', 5.to_json)

    assert_equal expected_result, result
  end
end

class TransformMultipleTest < MiniTest::Test
  def test_no_example
    schema = { "type" => ["string", "null"] }
    expected_result = { "type" => ["string", "null"] }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_rewrite_based_on_example
    schema = { "type" => ["string", "null"], "example" => "hello" }
    expected_result = { "type" => "string", "example" => "hello" }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_should_take_external_example_values
    schema = { "type" => ["string", "null"] }
    expected_result = { "type" => "string", "example" => "hello" }

    result = transform(schema, '', "hello".to_json)

    assert_equal expected_result, result
  end
end

class TransformOneOfTest < MiniTest::Test
  def test_no_example
    schema = { "oneOf" => [{"type"=>"null"}, {"type"=>"string"}]}
    expected_result = { "oneOf" => [{"type"=>"null"}, {"type"=>"string"}]}

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_rewrite_based_on_example
    schema = { "oneOf" => [{"type"=>"null"}, {"type"=>"string"}], "example" => "Hello"}
    expected_result = { "type" => "string", "example" => "Hello" }

    result = transform(schema, '')

    assert_equal expected_result, result
  end
end

class TranformAnyOfTest < MiniTest::Test
  def test_no_example
    schema = { "anyOf" => [
                           {"type"=>"number", "minimum" => 5, "maximum" => 10 },
                           {"type"=>"number", "minimum" => 8, "maximum" => 9}
                          ]
    }
    expected_result = { "anyOf" => [
                                    {"type"=>"number", "minimum" => 5, "maximum" => 10 },
                                    {"type"=>"number", "minimum" => 8, "maximum" => 9}
                                   ]
    }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

  def test_rewrite_based_on_example
    schema = {
      "anyOf" => [
                  {"type"=>"number", "minimum" => 5, "maximum" => 10 },
                  {"type"=>"number", "minimum" => 8, "maximum" => 9}
                 ],
      "example" => 8
    }
    expected_result =  { "type"=>"number", "minimum" => 5, "maximum" => 10, "example" => 8 }

    result = transform(schema, '')

    assert_equal expected_result, result
  end

end

# -*- coding: utf-8 -*-
require 'multi_json'
require 'json-schema'
require 'active_support/core_ext/object'

def from_json(json)
  JSON.parse("[#{json}]").first
end

def transform(schema, pointer, example_value = nil)
  return unless schema

  if schema.has_key?('example') || !example_value.nil?
    example = schema.has_key?('example') ? schema['example'].to_json : example_value
    if !JSON::Validator.validate(schema, example)
      raise "#{pointer}: Value \"#{schema['example'].inspect}\" failed validation against schema \"#{schema.inspect}\""
    end
  end

  if %w(integer boolean number string).include?(schema['type']) || schema.has_key?('enum')
    if !schema.has_key?('example') && !example_value.nil?
      schema.merge!("example" => from_json(example_value))
    end
    schema
  elsif schema['type'] == 'null'
    if !schema.has_key?('example') && !example_value.is_nil?
        # nil is the only possible value for example_value
      schema['example'] = nil
    end
    schema
  elsif schema['type'] == 'array'
    if !schema.has_key?('example') && example_value
      schema.merge!("example" => from_json(example_value))
    end

    if schema.has_key?('example')
      example = schema['example']
    elsif example_value
      example = from_json(example_value)
    end

    if example
      schema['items'] = example.map do |item|
        items = schema['items'].deep_dup
        items.merge('example' => item)
      end
      schema.delete('example')
    end

    if schema["items"].is_a?(Array)
      schema['items'] = schema['items'].map.with_index do |item, index|
        transform(item, "#{pointer}/items/#{index}")
      end
    else
      schema["items"] = transform(schema["items"], "#{pointer}/items")
    end

    schema
  elsif schema['type'] == 'object'
    if schema.has_key?('example')
      examples = schema.delete('example')
    elsif example_value
      examples = from_json(example_value)
    end

    if schema.has_key?('patternProperties') && examples
      schema['properties'] ||= {}
      examples.each do |key, value|
        matches = schema['patternProperties'].select do |pattern, _|
          regex = Regexp.new(pattern)
          regex =~ key
        end
        if matches
          schema['properties'][key] = matches[matches.keys.first].merge("example" => value);
        end
      end
    elsif schema.has_key?('properties') && examples
      schema['properties'] = schema['properties'].inject({}) do |memo, item|
        key, value = item
        if examples.has_key?(key)
          memo[key] = transform(value, "#{pointer}/properties/#{key}", examples[key].to_json)
        end

        memo
      end
    end

    if schema['properties']
      schema['properties'].keys.each do |key|
        schema['properties'][key] = transform(schema['properties'][key], "#{pointer}/properties/#{key}")
      end
    end

    schema
  elsif schema['type'].is_a?(Array)
    if schema['example']
      example = schema['example'].to_json
    elsif example_value
      example = example_value
    end

    if example
      matching_type = schema['type'].find do |type|
        new_schema = schema.dup
        new_schema['type'] = type
        JSON::Validator.validate(new_schema, example)
      end
      schema['type'] = matching_type
      schema['example'] = from_json(example)
    end
    schema
  elsif schema.has_key?('oneOf') || schema.has_key?('anyOf')
    keyword = schema.has_key?('oneOf') ? 'oneOf' : 'anyOf'
    if schema.has_key?('example') || !example_value.nil?
      example = schema.has_key?('example') ? schema['example'] : from_json(example_value)

      index = schema[keyword].find_index do |sub_schema|
        JSON::Validator.validate(sub_schema, example)
      end
      matching_schema = schema[keyword][index]
      schema.delete(keyword)
      schema.delete('example') if schema.has_key?('example')

      schema.merge!(transform(matching_schema, "#{pointer}/oneOf/#{index}", example.to_json))
    end
    schema
  else
    # can't transform yet, so don't exclude
    schema
  end
end

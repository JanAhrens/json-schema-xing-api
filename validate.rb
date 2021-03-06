# -*- coding: utf-8 -*-
require 'rubygems'
require 'json'
require 'json-schema'

schemas = Dir['schemas/**/*.json']

schemas.each do |schema_path|
  fixture_path = schema_path.sub('schemas/', 'fixtures/')

  # model files don't need a fixture file
  next if schema_path =~ /_models/ && !File.exists?(fixture_path)

  data = JSON.parse(File.read(fixture_path))

  if data.keys == ['test_cases']
    tests = data['test_cases']
  else
    tests = {'default' => data}
  end

  puts "#{schema_path} (#{fixture_path})"

  tests.each do |key, test|
    errors = JSON::Validator.fully_validate(schema_path, test, validate_schema: true)
    if errors.empty?
      puts "  \033[32m✔\033[39m #{key}"
    else
      puts "  \033[31m✖\033[39m #{key}"
      errors.each do |e|
        puts "   - #{e}"
      end
    end
  end

  puts ""

end

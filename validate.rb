require 'rubygems'
require 'json'
require 'json-schema'

schemas = Dir['schemas/**/*.json']

schemas.each do |schema_path|
  fixture_path = schema_path.sub('schemas/', 'fixtures/')

  data = JSON.parse(File.read(fixture_path))

  errors = JSON::Validator.fully_validate(schema_path, data, validate_schema: true)
  if errors.empty?
    puts "ok"
  else
    puts "error: #{errors.inspect}"
  end
end

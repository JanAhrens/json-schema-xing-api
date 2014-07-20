require 'json'
def deep_dereference(path, schema)
  if schema['type'] == 'object' && schema.has_key?('properties')
    schema['properties'] = schema['properties'].inject({}) do |rest, item|
      key, value = item
      rest[key] = deep_dereference(path, value)
      rest
    end
    schema
  elsif schema.has_key?('oneOf')
    schema['oneOf'] = schema['oneOf'].map do |sub_schema|
      deep_dereference(path, sub_schema)
    end
    schema
  elsif schema.has_key?('anyOf')
    schema['anyOf'] = schema['anyOf'].map do |sub_schema|
      deep_dereference(path, sub_schema)
    end
    schema
  elsif schema['type'] == 'array' && schema.has_key?('items')
    schema['items'] = deep_dereference(path, schema['items'])
    schema
  elsif schema.keys.include?('$ref')
    file, position = schema['$ref'].split('#')

    old_schema = schema.reject { |k, v| k == '$ref' }

    if file
      referenced_path = File.expand_path("../#{file}", path)
      path = referenced_path
      schema = JSON.parse(File.read(referenced_path))
    end

    if position
      schema = navigate_to(schema, position.split('/'))
    end

    # ensure that keys like example survive the dereferencing
    # {"$ref": "foo.json", "example": "bar"} => {"type": "string", "example": "bar"}
    schema.merge!(old_schema)

    deep_dereference(path, schema)
  else
    schema
  end
end

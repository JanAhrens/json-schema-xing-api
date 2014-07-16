# A primitive JSON schema renderer that renders either just the
# structure of the JSON file or uses the "example" property to fill in
# sample data (if present)

require 'json'
require 'json-schema'
require 'erubis'

def debug(msg)
  #STDERR.puts msg
end

def indent(offset)
  ' ' * ((offset + 1) * 2)
end

def col(offset)
  "col-xs-#{12 - offset} col-xs-offset-#{offset}"
end

def prop(name, has_title)
  "\"<span class=\"#{"has-title" if has_title}\">#{name}</span>\": "
end

def navigate_to(schema, position)
  if position.empty?
    schema
  else
    navigate_to(schema[position[0]], position[1..-1])
  end
end

def render_array(path, schema, offset, name = nil)
  debug("render_array(#{path}, #{schema}, #{offset}, #{name})")
  content = schema['items'] ? render_schema(path, schema['items'], offset+1) : ''
  indent(offset) + "<div class=\"row\" data-type=\"array\">\n" +
    indent(offset+1) + "<div class=\"#{col offset}\">#{prop(name, false) if name}[</div>\n" +
      content +
    indent(offset+1) + "<div class=\"#{col offset}\">]</div>\n" +
  indent(offset) + "</div>\n"
end

def render_object_properties(path, properties, offset)
  debug("render_object_properties(#{path}, #{properties}, #{offset})")
  results = []
  next_offset = offset + 1

  properties.each_with_index do |item, index|
    has_more = properties.keys.length - 1 > index
    key, value = item
    text = ""
    if value.is_a?(Hash) && value['type'] == 'array'
      text << render_array(path, value, offset + 1, key)
    elsif value.is_a?(Hash) && value['type'] == 'object'
      text << render_object(path, value, offset + 1, key, has_more)
    else
      text << indent(offset)+"<div class=\"row\">\n"
      text << indent(offset + 1)+
        "<div class=\"#{col next_offset}\">#{key.inspect}: #{render_schema(path, value, offset+1)}#{"," if has_more}</div>\n"
      text << indent(offset)+"</div>\n"
    end
    results << text
  end

  results.join('')
end

def render_object(path, schema, offset, name = nil, has_more = false)
  debug("render_object(#{path}, #{schema}, #{offset}, #{name}, #{has_more})")

  # there are "object" without "properties" for example:
  #   { "type": "object", "patternProperties": { "^I_": { "type": "integer" } } }
  return '' if schema['type'] == 'object' && !schema['properties']

  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    text = render_object_properties(path, schema['example'], offset)
  else
    if schema['properties']
      text = render_object_properties(path, schema['properties'], offset)
    else
      text = render_object_properties(path, schema, offset)
    end
  end

  has_title = schema['title']

  "<div class=\"row\" data-type=\"object\">\n"+
  "  <div class=\"#{col offset}\">#{prop(name, has_title) if name}{</div>\n" +
    text +
  "  <div class=\"#{col offset}\">}#{"," if has_more}</div>\n" +
  '</div>'
end

def render_string(path, schema, offset)
  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    schema['example'].to_json
  else
    "null"
  end
end

def render_multiple_type(path, schema, offset)
  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    render_schema(path, schema['example'], offset)
  else
    "null"
  end
end

def render_enum(path, schema, offset)
  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    render_schema(path, schema['example'], offset)
  else
    "null"
  end
end

def render_boolean(path, schema, offset)
  "null"
end

def render_oneOf(path, schema, offset)
  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    render_schema(path, schema['example'], offset)
  else
    "null"
  end
end

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

def render_number(path, schema, offset)
  if schema['example']
    JSON::Validator.validate!(schema, schema['example'])
    render_schema(path, schema['example'])
  else
    nil.to_json
  end
end

def render_schema(path, schema, offset)
  debug("render_schema(#{path}, #{schema}, #{offset})")

  if schema.is_a?(Hash)
    if schema['type'] == 'object'
      render_object(path, schema, offset)
    elsif schema['type']== 'array'
      render_array(path, schema, offset)
    elsif schema['type'] == 'string'
      render_string(path, schema, offset)
    elsif schema['type'] == 'boolean'
      render_boolean(path, schema, offset)
    elsif schema['type'] == 'number'
      render_number(path, schema, offset)
    elsif schema['type'].is_a?(Array)
      render_multiple_type(path, schema, offset)
    elsif schema.keys.include?('enum')
      render_enum(path, schema, offset)
    elsif schema.keys.include?('oneOf')
      render_oneOf(path, schema, offset)
    else
      # it's a hash
      render_object(path, schema, offset)
    end
  else
    # assume that we received directly renderable
    schema.to_json
  end
end

path = File.expand_path('../schemas/users/show.json', __FILE__)
schema = JSON.parse(File.read(path))
schema = deep_dereference(path, schema)
content = render_schema(path, schema, 0)
template = File.read(File.expand_path('../template.erb', __FILE__))
erb = Erubis::Eruby.new(template)
puts erb.result(binding());

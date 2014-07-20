# A primitive JSON schema renderer that renders either just the
# structure of the JSON file or uses the "example" property to fill in
# sample data (if present).

# It's an experiment. Please don't expect well written and tested
# code. This is as ugly as it can get!

require 'json'
require 'json-schema'
require 'erubis'
require 'redcarpet'

require_relative './lib/deep_dereference'
require_relative './lib/transform'

def markdown(code)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
  markdown.render(code)
end

def description(schema, offset)
  if schema.has_key?('description')
    "#{indent(offset+1)}<div class=\"#{col offset} description\"><div class=\"alert alert-info\">#{markdown schema['description']}</div></div>"
  else
    ''
  end
end

def description_label(schema)
  schema.has_key?('description') ? " <span class=\"glyphicon glyphicon-info-sign\"></span>" : ''
end

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

def has_description(schema)
  schema.has_key?('description') ? ' has-description' : ''
end

def render_array(schema, offset, name = nil, has_more = false)
  debug("render_array(#{schema}, #{offset}, #{name}, #{has_more})")

  if schema['items'].is_a?(Hash)
    content = render_schema(schema['items'], offset + 1)
  elsif schema['items'].is_a?(Array)
    content = ''
    schema['items'].each_with_index do |item, index|
      has_more_array = schema['items'].length - 1 > index
      content << render_schema(item, offset+1, nil, has_more_array)
    end
  end

  indent(offset) + "<div class=\"row\" data-type=\"array\">\n" +
    indent(offset+1) + "<div class=\"#{col offset}#{has_description schema}\">#{prop(name, false) if name}[#{description_label schema}</div>\n" +
      description(schema, offset) +
      content +
    indent(offset+1) + "<div class=\"#{col offset}\">]#{"," if has_more}</div>\n" +
  indent(offset) + "</div>\n"
end

def render_object_properties(properties, offset)
  debug("render_object_properties(#{properties}, #{offset})")

  results = []

  properties.each_with_index do |item, index|
    has_more = properties.keys.length - 1 > index
    key, value = item
    text = ""

    if value.is_a?(Hash) && value['type'] == 'array'
      text << render_array(value, offset + 1, key, has_more)
    elsif value.is_a?(Hash) && value['type'] == 'object'
      text << render_object(value, offset + 1, key, has_more)
    else
      text << indent(offset)+"<div class=\"row\">\n"
      text << render_schema(value, offset+1, key, has_more)
      text << indent(offset)+"</div>\n"
    end
    results << text
  end

  results.join('')
end

def render_object(schema, offset, name = nil, has_more = false)
  debug("render_object(#{schema}, #{offset}, #{name}, #{has_more})")

  # there are "object" without "properties" for example:
  #   { "type": "object", "patternProperties": { "^I_": { "type": "integer" } } }
  return '' if schema['type'] == 'object' && !schema['properties']

  if schema['example']
    text = render_object_properties(schema['example'], offset)
  else
    if schema['properties']
      text = render_object_properties(schema['properties'], offset)
    else
      text = render_object_properties(schema, offset)
    end
  end

  has_title = schema['title']

  "#{indent(offset)}<div class=\"row\" data-type=\"object\">\n"+
    "#{indent(offset+1)}<div class=\"#{col offset}#{has_description schema}\">#{prop(name, has_title) if name}{#{description_label schema}</div>\n" +
    description(schema, offset) +
    text +
    "#{indent(offset+1)}<div class=\"#{col offset}\">}#{"," if has_more}</div>\n" +
  "#{indent(offset)}</div>\n"
end

def render_multiple_type(schema, offset)
  if schema['example']
    render_schema(schema['example'], offset)
  else
    "null"
  end
end

def render_oneOf(schema, offset)
  if schema['example']
    render_schema(schema['example'], offset)
  else
    "null"
  end
end

def render_schema(schema, offset, name = nil, has_more = nil)
  debug("render_schema(#{schema}, #{offset}, #{name}, #{has_more})")

  if %w(string boolean number null integer).include?(schema['type']) || schema.has_key?('enum')
    text = ''
    has_description = schema.has_key?('description')
    if schema.has_key?('example')
      text << "#{indent offset}<div class=\"#{col offset}#{" has-description" if has_description}\">#{name.inspect + ': ' if name}#{schema['example'].to_json}#{',' if has_more}#{description_label schema}</div>\n"
    end

    text << description(schema, offset)

    text
  elsif schema['type'] == 'object'
    render_object(schema, offset, name, has_more)
  elsif schema['type']== 'array'
    render_array(schema, offset)
  elsif schema['type'].is_a?(Array)
    render_multiple_type(schema, offset)
  elsif schema.keys.include?('oneOf')
    render_oneOf(schema, offset)
  else
    # it's a hash
    render_object(schema, offset)
  end
end

path = File.expand_path('../schemas/users/show.json', __FILE__)
schema = JSON.parse(File.read(path))
schema = deep_dereference(path, schema)
schema = transform(schema, "")
content = render_schema(schema, 0)
template = File.read(File.expand_path('../template.erb', __FILE__))
erb = Erubis::Eruby.new(template)
puts erb.result(binding());

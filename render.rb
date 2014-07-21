# A primitive JSON schema renderer that renders either just the
# structure of the JSON file or uses the "example" property to fill in
# sample data (if present).

# It's an experiment. Please don't expect well written and tested
# code. This is as ugly as it can get!

require 'json-schema/documentation'

include JSON::Schema::Documentation

if ARGV.length < 1;
  STDERR.puts "#{$0} path"
  exit
end

filename = ARGV[0]

path = File.expand_path("../#{filename}", __FILE__)
schema = JSON.parse(File.read(path))
dereferenced_schema = deep_dereference(path, schema.deep_dup)
transformed_schema = transform(dereferenced_schema.deep_dup, "")
content = render_schema(transformed_schema, 0)

template = File.read(File.expand_path('../template.erb', __FILE__))
erb = Erubis::Eruby.new(template)
puts erb.result(binding());

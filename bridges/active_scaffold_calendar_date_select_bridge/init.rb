files = <<EOF.split("\n")
config/core.rb 
helpers/form_column_helpers.rb 
helpers/view_helpers.rb 
EOF

files.each { |file|
  load File.join( File.dirname(__FILE__),"lib", file) 
}
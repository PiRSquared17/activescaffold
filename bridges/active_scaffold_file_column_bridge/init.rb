[
  "config/core.rb", 
  "helpers/form_column_helpers.rb", 
  "helpers/list_column_helpers.rb"
].each { |file|
  load File.join( File.dirname(__FILE__), "lib",file)
}
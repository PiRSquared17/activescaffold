require 'exceptions'
##
## Check for dependencies
##

version = Rails::VERSION::STRING.split(".")
if version[0] < "1" or (version[0] == "1" and version[1] < "2")
  message = <<-EOM
    ************************************************************************
    Rails 1.2.1 or greater is required. Please remove ActiveScaffold or
    upgrade Rails. After you upgrade Rails, be sure to run

    > rake rails:update:javascripts

    to get the newest prototype.js.
    ************************************************************************
  EOM
  ActionController::Base::logger.error message
  puts message
  raise ActiveScaffold::DependencyFailure
end

begin
  Paginator rescue require('paginator')
end

##
## Load the library
##
require 'active_scaffold'
require 'configurable'
require 'finder'
require 'localization'
require 'constraints'

require 'helpers/active_scaffold_helpers'
require 'helpers/id_helpers'
require 'helpers/list_helpers'
require 'helpers/form_helpers'

require 'extensions/action_view'
require 'extensions/action_controller'
require 'extensions/active_record'
require 'extensions/array'
require 'extensions/resources'

##
## Autoloading for some directories
## (this could probably be optimized more -lance)
##
def autoload_dir(directory, namespace)
  Dir.entries(directory).each do |file|
    next if file =~ /^[._]/
    if file =~ /^[a-z_]+.rb$/
      constant = File.basename(file, '.rb').camelcase
      eval(namespace).autoload constant, File.join(directory, file)
    else
      message = "ActiveScaffold: could not autoload #{File.join(directory, file)}"
      RAILS_DEFAULT_LOGGER.error message
      puts message
    end
  end
end

module ActiveScaffold
  module Config; end
  module Actions; end
  module DataStructures; end
end

autoload_dir "#{File.dirname __FILE__}/lib/config", "ActiveScaffold::Config"
autoload_dir "#{File.dirname __FILE__}/lib/actions", "ActiveScaffold::Actions"
autoload_dir "#{File.dirname __FILE__}/lib/data_structures", "ActiveScaffold::DataStructures"

##
## Inject includes for ActiveScaffold libraries
##

ActionController::Base.send(:include, ActiveScaffold)
ActionController::Base.send(:include, ActionView::Helpers::ActiveScaffoldIdHelpers)
ActionController::Base.send(:include, Localization)
ActionView::Base.send(:include, ActionView::Helpers::ActiveScaffoldHelpers)
ActionView::Base.send(:include, ActionView::Helpers::ActiveScaffoldIdHelpers)
ActionView::Base.send(:include, ActionView::Helpers::ActiveScaffoldListHelpers)
ActionView::Base.send(:include, ActionView::Helpers::ActiveScaffoldFormHelpers)

##
## Add MIME type for JSON (backwards compat)
##
unless Mime.const_defined?(:JSON)
  # Rails 1.1 Method
  # Register a new Mime::Type
  Mime::JSON = Mime::Type.new 'application/json', :json, %w( text/json )
  Mime::LOOKUP["application/json"] = Mime::JSON
  Mime::LOOKUP["text/json"] = Mime::JSON

  # Its default handler in responder
  class ActionController::MimeResponds::Responder

    DEFAULT_BLOCKS[:json] = %q{
      Proc.new do
        render(:action => "#{action_name}.rjson", :content_type => Mime::JSON, :layout => false)
      end
    }

    for mime_type in %w( json )
      eval <<-EOT
        def #{mime_type}(&block)
           custom(Mime::#{mime_type.upcase}, &block)
        end
      EOT
    end
  end
end
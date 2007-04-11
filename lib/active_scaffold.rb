module ActiveScaffold
  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      # TODO: these should be in actions/core
      before_filter :handle_user_settings
    end
  end

  def self.set_defaults(&block)
    ActiveScaffold::Config::Core.configure &block
  end

  def active_scaffold_config
    self.class.active_scaffold_config
  end

  def active_scaffold_config_for(klass)
    self.class.active_scaffold_config_for(klass)
  end

  def active_scaffold_session_storage
    id = params[:eid] || params[:controller]
    session_index = "as:#{id}"
    session[session_index] ||= {}
    session[session_index]
  end

  # at some point we need to pass the session and params into config. we'll just take care of that before any particular action occurs by passing those hashes off to the UserSettings class of each action.
  def handle_user_settings
    if self.class.uses_active_scaffold?
      active_scaffold_config.actions.each do |action_name|
        conf_instance = active_scaffold_config.send(action_name) rescue next
        next if conf_instance.class::UserSettings == ActiveScaffold::Config::Base::UserSettings # if it hasn't been extended, skip it
        active_scaffold_session_storage[action_name] ||= {}
        conf_instance.user = conf_instance.class::UserSettings.new(conf_instance, active_scaffold_session_storage[action_name], params)
      end
    end
  end

  module ClassMethods
    def active_scaffold(model_id = nil, &block)
      # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
      model_id = self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore unless model_id

      # run the configuration
      @active_scaffold_config = ActiveScaffold::Config::Core.new(model_id)
      self.active_scaffold_config.configure &block if block_given?
      self.active_scaffold_config._load_action_columns

      # defines the attribute read methods on the model, so record.send() doesn't find protected/private methods instead
      # NOTE define_read_methods is an *instance* method even though it adds methods to the *class*.
      klass = self.active_scaffold_config.model
      klass.new.send(:define_read_methods) if klass.read_methods.empty? && klass.generate_read_methods

      # include the rest of the code into the controller: the action core and the included actions
      module_eval do
        include ActiveScaffold::Finder
        include ActiveScaffold::Constraints
        include ActiveScaffold::AttributeParams
        include ActiveScaffold::Actions::Core
        active_scaffold_config.actions.each do |mod|
          name = mod.to_s.camelize
          include eval("ActiveScaffold::Actions::#{name}") if ActiveScaffold::Actions.const_defined? name

          # sneak the action links from the actions into the main set
          if link = active_scaffold_config.send(mod).link rescue nil
            active_scaffold_config.action_links << link
          end
        end
      end
    end

    def active_scaffold_config
       @active_scaffold_config || self.superclass.instance_variable_get('@active_scaffold_config')
    end

    def active_scaffold_config_for(klass)
      begin
        controller, controller_path = active_scaffold_controller_for(klass)
      rescue ActiveScaffold::ControllerNotFound
        config = ActiveScaffold::Config::Core.new(klass)
        config._load_action_columns
        config
      else
        controller.active_scaffold_config
      end
    end

    # Tries to find a controller for the given ActiveRecord model.
    # Searches in the namespace of the current controller for singular and plural versions of the conventional "#{model}Controller" syntax.
    def active_scaffold_controller_for(klass)
      controller_path = controller_named_path = ""
      error_message = []
      if self.to_s.include?("::")
        path = self.to_s.split('::')
        path.pop # remove the parent controller
        controller_named_path = path.collect{|p| p.capitalize}.join("::") + "::"
        controller_path = path.join("/") + "/"
      end
      ["#{klass.to_s.underscore.pluralize}", "#{klass.to_s.underscore.pluralize.singularize}"].each do |controller_name|
        begin
          controller = "#{controller_named_path}#{controller_name.camelize}Controller"
          controller = controller.constantize
        rescue NameError => error
          # Only rescue NameError associated with the controller constant not existing - not other compile errors
          if error.message["uninitialized constant #{controller}"]
            error_message << controller
            next
          else
            raise
          end
        end
        raise ActiveScaffold::ControllerNotFound, "#{controller} missing ActiveScaffold", caller unless controller.uses_active_scaffold?
        raise ActiveScaffold::ControllerNotFound, "ActiveScaffold on #{controller} is not for #{klass} model.", caller unless controller.active_scaffold_config.model == klass
        return controller, "#{controller_path}#{controller_name}"
      end
      raise ActiveScaffold::ControllerNotFound, "Could not find " + error_message.join(" or "), caller
    end

    def uses_active_scaffold?
      !active_scaffold_config.nil?
    end
  end
end

class Object
  def as_(string_to_localize, *args)
    sprintf string_to_localize, args
  end
end

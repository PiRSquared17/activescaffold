module ActionView::Helpers
  module ActiveScaffoldHelpers
    # easy way to include ActiveScaffold assets
    def active_scaffold_includes
      js = ActiveScaffold::Config::Core.javascripts.collect do |name|
        javascript_include_tag(ActiveScaffold::Config::Core.asset_path(:javascript, name))
      end.join('')

      css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path(:stylesheet, "stylesheet.css"))
      ie_css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path(:stylesheet, "stylesheet-ie.css"))

      js + "\n" + css + "\n<!--[if IE]>" + ie_css + "<![endif]-->\n"
    end

    # access to the configuration variable
    def active_scaffold_config
      @controller.class.active_scaffold_config
    end

    def active_scaffold_nested_associations
      id = params[:eid] || params[:controller]
      session_index = "as:#{id}"
      session[session_index] ||= {}
      session[session_index]
      return session[session_index][:nested_associations]
      # Need to make active_scaffold_session_storage visible to this helper 
      #return @controller.class.active_scaffold_session_storage[:nested_associations]
    end

    ## TODO We should check the the model being used is the same Class
    ##      ie make sure ProductsController doesn't active_scaffold :shoe
    def active_scaffold_config_for(klass)
      controller, controller_path = active_scaffold_controller_for(klass)
      return controller.active_scaffold_config unless controller.nil? or !controller.uses_active_scaffold?

      config = ActiveScaffold::Config::Core.new(klass)
      config._load_action_columns
      config
    end

    # :parent_controller, pass in something like, params[:controller], this will resolve the controller to the proper path for subsequent call to render :active_scaffold or render :component.
    def active_scaffold_controller_for(klass, parent_controller = nil)
  		controller_path = ""
  		controller_named_path = ""
  		if parent_controller
  			path = parent_controller.split('/')
  			path.pop # remove the parent controller
  			controller_named_path = path.collect{|p| p.capitalize}.join("::") + "::"
    		controller_path = path.join("/") + "/"
  		end
      ["#{klass.to_s}", "#{klass.to_s.pluralize}"].each do |controller_name|
        controller = "#{controller_named_path}#{controller_name.camelize}Controller".constantize rescue next
        return controller, "#{controller_path}#{controller_name}"
      end
      nil
    end

    # a general-use loading indicator (the "stuff is happening, please wait" feedback)
    def loading_indicator_tag(options)
      image_tag "/images/active_scaffold/default/indicator.gif", :style => "display:none;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
    end

    def params_for(options = {})
      # :adapter and :position are one-use rendering arguments. they should not propagate.
      # :sort, :sort_direction, and :page are arguments that stored in the session. they need not propagate.
      # and wow. no we don't want to propagate :record.
      # :commit is a special rails variable for form buttons
      blacklist = [:adapter, :position, :sort, :sort_direction, :page, :record, :commit, :_method]
      @params_for ||= params.clone.delete_if { |key, value| blacklist.include? key.to_sym if key }
      @params_for.merge(options)
    end
  end
end
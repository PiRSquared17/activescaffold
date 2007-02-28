module ActionView::Helpers
  module ActiveScaffoldHelpers
    ## TODO We should check the the model being used is the same Class
    ##      ie make sure ProductsController doesn't active_scaffold :shoe
    def active_scaffold_config_for(klass)
      controller.active_scaffold_config_for(klass)
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
  end
end
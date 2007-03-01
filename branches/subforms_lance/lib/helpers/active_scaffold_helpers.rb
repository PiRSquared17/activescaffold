module ActionView::Helpers
  module ActiveScaffoldHelpers
    def active_scaffold_config_for(*args)
      @controller.class.active_scaffold_config_for(*args)
    end

    def active_scaffold_controller_for(*args)
      @controller.class.active_scaffold_controller_for(*args)
    end

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
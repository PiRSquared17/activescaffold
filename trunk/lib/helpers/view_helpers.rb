module ActiveScaffold
  module Helpers
    # All extra helpers that should be included in the View.
    # Also a dumping ground for uncategorized helpers.
    module ViewHelpers
      include ActiveScaffold::Helpers::Ids
      include ActiveScaffold::Helpers::Associations
      include ActiveScaffold::Helpers::Pagination
      include ActiveScaffold::Helpers::ListColumns
      include ActiveScaffold::Helpers::FormColumns

      ##
      ## Delegates
      ##

      # access to the configuration variable
      def active_scaffold_config
        @controller.class.active_scaffold_config
      end

      def active_scaffold_config_for(*args)
        @controller.class.active_scaffold_config_for(*args)
      end

      def active_scaffold_controller_for(*args)
        @controller.class.active_scaffold_controller_for(*args)
      end

      ##
      ## Uncategorized
      ##

      def generate_temporary_id
        (Time.now.to_f*1000).to_i.to_s
      end

      # Turns [[label, value]] into <option> tags
      # Takes optional parameter of :include_blank
      def option_tags_for(select_options, options = {})
        select_options.insert(0,[as_('- select -'),nil]) if options[:include_blank]
        select_options.collect do |option|
          label, value = option[0], option[1]
          value.nil? ? "<option value="">#{label}</option>" : "<option value=\"#{value}\">#{label}</option>"
        end
      end

      # Should this column be displayed in the subform?
      def in_subform?(column, parent_record)
        return true unless column.association

        # Polymorphic associations can't appear because they *might* be the reverse association, and because you generally don't assign an association from the polymorphic side ... I think.
        return false if column.polymorphic_association?

        # We don't have the UI to currently handle habtm in subforms
        return false if column.association.macro == :has_and_belongs_to_many

        # A column shouldn't be in the subform if it's the reverse association to the parent
        return false if column.association.reverse_for?(parent_record.class)
        #return false if column.association.klass == parent_record.class

        return true
      end

      def form_remote_upload_tag(url_for_options = {}, options = {})
        output=""

        output << "<iframe id='#{action_iframe_id(url_for_options)}' name='#{action_iframe_id(url_for_options)}' style='display:none'></iframe>"

        options[:form] = true

        options ||= {}

        onsubmits = options[:onsubmit] ? [ options[:onsubmit] ] : [ ]
        onsubmits << "setTimeout(function() { #{options[:loading]} }, 10); "
        # the setTimeout prevents the Form.disable from being called before the submit.  If that occurs, then no data will be posted.
        onsubmits << "return true"

        # simulate a "loading"
        options[:onsubmit] = onsubmits * ';'
        options[:target] = action_iframe_id(url_for_options)
        options[:multipart] = true

        output << form_tag(url_for_options, options)
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

      # a general-use loading indicator (the "stuff is happening, please wait" feedback)
      def loading_indicator_tag(options)
        image_tag "/images/active_scaffold/default/indicator.gif", :style => "visibility:hidden;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
      end

      def params_for(options = {})
        # :adapter and :position are one-use rendering arguments. they should not propagate.
        # :sort, :sort_direction, and :page are arguments that stored in the session. they need not propagate.
        # and wow. no we don't want to propagate :record.
        # :commit is a special rails variable for form buttons
        blacklist = [:adapter, :position, :sort, :sort_direction, :page, :record, :commit, :_method]
        unless @params_for
          @params_for = params.clone.delete_if { |key, value| blacklist.include? key.to_sym if key }
          @params_for[:controller] = '/' + @params_for[:controller] unless @params_for[:controller].first(1) == '/' # for namespaced controllers
          @params_for.delete(:id) if @params_for[:id].nil?
        end
        @params_for.merge(options)
      end

      # Creates a javascript-based link that toggles the visibility of some element on the page.
      # By default, it toggles the visibility of the sibling after the one it's nested in. You may pass custom javascript logic in options[:of] to change that, though. For example, you could say :of => '$("my_div_id")'.
      # You may also flag whether the other element is visible by default or not, and the initial text will adjust accordingly.
      def link_to_visibility_toggle(options = {})
        options[:of] ||= '$(this.parentNode).next()'
        options[:default_visible] = true if options[:default_visible].nil?

        link_text = options[:default_visible] ? 'hide' : 'show'
        link_to_function as_(link_text), "e = #{options[:of]}; e.toggle(); this.innerHTML = (e.style.display == 'none') ? '#{as_('show')}' : '#{as_('hide')}'", :class => 'visibility-toggle'
      end

      def render_action_link(link, url_options)
        url_options = url_options.clone
        url_options[:action] = link.action
        url_options.merge! link.parameters if link.parameters

        # NOTE this is in url_options instead of html_options on purpose. the reason is that the client-side
        # action link javascript needs to submit the proper method, but the normal html_options[:method]
        # argument leaves no way to extract the proper method from the rendered tag.
        url_options[:_method] = link.method
        
        html_options = {:class => link.action}
        # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails
        html_options[:method] = link.method
        
        html_options[:confirm] = link.confirm if link.confirm?
        html_options[:position] = link.position if link.position and link.inline?
        html_options[:class] += ' action' if link.inline?
        html_options[:popup] = true if link.popup?
        html_options[:id] = action_link_id(url_options[:action],url_options[:id])

        if link.dhtml_confirm?
          html_options[:class] += ' action' if !link.inline?
          html_options[:page_link] = 'true' if !link.inline?
          html_options[:dhtml_confirm] = link.dhtml_confirm.value
          html_options[:onclick] = link.dhtml_confirm.onclick_function(controller,action_link_id(url_options[:action],url_options[:id]))
        end

        link_to link.label, url_options, html_options
      end

      def column_class(column, column_value)
        classes = []
        classes << "#{column.name}-column"
        classes << column.css_class unless column.css_class.nil?
        classes << 'empty' if column_empty? column_value
        classes << 'sorted' if active_scaffold_config.list.user.sorting.sorts_on?(column)
        classes << 'numeric' if column.column and [:decimal, :float, :integer].include?(column.column.type)
        classes.join(' ')
      end

      def column_empty?(column_value)
        column_value.nil? || (column_value.empty? rescue false)
      end

      def column_calculation(column)
        calculation = active_scaffold_config.model.calculate(column.calculate, column.name, :conditions => controller.send(:all_conditions), :include => controller.send(:active_scaffold_joins))
      end
    end
  end
end
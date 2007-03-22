module ActiveScaffold::Config
  class FieldSearch < Base
    def initialize(core_config)
      @core = core_config
    end
      

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_reader :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', :label => _('SEARCH_BUTTON'), :type => :table, :security_method => :search_authorized?)

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Search to use
    def columns
      # we want to delay initializing to the @core.columns set for as long as possible. Too soon and .search_sql will not be available to .searchable?
      unless @columns
        self.columns = @core.columns.collect{|c| c.name if c.searchable?}.compact
      end
      @columns
    end

    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end
  end
end
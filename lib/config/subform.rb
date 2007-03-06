module ActiveScaffold::Config
  class Subform < Base
    def initialize(core_config)
      @core = core_config
    end

    # global level configuration
    # --------------------------

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Sub-Form to use
    def columns
      # we want to delay initializing to the @core.update.columns set for as long as possible. but we have to eventually clone, or else have a configuration "leak"
      @columns ||= @core.update.columns.clone
    end
    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end
  end
end
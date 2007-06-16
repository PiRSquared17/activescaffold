module ActiveScaffold
  module Helpers
    module ViewHelpers

      def active_scaffold_includes_with_calendar_date_select
        active_scaffold_includes_without_calendar_date_select + 
          calendar_date_select_includes
      end
      
      alias_method_chain :active_scaffold_includes, :calendar_date_select
    end
  end
end

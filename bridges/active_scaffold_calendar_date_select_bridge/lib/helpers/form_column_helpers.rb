module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      def active_scaffold_input_calendar_date_select(column, options)
        calendar_date_select("record", column.name, options)
      end      
    end
  end
end
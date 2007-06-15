module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      def active_scaffold_input_file_column(column, options)
        file_column_field("record", column.name, options)
      end      
    end
  end
end
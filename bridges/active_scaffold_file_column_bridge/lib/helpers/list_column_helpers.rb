module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumns
      def render_column_with_file_column(record, column)
        if column_override?(column) || !active_scaffold_config.file_column_fields.include?(column.name.to_sym)
          return render_column_without_file_column(record, column)
        end
        
        value = record.send(column.name)
        return "" if value.nil?
        link_to File.basename(value), url_for_file_column(record, column.name.to_s), :popup => true 
      end
      
      alias_method_chain :render_column, :file_column
    end
  end
end
module ActiveScaffold::Config
  class Core < Base
    attr_accessor :file_column_fields
    def initialize_with_file_column(model_id)
      @file_column_fields||=[]
      
      initialize_without_file_column(model_id)
      
      @file_column_fields = self.model.instance_methods.grep(/_just_uploaded\?$/).collect{|m| m[0..-16].to_sym }
      # check to see if file column was used on the model
      return if @file_column_fields.empty?
      
      self.update.multipart = true
      self.create.multipart = true
      
      # automatically set the forum_ui to a file column
      @file_column_fields.each{|field|
        self.columns[field].form_ui = :file_column
        
        # set null to false so active_scaffold wont set it to null
        # This is a bit hackish
        self.model.columns_hash[field.to_s].instance_variable_set("@null", false)
      }
    end
    
    alias_method_chain :initialize, :file_column
    
  end
end
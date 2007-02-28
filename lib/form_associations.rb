module ActiveScaffold
  module FormAssociations
    # Provides validation and template for displaying association in sub-list
    def add_association
      @association = active_scaffold_config.model.reflect_on_association(params[:id].to_sym)
      @record = find_or_create_for_params(params[@association.klass.to_s.underscore], @association.klass)

      render(:action => 'add_association', :layout => false)
    end

    protected

    # Finds or creates ActiveRecord objects for the associations params (derived from the request
    # params using split_record_params) and tacks them onto the given parent AR model.
    def build_associations(parent_record, columns, associations_params = {})
      return if associations_params.empty?

      columns.each do |column|
        next unless column.association
        next if column.ui_type == :select

        values = associations_params[column.name]
        if [:has_one, :belongs_to].include? column.association.macro
          record_params = values
          record = find_or_create_for_params(record_params, column.association.klass)
          eval "parent_record.#{column.association.name} = record" unless record.nil?
        else
          records = values.values.collect do |record_params|
            find_or_create_for_params(record_params, column.association.klass)
          end.compact rescue []
          eval "parent_record.#{column.association.name} = records"
        end
      end
    end

    # Attempts to create or find an instance of klass (which must be an ActiveRecord object) from the
    # request parameters given. If params[:id] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, klass)
      return nil if params.empty?

      record = nil
      if params.has_key? :id
        record = klass.find(params[:id]) unless params[:id].empty?
      else
        # TODO We need some security checks in here so we don't create new objects when you are not authorized
        attribute_params, associations_params = split_record_params(params,klass)
        record = klass.new(attribute_params)
        build_associations(record, associations_params) unless associations_params.empty?
      end
      record
    end

    # Splits a params hash into two hashes: one of all values that map to an attribute on the given class (klass)
    # and one all the values that map to associations (belongs_to, has_many, etc) on the class.
    def split_record_params(params, klass)
      attribute_params, associations_params = params.dup, {}
      klass.reflect_on_all_associations.each do |association|
        if attribute_params.has_key?(association.name)
          value = attribute_params.delete(association.name)
          associations_params[association.name] = value
        end
      end
      return attribute_params, associations_params
    end
  end
end
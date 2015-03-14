How to override by method the form field of a :belongs\_to association column
```
In Controller:
    config.columns[:#{column_name}].ui_type = :select


In Helper:

  def options_filtered_by(value)
    Model.find(:all, 
        :conditions => [ "value >= ?", value ], :order => "last_name ASC, first_name ASC").collect { |u| [ last_name[0..20], u.id ] }
  end

  def #{column_name}_form_column(record, input_name)
    selected_id = record.#{column_name}.id unless record.#{column_name}.nil?
    select(:record, :#{column_name}, options_filtered_by(:some_value), { :selected => selected_id }, { :name => input_name + "[id]" })
  end
```
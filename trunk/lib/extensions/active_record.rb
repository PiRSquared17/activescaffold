class ActiveRecord::Base

  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to?(attribute) and send(attribute).is_a?(String)
    end
  end

  def associated_valid?
    with_instantiated_associated {|a| a.valid? and a.associated_valid?}
  end

  def instantiated_for_edit
    @instantiated_for_edit = true
  end

  def instantiated_for_edit?
    @instantiated_for_edit
  end

  def no_errors_in_associated?
    with_instantiated_associated {|a| a.errors.count == 0 and a.no_errors_in_associated?}
  end

  # To prevent the risk of a circular association we track which objects
  # have been saved already. We use a [class,id] tuple because find will
  # return different object references for the same record.
  def save_associated( save_list = [] )
    with_instantiated_associated do |a|
      if save_list.include?( [a.class,a.id] )
        true
      else
        a.save and a.save_associated( save_list << [a.class,a.id] )
      end
    end
  end

  def save_associated!
    self.save_associated || raise(ActiveRecord::RecordNotSaved)
  end

  private

  # Provide an override to allow the model to restrict which associations are considered
  # by ActiveScaffolds update mechanism. This allows the model to restrict things like
  # Acts-As-Versioned versions associations being traversed.
  #
  # By defining the method :scaffold_update_nofollow returning an array of associations
  # these associations will not be traversed.
  # By defining the method :scaffold_update_follow returning an array of associations,
  # only those associations will be traversed.
  #
  # Otherwise the default behaviour of traversing all associations will be preserved.
  def associations_for_update
    if self.respond_to?( :scaffold_update_nofollow )
      self.class.reflect_on_all_associations.reject { |association| self.scaffold_update_nofollow.include?( association.name ) }
    elsif self.respond_to?( :scaffold_update_follow )
      self.class.reflect_on_all_associations.select { |association| self.scaffold_update_follow.include?( association.name ) }
    else
      self.class.reflect_on_all_associations
    end
  end

  # yields every associated object that has been instantiated (and therefore possibly changed).
  # returns true if all yields return true. returns false otherwise.
  # returns true by default, e.g. when none of the associations have been instantiated. build accordingly.
  def with_instantiated_associated
    associations_for_update.all? do |association|
      association_proxy = instance_variable_get("@#{association.name}")
      if association_proxy && association_proxy.target && !( association_proxy.class == self.class && association_proxy.id == self.id )
        case association.macro
          when :belongs_to, :has_one
          yield association_proxy unless association_proxy.readonly?

          when :has_many, :has_and_belongs_to_many
          association_proxy.select {|r| not r.readonly?}.all? {|r| yield r}
        end
      else
        true
      end
    end
  end
end
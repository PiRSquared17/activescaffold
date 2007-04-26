require File.join(File.dirname(__FILE__), '../test_helper.rb')

# These test situations do not yet cover:
#   :through associations
#   polymorphic associations

module ModelStubs
  class Alias < ActiveRecord::Base
    def self.columns; [ActiveRecord::ConnectionAdapters::Column.new('foo', '')] end
    belongs_to :user
  end

  class User < ActiveRecord::Base
    def self.columns; [ActiveRecord::ConnectionAdapters::Column.new('foo', '')] end
    has_many :aliases
    has_and_belongs_to_many :roles
    has_one :address
  end

  class Address < ActiveRecord::Base
    def self.columns; [ActiveRecord::ConnectionAdapters::Column.new('foo', '')] end
    belongs_to :user
  end

  class Role < ActiveRecord::Base
    def self.columns; [ActiveRecord::ConnectionAdapters::Column.new('foo', '')] end
    has_and_belongs_to_many :users
  end
end

class ConstraintsTestObject
  # stub out what the mixin expects to find ...
  def self.before_filter(*args); end
  attr_accessor :active_scaffold_joins
  attr_accessor :active_scaffold_config
  def merge_conditions(old, new)
    new
  end

  # mixin the constraint code
  include ActiveScaffold::Constraints

  # make the constraints read-write, instead of coming from the session
  attr_accessor :active_scaffold_constraints

  def initialize
    @active_scaffold_joins = []
  end
end

class ConstraintsTest < Test::Unit::TestCase
  def setup
    @test_object = ConstraintsTestObject.new
  end

  def test_constraint_conditions_for_default_associations
    @test_object.active_scaffold_config = config_for('user')
    # has_one (vs belongs_to)
    assert_constraint_condition({:address => 5}, ['addresses.id = ?', 5], 'find the user with address #5')
    # has_many (vs belongs_to)
    assert_constraint_condition({:aliases => 10}, ['aliases.id = ?', 10], 'find the user with alias #10')
    # habtm (vs habtm)
    assert_constraint_condition({:roles => 4}, ['roles_users.role_id = ?', 4], 'find all users with role #4')

    @test_object.active_scaffold_config = config_for('alias')
    # belongs_to (vs has_many)
    assert_constraint_condition({:user => 1}, ['aliases.user_id = ?', 1], 'find all aliases for user #1')

    @test_object.active_scaffold_config = config_for('address')
    # belongs_to (vs has_one)
    assert_constraint_condition({:user => 2}, ['addresses.user_id = ?', 2], 'find the address for user #2')
  end

  def test_constraint_conditions_for_normal_attributes
    @test_object.active_scaffold_config = config_for('alias')
    assert_constraint_condition({'foo' => 'bar'}, ['aliases.foo = ?', 'bar'], 'normal column-based constraint')
  end

  protected

  def assert_constraint_condition(constraint, condition, message = nil)
    @test_object.active_scaffold_constraints = constraint
    assert_equal condition, @test_object.send(:conditions_from_constraints), message
  end

  def config_for(klass)
    ActiveScaffold::Config::Core.new("model_stubs/#{klass.to_s.underscore.downcase}")
  end
end
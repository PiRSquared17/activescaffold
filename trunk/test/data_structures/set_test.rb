require 'test/test_helper'
require 'test/model_stub'

class SetTest < Test::Unit::TestCase
  def setup
    @items = ActiveScaffold::DataStructures::Set.new(:a, :b)
  end

  def test_initialization
    assert @items.include?(:a)
    assert @items.include?(:b)
    assert !@items.include?(:c)
  end

  def test_exclude
    # exclude with a symbol
    assert @items.include?(:b)
    @items.exclude :b
    assert !@items.include?(:b)

    # exclude with a string
    assert @items.include?(:a)
    @items.exclude 'a'
    assert !@items.include?(:a)
  end

  def test_exclude_array
    # exclude with a symbol
    assert @items.include?(:b)
    @items.exclude [:a, :b]
    assert !@items.include?(:b)
    assert !@items.include?(:a)
  end

  def test_add
    # try adding a simple column using a string
    assert !@items.include?(:c)
    @items.add 'c'
    assert @items.include?(:c)

    # try adding a simple column using a symbol
    assert !@items.include?(:d)
    @items.add :d
    assert @items.include?(:d)

    # test that << also adds
    assert !@items.include?(:e)
    @items << :e
    assert @items.include?(:e)

    # try adding an array of columns
    assert !@items.include?(:f)
    @items.add [:f, :g]
    assert @items.include?(:f)
    assert @items.include?(:g)

  end

  def test_length
    assert_equal 2, @items.length
  end

  def test_block_config
    @items.configure do |config|
      # we may use the config argument
      config.add :c
      # or we may not
      exclude :b
      add_subgroup 'my subgroup' do
        add :e
      end
    end

    assert @items.include?(:c)
    assert !@items.include?(:b)
    @items.each { |c|
      next unless c.is_a? ActiveScaffold::DataStructures::Set
      assert c.include?(:e)
      assert_equal 'my subgroup', c.label
    }
  end

  def test_include
    @items.add_subgroup 'foo' do
      add :c
    end

    assert @items.include?(:a)
    assert @items.include?(:b)
    assert @items.include?(:c)
    assert !@items.include?(:d)
  end
end
require_relative 'list'

class Run
  def initialize
    @lists = []
  end

  def <<(list)
    lists << list
  end

  def top_level_groups
    groups.select {|group| group.superclass == RSpec::Core::ExampleGroup}
  end

  def subgroups_for(parent_group)
    groups.select {|group| group.superclass == parent_group}
  end

  def examples_for(group)
    examples.select {|example| example.example_group == group}
  end

  private

  def groups
    lists.flat_map(&:groups)
  end

  def examples
    lists.flat_map(&:examples)
  end

  attr_reader :lists
end



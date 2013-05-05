require_relative 'list'

class Run
  def initialize
    @lists = []
  end

  def <<(list)
    lists << list
  end

  def groups
    lists.flat_map(&:groups)
  end

  def examples_for(group)
    lists.flat_map(&:examples).
      select {|example| example.example_group == group}
  end

  private

  attr_reader :lists
end



require_relative '../../../lib/scrubber/run'

module Scrubber
  describe Run do
    it "can filter the top-level groups from many lists" do
      group1 = RSpec::Core::ExampleGroup.describe('foo')
      group2 = RSpec::Core::ExampleGroup.describe('bar')

      example1 = group1.example('g1 example')
      example2 = group2.example('g2 example')

      run = Run.new
      run << List.new([group1])
      run << List.new([example1, example2])
      run << List.new([group2])
      run << List.new([group1.describe("some subgroup")])
      run << List.new([group2.describe("another subgroup")])

      expect(run.groups).to eq([group1, group2])
    end

    it "can return subgroups for a group" do
      group1 = RSpec::Core::ExampleGroup.describe('group1')
      group2 = RSpec::Core::ExampleGroup.describe('group2')
      group1_subgroup1 = group1.describe('g1 sg1')
      group2_subgroup1 = group2.describe('g2 sg1')
      group1_subgroup2 = group1.describe('g1 sg2')

      run = Run.new
      run << List.new([group1])
      run << List.new([group2])
      run << List.new([group1_subgroup1, group1_subgroup2])
      run << List.new([group2_subgroup1])

      expect(run.groups(group1)).to eq([group1_subgroup1, group1_subgroup2])
    end

    it "can return examples for a group" do
      group1 = RSpec::Core::ExampleGroup.describe('foo')
      group2 = RSpec::Core::ExampleGroup.describe('bar')
      example1 = group1.example('g1 example')
      example2 = group1.example('g1 example 2')
      example3 = group2.example('g3 example')

      run = Run.new
      run << List.new([group1])
      run << List.new([example1, example3])
      run << List.new([group2])
      run << List.new([example2])

      expect(run.examples_for(group1)).to eq([example1, example2])
    end
  end
end

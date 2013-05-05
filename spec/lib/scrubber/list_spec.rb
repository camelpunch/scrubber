require_relative '../../spec_helper'
require_relative '../../../lib/scrubber/list'

module Scrubber
  describe List do
    it "is empty when instantiated without arguments" do
      expect(List.new).to be_empty
    end

    it "is equal to another list with same items" do
      group1 = RSpec::Core::ExampleGroup.describe("Group 1")
      group2 = RSpec::Core::ExampleGroup.describe("Group 2")
      example1 = group1.example('blah')
      expect(List.new([group1, group2, example1])).
        to eq(List.new([group1, group2, example1]))
    end

    it "can return a copy of itself with randomly ordered items" do
      items = [
        top_level1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        top_level2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        top_level3 = RSpec::Core::ExampleGroup.describe("Item 3"),
      ]

      list = List.new(items)
      shuffled = list.shuffle(321)

      expect(shuffled).not_to equal(list)
      expect(shuffled).to eq(
        [ top_level1, top_level3, top_level2 ]
      )
      expect(shuffled.shuffle(922)).to eq(
        [ top_level2, top_level3, top_level1 ]
      )
    end

    it "can filter the groups from its items" do
      items = [
        group1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        group1.example('blah'),
        group2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        group3 = RSpec::Core::ExampleGroup.describe("Item 3"),
        group3.example('blah'),
      ]

      list = List.new(items)

      expect(list.groups).to eq([group1, group2, group3])
    end

    it "can filter the examples from its items" do
      items = [
        group1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        example1 = group1.example('blah'),
        group2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        group3 = RSpec::Core::ExampleGroup.describe("Item 3"),
        example2 = group3.example('blah'),
      ]

      list = List.new(items)

      expect(list.examples).to eq([example1, example2])
    end

    describe "sorting by a previous run" do
      it "reproduces the same order in a new list" do
        items = [
          group1 = RSpec::Core::ExampleGroup.describe("Group 1"),
          group1_example1 = group1.example('g1 ex1'),
          group1_example2 = group1.example('g1 ex2'),
          group2 = RSpec::Core::ExampleGroup.describe("Group 2"),
          group2_subgroup1 = group2.describe("Subgroup"),
        ]

        list = List.new(items)
        shuffled = list.shuffle(567)

        shuffled_by_previous_run = list.sort_by_other(shuffled)

        expect(shuffled_by_previous_run.to_a).to eq(shuffled.to_a)
      end

      it "accepts an edited string version of a previous run and removes deleted items" do
        items = [
          item1 = RSpec::Core::ExampleGroup.describe("Item 1"),
          item2 = RSpec::Core::ExampleGroup.describe("Item 2"),
          item3 = RSpec::Core::ExampleGroup.describe("Item 3"),
          item4 = RSpec::Core::ExampleGroup.describe("Item 4"),
        ]

        list = List.new(items)

        edited = list.to_s.lines.to_a[1..2].join

        expect(list.sort_by_other(edited).to_a).to eq(
          [ item2, item3 ]
        )
      end

      it "copes with blank lines in a supplied string" do
        items = [
          item1 = RSpec::Core::ExampleGroup.describe("Item 1"),
          item2 = RSpec::Core::ExampleGroup.describe("Item 2"),
          item3 = RSpec::Core::ExampleGroup.describe("Item 3"),
          item4 = RSpec::Core::ExampleGroup.describe("Item 4"),
        ]

        list = List.new(items)

        edited = "\n\n\n"

        expect(list.sort_by_other(edited).to_a).to be_empty
      end
    end

    it "outputs to a string using generated 'unique' IDs" do
      items = [
        group1 = RSpec::Core::ExampleGroup.describe("Group 1"),
        group1_example1 = group1.example('an example'),
        group2 = RSpec::Core::ExampleGroup.describe("Group 2"),
        group2_subgroup1 = group2.describe("Subgroup"),
      ]

      list = List.new(items)

      expect(list.to_s).to present_groups_and_examples(
        group1,
        group1_example1,
        group2,
        group2_subgroup1
      )
    end
  end
end

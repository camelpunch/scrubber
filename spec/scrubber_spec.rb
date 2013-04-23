module Scrubber
  class List
    include Enumerable

    def initialize(items)
      @items = items
    end

    def shuffle(seed)
      List.new(@items.shuffle(random: Random.new(seed)))
    end

    def sort_by_previous_run(run_output)
      sorted = []
      run_output.each_line do |stored_line|
        sorted << find {|item| stored_line.strip == id_for(item)}
      end
      List.new(sorted)
    end

    def each(&block)
      @items.each(&block)
    end

    def to_s
      inject(StringIO.new) {|output, item|
        output.tap do |output|
          output.puts id_for(item)
        end
      }.string
    end

    private

    def id_for(item)
      case item
      when RSpec::Core::Example
        "#{item.class} - #{item.full_description} - #{item.location}"
      else
        "#{item} - #{item.description} - #{item.file_path}"
      end
    end
  end
end

describe Scrubber::List do
  it "can return a copy of itself with randomly ordered items" do
    items = [
      top_level1 = RSpec::Core::ExampleGroup.describe("Item 1"),
      top_level2 = RSpec::Core::ExampleGroup.describe("Item 2"),
      top_level3 = RSpec::Core::ExampleGroup.describe("Item 3"),
    ]

    list = Scrubber::List.new(items)
    shuffled = list.shuffle(321)

    expect(shuffled).not_to equal(list)
    expect(shuffled.to_a).to eq(
      [ top_level2, top_level3, top_level1 ]
    )
    expect(shuffled.shuffle(322).to_a).to eq(
      [ top_level1, top_level3, top_level2 ]
    )
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

      list = Scrubber::List.new(items)
      shuffled = list.shuffle(567)

      shuffled_by_previous_run = list.sort_by_previous_run(shuffled.to_s)

      expect(shuffled_by_previous_run.to_a).to eq(shuffled.to_a)
    end

    it "excludes lines not in the provided document" do
      items = [
        item1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        item2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        item3 = RSpec::Core::ExampleGroup.describe("Item 3"),
        item4 = RSpec::Core::ExampleGroup.describe("Item 4"),
      ]

      list = Scrubber::List.new(items)

      edited = list.to_s.lines[1..2].join

      expect(list.sort_by_previous_run(edited).to_a).to eq(
        [ item2, item3 ]
      )
    end
  end

  it "outputs to a string using generated 'unique' IDs" do
    items = [
      group1 = RSpec::Core::ExampleGroup.describe("Group 1"),
      group1_example1 = group1.example('an example'),
      group2 = RSpec::Core::ExampleGroup.describe("Group 2"),
      group2_subgroup1 = group2.describe("Subgroup"),
    ]

    list = Scrubber::List.new(items)

    lines = list.to_s.lines
    num = subclass_number(group1)

    expect(lines[0]).to eq("RSpec::Core::ExampleGroup::Nested_#{num} - Group 1 - ./spec/scrubber_spec.rb\n")
    expect(lines[1]).to match(%r{RSpec::Core::Example - Group 1 an example - ./spec/scrubber_spec.rb:\d+\n})
    expect(lines[2]).to eq("RSpec::Core::ExampleGroup::Nested_#{num+1} - Group 2 - ./spec/scrubber_spec.rb\n")
    expect(lines[3]).to eq("RSpec::Core::ExampleGroup::Nested_#{num+1}::Nested_1 - Subgroup - ./spec/scrubber_spec.rb\n")
  end

  def subclass_number(example_group)
    example_group.to_s.scan(/\d+$/).first.to_i
  end
end

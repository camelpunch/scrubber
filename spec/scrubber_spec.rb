module Scrubber
  class List
    include Enumerable

    def initialize(items)
      @items = items
    end

    def shuffle(seed)
      List.new(@items.shuffle(random: Random.new(seed)))
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
    shuffled = list.shuffle 321

    expect(shuffled).not_to equal(list)
    expect(shuffled.to_a).to eq(
      [ top_level2, top_level3, top_level1 ]
    )
    expect(shuffled.shuffle(322).to_a).to eq(
      [ top_level1, top_level3, top_level2 ]
    )
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

    expect(lines[0]).to eq("RSpec::Core::ExampleGroup::Nested_5 - Group 1 - ./spec/scrubber_spec.rb\n")
    expect(lines[1]).to match(%r{RSpec::Core::Example - Group 1 an example - ./spec/scrubber_spec.rb:\d+\n})
    expect(lines[2]).to eq("RSpec::Core::ExampleGroup::Nested_6 - Group 2 - ./spec/scrubber_spec.rb\n")
    expect(lines[3]).to eq("RSpec::Core::ExampleGroup::Nested_6::Nested_1 - Subgroup - ./spec/scrubber_spec.rb\n")
  end

  xit "can use previous output to reproduce the same order in a new list" do
  end
end

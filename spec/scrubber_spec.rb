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
          output.puts "group: #{item.description}"
        end
      }.string
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

    expect(shuffled).to be_kind_of(Scrubber::List)
    expect(shuffled).not_to equal(list)
    expect(shuffled.to_a).to eq(
      [ top_level2, top_level3, top_level1 ]
    )
  end

  it "outputs to a string using generated 'unique' IDs" do
    items = [
      top_level1 = RSpec::Core::ExampleGroup.describe("Group 1"),
      top_level2 = RSpec::Core::ExampleGroup.describe("Group 2"),
      top_level3 = RSpec::Core::ExampleGroup.describe("Group 3"),
    ]

    list = Scrubber::List.new(items)

    lines = list.to_s.lines

    expect(lines[0]).to match(/group: Group 1/)
    expect(lines[1]).to match(/group: Group 2/)
    expect(lines[2]).to match(/group: Group 3/)
  end

  xit "can use previous output to reproduce the same order in a new list" do
  end
end

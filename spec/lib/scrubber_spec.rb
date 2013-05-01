require 'tmpdir'
require 'tempfile'
require_relative '../../lib/scrubber'

describe Scrubber do
  describe "recording an RSpec run" do
    it "creates a file with the test order, seeded by RSpec config's seed" do
      config = stub('rspec config', seed: 324)
      ordering_block = nil
      config.define_singleton_method(:order_groups_and_examples) do |&block|
        ordering_block = block
      end

      items = [
        group1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        group2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        group3 = RSpec::Core::ExampleGroup.describe("Item 3"),
      ]

      Dir.mktmpdir do |dir|
        path = "#{dir}/order"
        Scrubber.record_rspec_run(config, path)

        expect(File.exists?(path)).to be_false

        ordering_block.call(items[0..1])

        expect(File.read(path)).to eq(<<-ORDER)
./spec/lib/scrubber_spec.rb - Item 2 - #{group2}
./spec/lib/scrubber_spec.rb - Item 1 - #{group1}
        ORDER

        ordering_block.call([items[2]])

        expect(File.read(path)).to eq(<<-ORDER)
./spec/lib/scrubber_spec.rb - Item 2 - #{group2}
./spec/lib/scrubber_spec.rb - Item 1 - #{group1}
./spec/lib/scrubber_spec.rb - Item 3 - #{group3}
        ORDER
      end
    end

    it "removes existing files at start of each run" do
      config = stub('rspec config', order_groups_and_examples: nil)
      Tempfile.open('record file') do |file|
        Scrubber.record_rspec_run(config, file.path)
        expect(File.exists?(file.path)).to be_false
      end
    end
  end

  describe "playing back an RSpec run" do
    it "returns items from the config block in the file's order" do
      config = stub('rspec config', seed: 123)
      ordering_block = nil
      config.define_singleton_method(:order_groups_and_examples) do |&block|
        ordering_block = block
      end

      items = [
        group1 = RSpec::Core::ExampleGroup.describe("Item 1"),
        group2 = RSpec::Core::ExampleGroup.describe("Item 2"),
        group3 = RSpec::Core::ExampleGroup.describe("Item 3"),
      ]

      Dir.mktmpdir do |dir|
        path = "#{dir}/order"
        Scrubber.record_rspec_run(config, path)
        ordering_block.call(items)

        expect(File.read(path)).to eq(<<-ORDER)
./spec/lib/scrubber_spec.rb - Item 2 - #{group2}
./spec/lib/scrubber_spec.rb - Item 1 - #{group1}
./spec/lib/scrubber_spec.rb - Item 3 - #{group3}
        ORDER

        ordering_block = nil
        Scrubber.play_rspec_run(config, path)
        expect(ordering_block.call(items)).
          to eq([ group2, group1, group3 ])
      end
    end
  end

  describe Scrubber::List do
    it "is empty when instantiated without arguments" do
      expect(Scrubber::List.new).to be_empty
    end

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
        [ top_level1, top_level3, top_level2 ]
      )
      expect(shuffled.shuffle(922).to_a).to eq(
        [ top_level2, top_level3, top_level1 ]
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

        list = Scrubber::List.new(items)

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

        list = Scrubber::List.new(items)

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

      list = Scrubber::List.new(items)

      lines = list.to_s.lines.to_a

      expect(lines[0]).to eq(
        "./spec/lib/scrubber_spec.rb - Group 1 - #{group1}\n"
      )
      expect(lines[1]).to match(%r{./spec/lib/scrubber_spec.rb:\d+ - Group 1 an example - #{group1_example1.class}\n})
      expect(lines[2]).to eq("./spec/lib/scrubber_spec.rb - Group 2 - #{group2}\n")
      expect(lines[3]).to eq("./spec/lib/scrubber_spec.rb - Subgroup - #{group2_subgroup1}\n")
    end
  end
end

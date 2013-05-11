require 'tmpdir'
require 'tempfile'
require_relative '../spec_helper'
require_relative '../../lib/scrubber'

module Scrubber
  describe Scrubber do
    def in_temp_path(&block)
      Dir.mktmpdir do |dir|
        path = "#{dir}/order"
        block.call(path)
      end
    end

    class RSpecConfigDouble
      attr_reader :seed

      def initialize(options = {})
        @seed = options[:seed]
      end

      def after(type, &block)
        @hooks ||= {}
        @hooks[type] = block
      end

      def clear_ordering_block
        @ordering_block = nil
      end

      def order_groups_and_examples(&block)
        @ordering_block = block
      end

      def run_ordering_block(*items)
        @ordering_block[items]
      end

      def run_after(type)
        @hooks[type].call
      end
    end

    describe "recording an RSpec run" do
      let(:group1) { RSpec::Core::ExampleGroup.describe("Group 1") }
      let(:group2) { RSpec::Core::ExampleGroup.describe("Group 2") }
      let(:group3) { RSpec::Core::ExampleGroup.describe("Group 3") }

      it "organises shuffled output into human- and machine-readable format" do
        config = RSpecConfigDouble.new(seed: 324)

        in_temp_path do |path|
          group1_subgroup1 = group1.describe('a subgroup')
          group1_subgroup1_example1 = group1_subgroup1.example("some subgroup example")
          example1 = group1.example('an example')
          example2 = group1.example('g1 ex2')

          Scrubber.record_rspec_run(config, path)
          config.run_ordering_block(group1)
          config.run_ordering_block(group2, group3)
          config.run_ordering_block(example2, example1)
          config.run_ordering_block(group1_subgroup1)
          config.run_ordering_block(group1_subgroup1_example1)

          config.run_after(:suite)

          expect(File.read(path)).to present_groups_and_examples(
            group1,
            example1,
            example2,
            group1_subgroup1,
            group1_subgroup1_example1,

            group3,
            group2,
          )
        end
      end

      it "returns a shuffled list from the order_groups_and_examples block" do
        config = RSpecConfigDouble.new(seed: 324)
        Scrubber.record_rspec_run(config, '/tmp/not/used')
        expect(config.run_ordering_block(group1, group2).to_a).to eq(
          [group2, group1]
        )
      end

      it "overwrites old record files" do
        config = RSpecConfigDouble.new
        file = Tempfile.open('record file') do |file|
          file << "some old record"
        end

        Scrubber.record_rspec_run(config, file.path)
        config.run_ordering_block
        config.run_after(:suite)

        expect(File.read(file.path)).not_to include("some old record")
      end
    end

    describe "playing back an RSpec run" do
      it "returns items from the config block in the file's order" do
        config = RSpecConfigDouble.new(seed: 123)

        group1 = RSpec::Core::ExampleGroup.describe("Item 1")
        group2 = RSpec::Core::ExampleGroup.describe("Item 2")
        group3 = RSpec::Core::ExampleGroup.describe("Item 3")

        example1 = group1.example "ex1"
        example2 = group2.example "ex2"
        example3 = group3.example "ex3"

        in_temp_path do |path|
          Scrubber.record_rspec_run(config, path)

          config.run_ordering_block group1, group2, group3

          config.run_ordering_block example1
          config.run_ordering_block example2
          config.run_ordering_block example3

          config.run_after(:suite)

          config.clear_ordering_block
          Scrubber.play_rspec_run(config, path)

          expect(config.run_ordering_block(group1, group2, group3)).
            to eq([ group2, group1, group3 ])
        end
      end
    end
  end
end

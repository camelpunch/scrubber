require_relative '../../spec_helper'
require_relative '../../../lib/scrubber/presenter'

module Scrubber
  describe Presenter do
    let(:path) { './spec/lib/scrubber/presenter_spec.rb' }

    describe "presenting an ExampleGroup" do
      it "includes file name, line number, description and class" do
        group = RSpec::Core::ExampleGroup.describe("foo") {}
        expect(Presenter.for(group).to_s).
          to match /^#{path}:\d+ - foo - #{group}$/
      end

      context "when the group doesn't have a block" do
        it "excludes the line number, because it's not available (?)" do
          group = RSpec::Core::ExampleGroup.describe("foo")
          expect(Presenter.for(group).to_s).
            to match /^#{path} - foo - #{group}$/
        end
      end
    end

    describe "presenting an Example" do
      it "includes file name, line number, description and class" do
        group = RSpec::Core::ExampleGroup.describe("foo")
        example = group.example("bar")
        expect(Presenter.for(example).to_s).
          to match /^#{path}:\d+ - foo bar - #{example.class}$/
      end
    end
  end
end


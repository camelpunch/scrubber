require 'tempfile'
require_relative '../../lib/scrubber'

RSpec.configure do |config|
  filename = Tempfile.new('order')
  Scrubber.record_rspec_run(config, filename)
end

describe "silly group" do
  it "runs" do
  end

  describe "subgroups" do
    it "runs" do
    end
  end
end


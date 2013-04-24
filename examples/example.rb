require 'fileutils'
require_relative '../lib/scrubber'

RSpec.configure do |config|
  record = true # change to false to start finding pollution
  filename = ENV['HOME'] + '/foo'

  FileUtils.rm_f(filename) if record

  config.order_groups_and_examples do |items|
    list = Scrubber::List.new(items)

    if record
      list.shuffle(324).tap do |list|
        File.open(filename, 'a') { |f| f.puts list }
      end
    else
      list.sort_by_other(File.read(filename))
    end
  end
end

describe "some pollution" do
  it "pollutes" do
    $pollution = true
  end

  it "gets polluted" do
    expect($pollution).to be_nil
  end

  example "1" do
  end

  describe "foo" do
    example "1a" do
    end
  end

  example "2" do
  end

  example "3" do
  end
end


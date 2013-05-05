require_relative '../lib/scrubber'

RSpec.configure do |config|
  filename = ENV['HOME'] + '/order.txt'
  Scrubber.record_rspec_run(config, filename)

  # Run this file with rspec until you get a fail.
  #
  # Once you have a failed run, comment out the record line above, and
  # uncomment the following line to play the fail back. It should always fail.
  #
  # Then, when you want to fix the pollution, edit ~/order.txt and swap the
  # order of the polluter and the polluted examples.
  #
  # Run again, and you should have a green. You've successfully 'found' the
  # test pollution culprits.
  #
  #Scrubber.play_rspec_run(config, filename)
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

describe "User" do
  it "has a name"
  it "validates presence of name"
end

describe "Order" do
  it "has many items"
  it "calculates its total from its items"
end

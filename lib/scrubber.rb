require_relative 'scrubber/run'

module Scrubber
  class << self
    def record_rspec_run(config, record_path)
      Recording.new(config, record_path).record
    end

    def play_rspec_run(config, record_path)
      order = File.read(record_path)
      config.order_groups_and_examples do |items|
        List.new(items).sort_by_other(order)
      end
    end
  end

  class Recording
    def initialize(config, record_path)
      @run = Run.new
      @config = config
      @record_path = record_path
    end

    def record
      config.order_groups_and_examples do |items|
        List.new(items).shuffle(config.seed).tap do |list|
          run << list
        end
      end

      context = {
        run: run,
        writer: method(:write_group),
        file: file,
      }
      config.after(:suite) do
        context[:run].groups.each do |group|
          context[:writer].call(group)
        end
        context[:file].close
      end
    end

    private

    def write_group(group)
      file.puts Presenter.for(group)
      run.examples_for(group).each do |example|
        file.puts Presenter.for(example)
      end
      run.groups(group).each do |group|
        write_group(group)
      end
    end

    def file
      @file ||= File.exists?(File.dirname(record_path)) &&
        File.open(record_path, 'w')
    end

    attr_reader :config, :record_path, :run
  end
end

require_relative 'scrubber/run'

module Scrubber
  class << self
    def record_rspec_run(config, record_path)
      run = Run.new
      config.order_groups_and_examples do |items|
        List.new(items).shuffle(config.seed).tap do |list|
          run << list
        end
      end

      config.after(:suite) do
        File.open(record_path, 'w') do |f|
          run.groups.each do |group|
            f.puts Presenter.for(group)
            run.examples_for(group).each do |example|
              f.puts Presenter.for(example)
            end
          end
        end
      end
    end

    def play_rspec_run(config, record_path)
      config.order_groups_and_examples do |items|
        List.new(items).sort_by_other(File.read(record_path))
      end
    end
  end
end

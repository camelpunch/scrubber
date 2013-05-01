module Scrubber
  class << self
    def record_rspec_run(config, record_path)
      FileUtils.rm_f(record_path)
      config.order_groups_and_examples do |items|
        List.new(items).shuffle(config.seed).tap do |list|
          File.open(record_path, 'a') { |f| f.puts list }
        end
      end
    end

    def play_rspec_run(config, record_path)
      config.order_groups_and_examples do |items|
        List.new(items).sort_by_other(File.read(record_path))
      end
    end
  end

  class List
    include Enumerable

    def initialize(items = [])
      @items = items
    end

    def <<(item)
      @items << item
    end

    def empty?
      @items.empty?
    end

    def shuffle(seed)
      generator = Random.new(seed)
      List.new(@items.sort_by { generator.rand(@items.size) })
    end

    def sort_by_other(run)
      run.to_s.each_line.inject(List.new) {|memo, stored_line|
        memo << find {|item| stored_line.strip == id_for(item)}
      }.compact
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
        [item.location, item.full_description, item.class].join(' - ')
      else
        [item.file_path, item.description, item].join(' - ')
      end
    end
  end
end

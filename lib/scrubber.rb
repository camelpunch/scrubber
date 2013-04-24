module Scrubber
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
      List.new(@items.shuffle(random: Random.new(seed)))
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
        "#{item.class} - #{item.full_description} - #{item.location}"
      else
        "#{item} - #{item.description} - #{item.file_path}"
      end
    end
  end
end

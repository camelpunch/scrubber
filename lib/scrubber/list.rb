require_relative 'presenter'

module Scrubber
  class List
    include Enumerable

    def initialize(items = [])
      @items = items
    end

    def <<(item)
      items << item
    end

    def ==(other)
      to_a == other.to_a
    end

    def empty?
      items.empty?
    end

    def groups
      reject {|item| item.is_a? RSpec::Core::Example}
    end

    def examples
      select {|item| item.is_a? RSpec::Core::Example}
    end

    def shuffle(seed)
      generator = Random.new(seed || 1)
      List.new(items.sort_by { generator.rand(@items.size) })
    end

    def sort_by_other(list)
      list.to_s.each_line.inject(List.new) {|memo, stored_line|
        found = find {|item| stored_line.strip == id_for(item)}
        memo << found
      }.compact
    end

    def each(&block)
      items.each(&block)
    end

    def to_s
      inject(StringIO.new) {|output, item|
        output.tap do |output|
          output.puts id_for(item)
        end
      }.string
    end

    private

    attr_reader :items

    def id_for(item)
      Presenter.for(item).to_s
    end
  end
end

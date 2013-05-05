require 'delegate'

module Scrubber
  module Presenter
    def self.for(obj)
      [Example, Group].
        detect {|presenter| presenter.applicable_to?(obj)}.
        new(obj)
    end

    class Example < SimpleDelegator
      def self.applicable_to?(obj)
        obj.respond_to?(:location)
      end

      def to_s
        [location, full_description, __getobj__.class].join(' - ')
      end
    end

    class Group < SimpleDelegator
      def self.applicable_to?(obj)
        true
      end

      def to_s
        [location, description, __getobj__].join(' - ')
      end

      class NullExampleGroupBlock
        def source_location; []; end
      end

      private

      def location
        [file_path, line_number].compact.join(':')
      end

      def line_number
        group_block.source_location[1]
      end

      def group_block
        metadata[:example_group_block] || NullExampleGroupBlock.new
      end
    end
  end
end

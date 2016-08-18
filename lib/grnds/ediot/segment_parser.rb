module Grnds
  module Ediot
    module SegmentParser
      SEGMENT_MATCHER = /\*/

      # @param raw_row [String]
      # @param size [Integer]
      # @raise Error::SegmentParsingError
      def segment_parse(raw_row:, size:)
        elements = segment_split(raw_row)
        split_size = elements.size - 1 # we don't count the row key in our size. Split size will always be bigger
        raise_segment_error(size, split_size, elements.first) if split_size > size
        (0..size).map{|x| elements[x] || ''} # Pad out the array with empty strings
      end

      # @param raw_row [String]
      def segment_peek(raw_row)
        segment_split(raw_row).first
      end

      # @param raw_row [String]
      def segment_split(raw_row)
        raw_row.split(SEGMENT_MATCHER, -1).map{|s| s.strip }
      end

      private def raise_segment_error(size, split_size, element)
        msg = "Too many elements! Expecting #{size} elements for segment #{element}. Got #{split_size}."
        raise Error::SegmentParsingError.new(msg)
      end
    end
  end
end

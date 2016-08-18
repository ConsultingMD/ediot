module Grnds
  module Ediot
    class Error < StandardError
      class SegmentParsingError < Error; end
      class RecordParsingError < Error; end
    end
  end
end

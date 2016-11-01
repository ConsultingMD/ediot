module Grnds
  module Ediot
    class Record
      include SegmentParser

      attr_reader :segments, :row_keys, :row_values

      # @param definition [Hash{Symbol => Hash{Symbol => Number}}]
      def initialize(definition)
        @row_keys = generate_keys(definition)
        @row_values = []
        @segments = definition
      end

      private def generate_keys(definition)
        definition.map { |key, options| definition_to_keys(key, options) }.flatten
      end

      private def definition_to_keys(key, options)
        row_keys = []
        size = options[:size]
        occurs = options[:occurs]
        prefix = "#{key.to_s.downcase}_"
        if occurs && occurs > 1
          occurs.times do |o|
            size.times do |s|
              row_keys << prefix + "#{o + 1}_#{s + 1}"
            end
          end
        else
          size.times do |s|
            row_keys << prefix + "#{s + 1}"
          end
        end
        row_keys
      end

      # Builds a structured record row based on the segment definition. Takes the
      # raw rows from the parsed records and for each type of segment looks into the
      # raw rows to see if the segments exist. If they do exist in the raw rows the
      # segment is created from the the row. The values in the segment are returned
      #
      # @param raw_rows [Array<String>]
      def parse(raw_rows)
        @row_values = []
        segments.each do |row_key, options|
          occurs = options[:occurs] || 1
          size = options[:size]

          matched_rows = match_and_sort(raw_rows, row_key)
          matched_rows.each do |row|
            elements = segment_parse(raw_row: row, size: size)
            # omit the first element value since that is the segment identifier
            @row_values << elements.drop(1)
          end

          rows_matched = matched_rows.size
          filler_size = occurs - rows_matched
          raise_record_error(row_key, occurs, rows_matched) if filler_size < 0 # we got more than we asked for

          filler_size.times do
            fill = (1..size).map{""}
            @row_values << fill
          end
        end
        @row_values.flatten!
      end

      private def match_and_sort(raw_rows, row_key)
        raw_rows.select {|r| row_key.to_s == segment_peek(r)}.sort
      end

      private def raise_record_error(row_key, occurs, rows_matched)
        msg = "Error parsing record! Expected #{occurs} of #{row_key} segments. Got #{rows_matched}."
        raise Error::RecordParsingError.new(msg)
      end
    end
  end
end

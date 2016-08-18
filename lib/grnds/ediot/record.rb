module Grnds
  module Ediot
    class Record

      include SegmentParser

      attr_reader :segments, :row_keys, :row_values

      def initialize(definition)
        @row_keys = generate_keys(definition)
        @row_values = []
        @segments = definition
      end

      def generate_keys(definition)
        row_keys = []
        definition.each do |key, options|
          row_keys << definition_to_keys(key, options)
        end
        row_keys.flatten
      end

      def definition_to_keys(key, options)
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

      def parse(raw_rows)
        @row_values = []
        @segments.each do |row_key, options|
          occurs = options[:occurs] || 1
          size = options[:size]

          matched_rows = match_and_sort(raw_rows, row_key)
          matched_rows.each do |row|
            elements = segment_parse(raw_row: row, size: size)
            @row_values << elements.drop(1) # omit the first element value
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

      def zip
        Hash[@row_keys.zip(row_values)]
      end

      def match_and_sort(raw_rows, row_key)
        raw_rows.select {|r| row_key.to_s == segment_peek(r)}.sort
      end

      def raise_record_error(row_key, occurs, rows_matched)
        msg = "Error parsing record! Expected #{occurs} of #{row_key} segments. Got #{rows_matched}."
        raise Error::RecordParsingError.new(msg)
      end

    end
  end
end

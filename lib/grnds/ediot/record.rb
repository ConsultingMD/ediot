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


      # Ensures consistent ordering of the elements in the record
      #
      # @param raw_rows [Array]
      # @param row_key [Symbol]
      private def match_and_sort(raw_rows, row_key)
        raw_rows.select {|r| row_key.to_s == segment_peek(r)}.sort
      end

      # A helper function to raise if the definition does not match the data.
      # E.g. If the definition says there are 3 REF segments and we process
      # a file with 5 REF segments.
      #
      # @param row_key [Symbol]
      # @param occurs [Number]
      # @param rows_matched [Number]
      # @raise [Error::RecordParsingError] if the occurrence does not match the record
      private def raise_record_error(row_key, occurs, rows_matched)
        msg = "Error parsing record! Expected #{occurs} of #{row_key} segments. Got #{rows_matched}."
        raise Error::RecordParsingError.new(msg)
      end

      # Iterates over the definition of the 834 file and generates the array of
      # column headers for each segment size and type. Expects definition is an 
      # ordered Hash.
      #
      # @param [Hash] definition
      private def generate_keys(definition)
        definition.map { |key, options| definition_to_keys(key, options) }.flatten
      end

      # Creates the header row column names that based on the 834 definition.
      # It take their segment size and occurrence count to generate the
      # columns names.
      #
      # @param key [Symbol]
      # @param options [Hash]
      # @return [Array<String>]
      private def definition_to_keys(key, options)
        row_keys = []
        size = options[:size] || 2
        occurs = options[:occurs] || 1
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
    end
  end
end

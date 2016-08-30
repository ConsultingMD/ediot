module Grnds
  module Ediot
    class Parser
      include SegmentParser

      DEFINITION = {
        INS: {size: 17},
        REF: {occurs: 5, size: 2},
        DTP: {occurs: 3, size: 3},
        NM1: {occurs: 2, size: 9},
        PER: {size: 8},
        N3: {size: 2},
        N4: {size: 3},
        DMG: {size: 3},
        HLH: {size: 3},
        HD: {size: 5},
        AMT: {size: 2},
      }

      # @param definition [Hash{Symbol => Hash{Symbol => Number}}]
      def initialize(definition=DEFINITION)
        @record = Record.new(definition)
        @segment_keys = definition.keys.map{ |k| k.to_s }
      end

      # @return [Array<String>]
      def row_keys
        @record.row_keys
      end

      # @param enum_in [Enumerator]
      # @return [Array<Array<String>>]
      def parse(enum_in, &block)
        record_lines = []
        collecting = false
        enum_in.each do |line|
          if line && known_line_type?(line)
            if record_header?(line)
              collecting = true
              process_record(record_lines, &block)
              record_lines = []
            end
            record_lines << line if collecting
          end
        end
        # catch trailing record after eof hit
        process_record(record_lines, &block)
      end

      def parse_to_csv(file_enum)
        return enum_for __method__, file_enum unless block_given?
        # write the csv header row first
        yield CSV::Row.new(row_keys, row_keys, true).to_s
        parse(file_enum) do |row|
          yield CSV::Row.new(row_keys, row).to_s
        end
      end

      # @param file_lines [String]
      # @return [Array<Array<String>>]
      def file_parse(file_lines)
        record_rows = []
        parse(StringIO.new(file_lines)) do |row|
          record_rows << row
        end
        record_rows
      end

      private def process_record(record_lines, &block)
        unless record_lines.empty?
          row = @record.parse(record_lines)
          block.call(row)
        end
      end

      # @param line [String]
      # @return [Bool]
      def known_line_type?(line)
        line_key = segment_peek(line)
        @segment_keys.include?(line_key)
      end

      # @param line [String]
      # @return [Bool]
      def record_header?(line)
        segment_peek(line) == @segment_keys.first
      end

      # @param record_file [String] really a whole file in a string? would expect something of IO
      # @return [Array<Hash{String => String}>]
      def parse_and_zip(record_file)
        record_rows = file_parse(record_file)
        record_rows.map do |row|
          Hash[row_keys.zip(row)]
        end
      end
    end
  end
end

module Grnds
  module Ediot
    class Parser
      include SegmentParser

      # Can only be one a one character segment separator
      SEGMENT_SEP = '~'

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
      }.freeze

      # Open a file using the segment separator to split file and return an enum.
      # Useful for testing or exploratory work or small files
      #
      # @param file_path [String] The file path to parse
      # @param sep [String] The file line/segment separator
      # @return [Enumerator]
      def self.lazy_file_stream(file_path)
        strings_to_lines(File.open(file_path, 'r'))
      end

      # String based stream filter to split strings into enumerated lines based
      # on the desginated segment separator
      #
      # @param enum_of_strings [Enumerator] An enum of string objects
      # @param sep [String] the line separator
      # @return [Enumerator::Lazy]
      def self.strings_to_lines(enum_of_strings, sep=SEGMENT_SEP)
        return enum_for __method__, enum_of_strings, sep unless block_given?
        line = ''
        enum_of_strings.map(&:each_char).lazy.flat_map do |o|
          puts 'Making it lazy'
          o.lazy
        end.each do |char|
          if char == sep
            yield line
            line = ''
          else
            line << char
          end
        end
      end

      # Initialize with the definition of the 384 eligibility file
      #
      # @param definition [Hash{Symbol => Hash{Symbol => Number}}]
      def initialize(definition=DEFINITION)
        @record = Record.new(definition)
        @segment_keys = definition.keys.map{ |k| k.to_s }
      end

      # Returns the names of the row keys defined in the record
      #
      # @return [Array<String>]
      def row_keys
        @record.row_keys
      end

      # Checks if the line is a segment type we can process
      #
      # @param line [String]
      # @return [Bool]
      def known_line_type?(line)
        line_key = segment_peek(line)
        @segment_keys.include?(line_key)
      end

      # Check if the line segment is the start of a new record
      #
      # @param line [String]
      # @return [Bool]
      def record_header?(line)
        segment_peek(line) == @segment_keys.first
      end

      # Takes an enum of the source stream. It expects the enum to yield a new
      # record line each time it is called. It parses record row provided and
      # collects them into groups of record rows that represent a single record
      # entry (i.e these record rows are pivoted out into one row in the final CSV document)
      #
      # @param enum_in [Enumerator]
      # @yield [Recor
      def parse(enum_in, &block)
        raise ArgumentError.new("Block required") unless block_given?
        record_lines = []
        collecting = false
        enum_in.each do |line|
          if line && known_line_type?(line)
            if record_header?(line)
              collecting = true # hit the first header line
              process_lines(record_lines, &block) # process previous collected lines (if any)
              record_lines = []
            end
            record_lines << line if collecting
          end
        end
        # catch trailing record after EOF hit
        process_lines(record_lines, &block)
      end

      # Parse file stream and yield CSV parts (header, rows) to the calling block.
      # Rows are returned as strings that can be written directly to a file or IO
      #
      # @param file_enum [Enumerator]
      # @yield [String] Yields a comma separated header string and then rows
      def parse_to_csv(file_enum)
        return enum_for __method__, file_enum unless block_given?
        # write the csv header row first
        yield CSV::Row.new(row_keys, row_keys, true).to_s
        parse(file_enum) do |row|
          yield CSV::Row.new(row_keys, row).to_s
        end
      end

      # Used for testing. Breaks streaming
      # Returns all records as an array of hashes keyed off
      # the segment row key values
      #
      # @param enum_in [Enumerator]
      # @return [Array<Hash>]
      def parse_to_hashes(enum_in)
        [].tap do |records|
          parse(enum_in) do |row|
            records << Hash[row_keys.zip(row)]
          end
        end
      end

      # Passes off the block of record lines for one record to
      # the record parser and yields the results of that call to the block.
      #
      # @param record_lines [Array]
      # @param block
      def process_lines(record_lines, &block)
        unless record_lines.empty?
          row = @record.parse(record_lines)
          block.call(row) if block_given?
        end
      end
    end
  end
end

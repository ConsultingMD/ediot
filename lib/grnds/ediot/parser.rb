module Grnds
  module Ediot
    class Parser

      include SegmentParser

      BUFFER_MAX = 500
      DEFINITION = {
        :INS => {size: 18},
        :REF => {occurs: 5, size: 3 },
        :DTP => {occurs: 3, size: 4 },
        :NM1 => {occurs: 2, size: 10 },
        :PER => {size: 9 },
        :N3 => {size: 2 },
        :N4 => {size: 4 },
        :DMG => {size: 4 },
        :HLH => {size: 4 },
        :HD => {size: 6 },
        :AMT => {size: 3 }
      }

      attr_reader :segment_header

      def initialize(definition=DEFINITION)
        @record = Record.new(definition)
        @segment_keys = definition.keys.map{|k| k.to_s }
        @segment_header = @segment_keys.first
      end

      # The column headers based on the record definition
      def rows_header
        @record.row_keys
      end

      # Parses a record file as a string
      # Splits the record on newline chars and
      # iterates through the list. The function scans
      # the rows and segments the records.
      def parse(record_file)
        record_rows = []
        record_lines = []
        record_file.split(/\n/).each do |line|
          line_key = segment_peek(line)
          if @segment_keys.include?(line_key)
            if line_key == @segment_header
              if record_lines.count > 1
                # parse the previous header rows
                record_rows << @record.parse(record_lines)
              end
              record_lines = [line]
            else
              record_lines << line
            end
          end
        end
        # catch the record_lines when we hit the end of the rows
        record_rows << @record.parse(record_lines)
      end

      # Parses a stream input. Must be an IO::Enumerable object
      def stream_parse(io_in)
        until io_in.eof do
          buffer = []
          row = io_in.readline
          while row do
            buffer << row
            row = io_in.readline
            break if (io_in.eof || buffer.size > BUFFER_MAX)
          end
          rows = parse(buffer.join())
          rows.each do |row|
            yield row
          end
        end
      end

      # Zips the headers to the values and returns each
      # row as a hash where the column name is the key and
      # the extracted row value is the value.
      def parse_and_zip(record_file)
        record_rows = parse(record_file)
        zipped = []
        record_rows.each do |row|
          zipped << Hash[rows_header.zip(row)]
        end
        zipped
      end

    end
  end
end

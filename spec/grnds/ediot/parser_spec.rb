require 'spec_helper'
require 'csv'

RSpec.describe Grnds::Ediot::Parser do

  let(:parser) { Grnds::Ediot::Parser.new }
  let(:edi_stream) { Grnds::Ediot::Parser.lazy_file_stream('spec/support/simple_tilde_sample.txt') }
  let(:out_file) { StringIO.new }

  describe "class methods" do
    let(:klass) { Grnds::Ediot::Parser }
    let(:lines) do
      ['line ', '1-line 2-','line', ' 3-'].to_enum
    end

    subject do
      klass.strings_to_lines(lines, '-')
    end

    it 'clips segment separator from the tail end of the line' do
      expect(subject.next).to eq('line 1')
      expect(subject.next).to eq('line 2')
      expect(subject.next).to eq('line 3')
    end

  end

  context 'given a simple example' do
    let(:raw_records){
      # Files use ~ instead of standard line breaks
      raw =<<~RAWREC
        ISA*00**00
        QTY*TO*3
        INS*Y*18
        REF*23*BOB SMITH
        INS*Y*19
        REF*23*SALLY SUE
      RAWREC
      raw.gsub(/\n/,'~')
      StringIO.new(raw)
    }

    let(:definition) do
      {
        INS: {size: 2},
        REF: {size: 2}
      }
    end

    let(:parser) { Grnds::Ediot::Parser.new(definition) }

    describe '#known_line_type?' do
      it 'is true when line type is defined' do
        expect(parser).to be_known_line_type('INS*0*9')
        expect(parser).to be_known_line_type('REF*1*8')
      end

      it 'is false when the line type is not defined' do
        expect(parser).not_to be_known_line_type('FOO*1*8')
      end
    end

    describe '#record_header?' do
      it 'is true when the line is a header record' do
        expect(parser).to be_record_header('INS*0*9')
      end

      it 'is false when the line is not a header record' do
        expect(parser).not_to be_record_header('REF*1*8')
      end
    end

    describe 'record parsing' do
      let(:records) do
        records = []
        parser.parse(raw_records) { |row| records << row }
        records
      end

      it 'processes two records' do
        expect(records.count).to eql(2)
      end
    end
  end

  context 'given a single record in a file' do
    let(:raw_records) { File.foreach('spec/support/simple_sample.txt') }
    let(:expected_results) { CSV.read('spec/support/processed_simple_sample.csv', headers: true) }

    it 'processes the records correctly' do
      processed_rows = parser.parse_to_hashes(raw_records)
      expected_results.each_with_index do |expected_row, idx|
        processed_rows[idx].each do |row_key, row_val|
          expect(expected_row[row_key]).to eql(row_val), "Expected parsed value '#{row_val}' to equal "\
          "'#{expected_row[row_key]}' from column '#{row_key}' and row #{idx} in the csv file"
        end
      end
    end
  end

  describe '#parse' do

    context 'when passed a block' do
      let(:processed_result) { CSV.read('spec/support/processed_simple_sample.csv', headers: true) }

      let(:streamed_csv) do
        column_headers = parser.row_keys
        out_file << CSV::Row.new(column_headers, column_headers, true).to_s
        parser.parse(edi_stream) do |row|
          out_file << CSV::Row.new(column_headers, row).to_s
        end
        CSV.parse(out_file.string, headers: true)
      end

      it 'processes the records in the file' do
        processed_result.each_with_index do |csv_row, idx|
          streamed_csv[idx].each do |row_key, row_val|
            expect(csv_row[row_key]).to eql(row_val), "Expected parsed value '#{row_val}' to equal "\
            "'#{csv_row[row_key]}' from column '#{row_key}' and row #{idx} in the csv file"
          end
        end
      end
    end

    context 'without a block' do

      it 'throws an ArgumentError' do
        expect { parser.parse(edi_stream) }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#parse_to_csv' do

    context 'an enumerator input' do
      let(:input) { edi_stream }

      it 'returns an enumerator' do
        expect(parser.parse_to_csv input).to be_an Enumerator
      end

      it 'outputs lines of a CSV when given a block' do
        correct_csv_enum = File.open('spec/support/processed_simple_sample.csv', 'r').to_enum
        parser.parse_to_csv(input) do |line|
          expect(line).to eq correct_csv_enum.next
        end
        expect{ correct_csv_enum.next }.to raise_error StopIteration
      end
    end
  end

  after(:each) do |example|
    if example.exception && out_file
      line = example.metadata[:line_number]
      file_name = File.basename(example.metadata[:file_path], ".rb")
      fail_file = "tmp/#{file_name}_failure_#{line}.txt"
      File.open(fail_file,'w') { |f| f << out_file.string }
      puts "Failure! Wrote output to file '#{fail_file}'"
    end
  end

end

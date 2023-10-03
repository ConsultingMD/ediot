require 'spec_helper'
require 'csv'

RSpec.describe Grnds::Ediot::Record do

  let(:raw_record) {
    %w[INS*Y*0 REF*0F*487261279]
  }

  let(:definition) {{
    INS: { size: 2 },
    REF: { size: 2 }
  }}

  let(:record) { Grnds::Ediot::Record.new(definition) }

  describe '#initialize' do
    it 'has segments' do
      expect(record.segments).to_not be_nil
    end

    it 'has defined row keys' do
      expect(record.row_keys).to eq %w[ins_1 ins_2 ref_1 ref_2]
    end

    it 'has no row values to start' do
      expect(record.row_values).to be_empty
    end
  end

  describe 'generating keys' do
    context 'for segments occurring once' do
      let(:definition) { {ins: {size: 2}} }

      it 'creates keys to one level deep' do
        expect(record.row_keys).to eq %w[ins_1 ins_2]
      end
    end

    context 'for segments occurring twice or more' do
      let(:definition) {{ ins: { size: 2, occurs: 2 } }}

      it 'creates nested keys' do
        expect(record.row_keys).to eq %w[ins_1_1 ins_1_2 ins_2_1 ins_2_2]
      end
    end
  end

  describe 'processing' do
    context 'a complete and well formed set of rows' do

      before do
        record.parse(raw_record)
      end

      it 'parses all rows provided' do
        expect(record.row_values.count).to eql(4)
      end

      describe 'the record array' do
        it 'is the expected length' do
          expect(record.row_keys.count).to eql(record.row_values.count)
        end

        it 'contains all the segment data' do
          vals = %w[Y 0 0F 487261279]
          record.row_values.each_with_index do |val, idx|
            expect(val).to eq(vals[idx])
          end
        end
      end
    end

    context 'a record with repeated row types' do

      let(:headers) {
        %w(ins_1 ins_2 ref_1_1 ref_1_2 ref_2_1 ref_2_2)
      }

      let(:definition) {{
        INS: { size: 2 },
        REF: { size: 2, occurs: 2 }
      }}

      context 'when the repeated elements are present' do

        let(:raw_record) {
          ['INS*Y*0',
          'REF*23*BOB SMITH',
          'REF*0F*487261279'
          ]
        }

        let(:processed) {
          [
            %w[Y 0],
            %w[0F 487261279],
            ['23','BOB SMITH'] # note the order change
          ].flatten
        }

        before do
          record.parse(raw_record)
        end

        it 'has the defined number of elements' do
          expect(record.row_values.count).to eql(6)
        end

        describe 'the row key headers' do
          it 'generates the defined keys' do
            expect(record.row_keys).to eql(headers)
          end
        end

        describe 'the row values array' do
          it 'is the same length as the row keys array' do
            expect(record.row_keys.count).to eql(record.row_values.count)
          end

          it 'contains all the segment data' do
            record.row_values.each_with_index do |val, idx|
              expect(val).to eq(processed[idx])
            end
          end
        end
      end

      context 'when a repeated element is not present' do

        let(:raw_record) {[
          'INS*Y*0',
          'REF*23*BOB SMITH'
        ]}

        let(:processed) {
          [
            %w[Y 0],
            ['23','BOB SMITH'],
            ['','']
          ].flatten
        }

        before do
          record.parse(raw_record)
        end

        it 'has the defined number of row elements' do
          expect(record.row_values.count).to eql(6)
        end

        describe 'the row key headers' do
          it 'generates the defined keys' do
            expect(record.row_keys).to eql(headers)
          end
        end

        describe 'the row values array' do
          it 'is the same length as row keys array' do
            expect(record.row_keys.count).to eql(record.row_values.count)
          end

          it 'contains all the segment data' do
            record.row_values.each_with_index do |val, idx|
              expect(val).to eq(processed[idx])
            end
          end

          it 'contains blanks for the missing segment data' do
            expect(record.row_values[4]).to be_empty
            expect(record.row_values[5]).to be_empty
          end

        end
      end
    end

    context 'when a repeated element occurs too many times' do

      let(:raw_record) {[
        'INS*Y*0',
        'REF*23*BOB SMITH',
        'REF*23*BOB SMITH'
      ]}

      it 'throws an error' do
        expect{ record.parse(raw_record)}.
          to raise_error(Grnds::Ediot::Error::RecordParsingError).with_message(/Expected 1 of REF segments\. Got 2./)
      end

    end

    context 'when two records of the same type have different sizes' do
      let(:definition) {{
        :INS => {size: 17},
        :HD => {occurs: 2, size: 5}
      }}

      let(:raw_record) {[
        'INS*Y*18*030*AB*A***FT**N*******0',
        'HD*030**HLT*        0126200300000000000000000000000000000000  ',
        'HD*030**HLT*        0126200300000000000000000000000000000000  *ESP',
      ]}

      let(:processed) {
        [
          ['Y','18','030','AB','A','','','FT','','N','','','','','','','0'],
          ['030','','HLT', '0126200300000000000000000000000000000000',''],
          ['030','','HLT', '0126200300000000000000000000000000000000','ESP'],
        ].flatten
      }

      let(:record) { Grnds::Ediot::Record.new(definition) }

      before do
        record.parse(raw_record)
      end

      it 'contains all the segment data' do
        record.row_values.each_with_index do |val, idx|
          expect(val).to eq(processed[idx]), "Expected '#{val}' to eql '#{processed[idx]}' in position #{idx} of #{processed.inspect}"
        end
      end
    end

    context 'a realistic record' do
      let(:raw_record) { File.open('spec/support/single_record.txt','r').readlines }
      let(:processed_record) { CSV.read('spec/support/processed_single_record.csv', headers: true).first }
      let(:definition) {{
        :INS => {size: 17},
        :REF => {occurs: 5, size: 2},
        :DTP => {occurs: 3, size: 3},
        :NM1 => {occurs: 2, size: 9},
        :PER => {size: 8},
        :N3 => {size: 2},
        :N4 => {size: 3},
        :DMG => {size: 3},
        :HLH => {size: 3},
        :HD => {size: 4},
        :AMT => {size: 2}
      }}

      let(:record) { Grnds::Ediot::Record.new(definition) }

      before do
        record.parse(raw_record)
      end

      it 'maps the data values correctly' do
        record.row_values.each_with_index do |val, idx|
          expect(processed_record[idx]).to eql(val)
        end
      end
    end
  end
end

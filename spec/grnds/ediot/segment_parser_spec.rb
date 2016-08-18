require 'spec_helper'

RSpec.describe Grnds::Ediot::SegmentParser do

  describe 'segment processing' do
    let(:segment) { Class.new { include Grnds::Ediot::SegmentParser }.new }

    context 'a well formed raw segment' do
      let(:raw_row) { 'NM1*IL*1*CALRISSIAN*LANDO*S***34*111223333' }
      let(:elements) { segment.segment_parse(raw_row: raw_row, size: 9) }

      it 'peeks at first element of the row' do
        key = segment.segment_peek(raw_row)
        expect(key).to eql('NM1')
      end

      it 'matches against the raw row' do
        expect(elements).to_not be_empty
      end

      it 'maps elements to array positions' do
        vals = ['NM1','IL','1','CALRISSIAN','LANDO','S','','','34','111223333']
        vals.each_with_index do |el, idx|
          expect(elements[idx]).to eq(el)
        end
      end
    end

    context 'segment that has too many elements' do
      let(:raw_row) { 'NM1*IL*1*CALRISSIAN*LANDO*VAPOR TOWERS*APT 3A*OUTPOST A*BESPIN*34*111223333' }

      it 'throws a processing error' do
        expect{ segment.segment_parse(raw_row: raw_row, size: 8) }.
          to raise_error(Grnds::Ediot::Error::SegmentParsingError).with_message(/Too many elements/)
      end
    end

    context 'segment that has too few elements' do
      let(:raw_row) { 'NM1*IL*1*CALRISSIAN*LANDO*1' }
      let(:elements) { segment.segment_parse(raw_row: raw_row, size: 7) }

      it 'pads out the missing values as empty strings on the end of the array' do
        expect(elements[6]).to be_empty
        expect(elements[7]).to be_empty
      end
    end

    context 'segment with leading/trailing whitespace' do
      let(:raw_row) { '        NM1*  IL*1*CALRI SIAN*LANDO*S***34*111223333             ' }
      let(:elements) { segment.segment_parse(raw_row: raw_row, size: 9) }

      it 'clears the whitespace when peeking at the first element' do
        key = segment.segment_peek(raw_row)
        expect(key).to eql('NM1')
      end

      it 'clears the ws on the first element' do
        expect(elements.first).to eql('NM1')
      end

      it 'clears the ws on the second element' do
        expect(elements[1]).to eq('IL')
      end

      it 'does not clear the whitespace in the fourth element' do
        expect(elements[3]).to eq('CALRI SIAN')
      end

      it 'clears the whitespace at the end of the last element' do
        expect(elements.last).to eq('111223333')
      end
    end

    context 'a segment where the trailing value is missing and the row is mostly *******' do
      let(:raw_row) { 'M1*******' }

      it 'splits and includes empty values for the ******' do
        expect(segment.segment_split(raw_row).size).to eql(8)
      end
    end
  end
end

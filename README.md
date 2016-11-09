# EDIot (Electronic Data Interchange oriented transformer)
This gem provides the ability to transform an EDI X12 ANSI 834 formated file (row based) to flattened CSV format (column based). You can find details on this format here http://www.x12.org/about/faqs.cfm#a1 and here https://getworkforce.com/ansi-834-file-layout/

## Installation

Add this line to your application's Gemfile:


    gem 'grnds-ediot', git: 'https://github.com/ConsultingMD/ediot.git', tag: '<sha-here>'


And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grnds-ediot

## Usage

### Demo
See rake tasks for examples of processing files in bulk or streaming

    $ rake -T

Rake tasks expect a tmp directory to be present in the project directory (e.g. 'tmp/'). Some sample files can be found in the spec/support directory.

    $ rake demo:with_stream
    $ rake demo:with_file

### IRL

Here's an example usage to create a CSV from an 834 file. The parser is designed for streaming data. 
Feed it an IOStream compatible object.

    require 'csv'
    require 'grnds/ediot'

    file_enum = Grnds::Ediot::Parser.lazy_file_stream('tmp/my_834_file.txt')
    File.open('tmp/my_csv_file.csv', 'w') do |out_file|

      # create a parser with the default 834 definition
      parser = Grnds::Ediot::Parser.new

      # record definition contains keys for each record row
      column_keys = parser.row_keys

      # write the csv header row first
      out_file << CSV::Row.new(column_keys, column_keys, true)

      # parser takes a fileIO object and will read the file
      # lines until EOF. As the reading cursor advances for
      # each complete record it finds it will yield an array
      # representing the row object.
      parser.parse(file_enum) do |row|
        out_file << CSV::Row.new(column_keys, row)
      end
    end

### 834 file definition

In order to properly parse an 834 file we have a simple definition object.
Abstracting the structure of the 834 file in this way makes it easy to change
it also makes the library code easy to test (see spec files for examples).

For context an example 834 record looks like this:

    INS*Y*18*030*AB*A***FT**N*******0
    REF*0F*00000000
    REF*23*800188350
    REF*ZZ*00000000W
    DTP*356*D8*20020128
    DTP*336*D8*20040126
    NM1*IL*1*SMITH*JOHN*Q***34*000000000
    PER*IP**HP*5785552630*EM*JOHNBOY@CRAZY8.NET*CP*5735552630
    N3*387 EAST WEST ROAD
    N4*LONELY CREEK*M0*68786
    DMG*D8*19500803*M
    HLH*N*0*0
    HD*030**HLT*        0920200300000000000000000000000000000000  *ESP
    DTP*348*D8*20160101
    AMT*D2*6000
    REF*1L*WY 00222D 0001419020 2100572 N65533    WMO

Note: This gem was updated to only support '~' based line separators in files (i.e no newlines in the file, only tildes). The file faker and all the specs have been updated to reflect this change. If you want to use the library for a file that does not have ~ based line endings you can pass this in to the `lazy_file_stream` class method. 

For example:

    file_enum = Grnds::Ediot::Parser.lazy_file_stream(INPUT_FILE_PATH, "\n")



The based on this example record the out-of-the-box definition is:


    DEFINITION = {
        :INS => {size: 18 },
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

The definition hash has a few key features.

1. Each entry in the definition hash reperesents a row type 
    we want to parse. If the row key is not the hash, it won't end 
    up in your output. 

2. The first entry in the definition is the header row. The parser 
    will scan the file lines until it reaches one of these. Since the
    format type of this 834 file is "unbounded" (see http://www.rawlinsecconsulting.com/x12tutorial/x12syn.html )
    we don't know the current record has ended until we see the start of
    the next record.

3. Each entry has a key (e.g. 'INS'). This corresponds to the first key in 
    the 834 "segment." The hash key must be a symbol, be in all caps, and it must have a hash as the value.
    That hash must contain the key `:size` and have an integer value that
    represents the number of "elements" in the segment row (each "element" 
    is separated by the '*' character). Optionally, you can pass in a second
    key `:occurs` this is the MAX number of times you expect to see this 
    segment type in one record. If during record parsing this number is
    exceded it will throw an error. Likewise for going over the number of
    elements designated by `:size`. LESS IS OKAY. Just not more. More elements
    than expected will throw off the pivoting from rows to columns. It would 
    be bad. Bad like mass-hysteria, dogs and cats living together, etc...


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Uses RSpec. If you find bugs or make changes write tests first. 

To run the test suite:

    $ rake spec


## License
Copyright (c) 2016 Grand Rounds Inc, all rights reserved.
[Ren Hoek](http://3b3832722e63ef13df5f-655e11a96f14b2c941c4bc34ef58f583.r35.cf2.rackcdn.com/product_images_new/Mens_Grey_Ren_And_Stimpy_Eediot_T_Shirt_from_Chunk_print_500-480-500.jpg)

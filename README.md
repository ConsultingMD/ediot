# EDIot
This gem provides the ability to transform an EDI X12 834 formated file (row based) to flattened CSV format (column based).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ediot'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ediot

## Usage

### Demo
See rake tasks for examples of processing files in bulk or streaming

    $ rake -T

Rake tasks expect a tmp directory to be present in the project directory (e.g. 'tmp/'). Some sample files can be found in the spec/support directory.

    $ rake demo:with_stream
    $ rake demo:with_file

### IRL

Here's an example usage to create a CSV from an 834 file:

    require 'csv'
    require 'grnds/ediot'

    File.open('tmp/my_834_file.txt', 'r') do |in_file|
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
        parser.parse(in_file) do |row|
          out_file << CSV::Row.new(column_keys, row)
        end
      end
    end


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Uses RSpec. To run the test suite:

    $ rake spec


## License
Copyright (c) 2016 Grand Rounds Inc, all rights reserved.

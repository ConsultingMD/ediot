require 'csv'
require 'grnds/ediot'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :demo do
  OUTPUT_FILE_PATH = 'tmp/834_demo.csv'
  INPUT_FILE_PATH = 'tmp/demomart.txt'

  desc 'Stream the demo input file'
  task :stream_it do |t|

    start_time = Time.now
    row_count = 0

    print_file_stats(INPUT_FILE_PATH)

    File.open(INPUT_FILE_PATH,'r') do |in_file|
      File.open(OUTPUT_FILE_PATH, 'w') do |out_file|

        parser = Grnds::Ediot::Parser.new
        column_headers = parser.rows_header
        out_file << CSV::Row.new(column_headers,column_headers, true).to_s

        parser.stream_parse(in_file) do |row|
          print '.' if row_count % 1000 == 0
          row_count += 1
          out_file << CSV::Row.new(column_headers, row)
        end

      end
    end
    print_run_stats(row_count, start_time)
  end

  desc 'Run the demo input file'
  task :do_it do |t|

    start_time = Time.now
    row_count = 0

    print_file_stats(INPUT_FILE_PATH)

    File.open(INPUT_FILE_PATH,'r') do |in_file|
      CSV.open(OUTPUT_FILE_PATH, 'w') do |out_file|

        parser = Grnds::Ediot::Parser.new

        # read all the lines at once
        lines = in_file.read

        out_file << parser.rows_header
        rows = parser.parse(lines)
        rows.each do |row|
          print '.' if row_count % 1000 == 0
          row_count += 1
          out_file << row
        end
        puts "Done!"
        puts "Wrote file to #{OUTPUT_FILE_PATH}"
      end
    end
    print_run_stats(row_count, start_time)
  end

  def print_file_stats(input_file_path)
    s = File.stat(input_file_path)
    file_mb = s.size/1000.0/1000.0
    puts "Input Filesize: %5.2f MB" % [file_mb]
  end

  def print_run_stats(row_count, start_time)
    puts 'Done!'
    seconds = Time.now - start_time
    puts "Processed file with %d rows in %5.2f seconds" % [row_count, seconds]
  end

end


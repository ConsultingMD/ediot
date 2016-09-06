$LOAD_PATH.push './lib'

require 'fileutils'
require 'csv'
require 'grnds/ediot'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require_relative 'file_faker/faux_834'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :sample_data do

  desc 'Makes a sample data file for 834 testing'
  task :generate do |t|
    dirname = 'tmp'
    filename = "834_fake_file_#{Time.now.to_i}.txt"
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    path = File.join(dirname, filename)
    File.open(path,'w') do |file|
      faker = FileFaker::Faux834.new(employee_count: 1000)
      faker.render(file)
      puts faker.render_meta
    end
    puts "Wrote '#{path}'"
  end
end

namespace :demo do

  INPUT_FILE_PATH = 'tmp/834_fake_file.txt'
  OUTPUT_FILE_PATH = 'tmp/834_fake_file.csv'

  desc 'Stream the demo input file (large files encouraged)'
  task :with_stream do |t|

    start_time = Time.now
    row_count = 0

    print_file_stats(INPUT_FILE_PATH)

    File.open(INPUT_FILE_PATH,'r') do |in_file|
      File.open(OUTPUT_FILE_PATH, 'w') do |out_file|

        parser = Grnds::Ediot::Parser.new
        column_headers = parser.row_keys
        out_file << CSV::Row.new(column_headers,column_headers, true).to_s

        parser.parse(in_file) do |row|
          print '.' if row_count % 1000 == 0
          row_count += 1
          out_file << CSV::Row.new(column_headers, row)
        end

      end
    end
    print_run_stats(row_count, start_time)
  end

  desc 'Run the demo using a small (< 10mb) sample file'
  task :with_file do |t|

    start_time = Time.now
    row_count = 0

    print_file_stats(INPUT_FILE_PATH)

    File.open(INPUT_FILE_PATH,'r') do |in_file|
      CSV.open(OUTPUT_FILE_PATH, 'w') do |out_file|
        parser = Grnds::Ediot::Parser.new
        # read all the lines at once
        lines = in_file.read

        out_file << parser.row_keys
        rows = parser.file_parse(lines)
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

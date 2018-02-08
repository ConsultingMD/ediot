$LOAD_PATH.push './lib'

require 'fileutils'
require 'csv'
require 'grnds/ediot'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require_relative 'file_faker/walmart_multipart_filename'
require_relative 'file_faker/faux_834'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :sample_data do

  desc 'Makes a single sample data file for 834 testing'
  task :generate do |t|
    dirname = 'tmp'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    FileFaker::Filename.new.each do |filename|
      path = File.join(dirname, filename)
      File.open(path,'w') do |file|
        faker = FileFaker::Faux834.new(employee_count: 1000)
        faker.render(file)
        puts faker.render_meta
        puts "Wrote '#{path}'"
      end
    end
  end

  desc 'Makes a sample Walmart multipart data file for 834 testing'
  task :generate_all do |t|
    dirname = 'tmp'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    FileFaker::WalmartMultipartFilename.new.each do |filename|
      path = File.join(dirname, filename)
      File.open(path,'w') do |file|
        faker = FileFaker::Faux834.new(employee_count: 1000)
        faker.render(file)
        puts faker.render_meta
        puts "Wrote '#{path}'"
      end
    end
  end
end

namespace :demo do

  INPUT_FILE_PATH = 'tmp/834_fake_file.txt'
  OUTPUT_FILE_PATH = 'tmp/834_fake_file.csv'

  DEFINITION = {
    INS: {size: 17},
    REF: {occurs: 5, size: 2},
    DTP: {occurs: 10, size: 3},
    NM1: {occurs: 2, size: 9},
    PER: {size: 8},
    N3: {size: 2},
    N4: {size: 3},
    DMG: {size: 3},
    HLH: {size: 3},
    HD: {size: 5},
    AMT: {size: 2},
  }.freeze

  desc 'Parse sample 834 file to a csv'
  task :parse_to_csv do |t|

    start_time = Time.now
    row_count = 0

    puts "Reading '#{INPUT_FILE_PATH}'"
    print_file_stats(INPUT_FILE_PATH)

    file_enum = Grnds::Ediot::Parser.lazy_file_stream(INPUT_FILE_PATH)
    File.open(OUTPUT_FILE_PATH, 'w') do |out_file|

      parser = Grnds::Ediot::Parser.new(DEFINITION)
      column_headers = parser.row_keys
      out_file << CSV::Row.new(column_headers,column_headers, true).to_s

      parser.parse(file_enum) do |row|
        print '.' if row_count % 1000 == 0
        row_count += 1
        out_file << CSV::Row.new(column_headers, row)
      end

    end
    print_run_stats(row_count, start_time)
    puts "Wrote to '#{OUTPUT_FILE_PATH}'"
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

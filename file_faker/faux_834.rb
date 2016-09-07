require 'date'
require 'faker'
require 'erb'
require 'ostruct'

module FileFaker
  class Faux834

    # POPULATION is randomly sampled to seed varables for
    # the sponsors set of dependents. Each entry in the array
    # has the format [<spouse/partner count>,<child count>].
    # E.g. array [1,2] for a sponsor will generate one spouse/partner
    # and two children.  Duplicating the one type of array object
    # increases its probability.
    POPULATION = [
      [0,0], [0,0],
      [1,0], [1,0],
      [1,1], [1,1], [1,1],
      [0,1], [0,1],
      [1,2], [1,2], [1,2],
      [0,2],
      [1,3], [1,3],
    ].freeze

    def initialize(employee_count:)
      @employee_count= employee_count
      @dependent_count = 0
      @ward_count = 0
      @minor_count = 0
      @total = 0
      @data = []
    end

    def generate_data
      @employee_count.times do
        person = make_person
        @data << person
        randomize_dependency(person)
      end
      @total = @employee_count + @dependent_count
    end

    def render(io_stream)
      generate_data
      io_stream << render_header
      @data.each do |p|
        io_stream << render_person(p)
      end
    end

    def randomize_dependency(sponsor)
      spouse, children = POPULATION.sample
      spouse.times do
        @dependent_count += 1
        @data << make_dependent(sponsor)
      end
      children.times do
        @dependent_count += 1
        @minor_count += 1
        dependent = make_dependent(sponsor)
        if @dependent_count % 240 == 0
          @ward_count += 1
          @data << as_a_ward(dependent)
        else
          @data << as_a_child(dependent)
        end
      end
    end

    def make_person
      {
        primary: 'Y',
        ft_status: 'FT',
        subscriber_number: Faker::Number.number(9),
        benefit_number: Faker::Number.number(8),
        relationship_code: '18',
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        middle_i: [*?A..?Z].sample,
        ssn: Faker::Number.number(9),
        email: Faker::Internet.email,
        home_phone: Faker::Number.number(10),
        cell_phone: Faker::Number.number(10),
        street_address: Faker::Address.street_address,
        apt_number: [Faker::Address.secondary_address, '', ''].sample,
        city: Faker::Address.city,
        state: Faker::Address.state_abbr,
        zipcode: Faker::Address.zip,
        gender: ['M','F'].sample,
        birthdate: Faker::Date.between(Date.today - 25000, Date.today - 7000).strftime('%Y%m%d'),
        plan_number: [ '00000', '02700', '03100', '02200', '04000', '04004' ].sample,
        coverage_type: ['ECH','FAM'].sample,
      }.reduce({}) { |h, (k, v)| h[k] = v.upcase; h }
    end

    def make_dependent(sponsor)
      dependent = make_person
      dependent.merge(
        primary: 'N',
        ft_status: '',
        relationship_code: ['01','53'].sample,
        subscriber_number: sponsor[:subscriber_number],
        plan_number: sponsor[:plan_number],
        street_address: sponsor[:street_address],
        apt_number: sponsor[:apt_number],
        city: sponsor[:city],
        state: sponsor[:state],
        zipcode: sponsor[:zipcode],
        coverage_type: '',
      )
    end

    def as_a_child(dependent)
      dependent.merge(
        relationship_code: '19',
        birthdate: Faker::Date.between(Date.today - 7000, Date.today - 30).strftime('%Y%m%d'),
        )
    end

    def as_a_ward(dependent)
      as_a_child(dependent).merge(relationship_code: '15')
    end

    def render_person(person)
      template = read_template('record.erb')
      ERB.new(template).result(OpenStruct.new(person).instance_eval { binding })
    end

    def render_header
      template = read_template('header.erb')
      ERB.new(template).result(binding)
    end

    def render_meta
      template = read_template('meta.erb')
      ERB.new(template).result(binding)
    end

    private def read_template(template_file)
      File.read(File.expand_path(template_file, File.dirname(__FILE__)))
    end
  end
end

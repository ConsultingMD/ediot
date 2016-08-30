require 'date'
require 'faker'
require 'erb'
require 'ostruct'

class FileFaker
  def initialize(employee_count:)
    @employee_count= employee_count
    @dependent_count = 0
    @total = 0
    @data = []
  end

  def generate_data
    @employee_count.times do
      p = person
      @data << p
      d = make_dependent(p)
      @data << d
      @dependent_count += 1
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

  def make_dependent(sponsor)
    dependent = person(true)
    dependent.merge(
      subscriber_number: sponsor[:subscriber_number],
      plan_number: sponsor[:plan_number]
    )
  end

  def person(dependent=false)
    {
      primary: (dependent ? 'N' : 'Y'),
      ft_status: (dependent ? '' : 'FT'),
      subscriber_number: Faker::Number.number(9),
      benefit_number: Faker::Number.number(8),
      relationship_code: (dependent ? ['01','15','19','53'].sample : '18'),
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      middle_i: 'Q',
      ssn: Faker::Number.number(9),
      email: Faker::Internet.email,
      home_phone: Faker::Number.number(10),
      cell_phone: Faker::Number.number(10),
      street_address: Faker::Address.street_address,
      apt_number: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zipcode: Faker::Address.zip,
      gender: ['M','F'].sample,
      birthdate: Faker::Date.between(Date.today - 25000, Date.today - 7000).strftime('%Y%m%d'),
      plan_number: [ '00000', '02700', '03100', '02200', '04000', '04004' ].sample
    }.inject({}) { |h, (k, v)| h[k] = v.upcase; h }
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

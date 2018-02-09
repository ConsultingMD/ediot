require_relative 'filename'

module FileFaker
  # Generates a filename sequence for a Walmart multipart eligibility file. The filenames are as follows:
  #
  #    X12~005010X220A1~834~OUT-C.N.N.YYYY-MM-DD_HH-MM-SS.txt
  #
  # where:
  #
  #    X12~005010X220A1~834~OUT        Identifies each part as an X12 EDI 834 (eligibility) file conforming to version 5010,
  #                                    sub-version 220A1.
  #
  #    C                               Walmart AS2 client number. Walmart currently has two active clients that communicate
  #                                    with Grand Rounds, numbered 1 and 5. All parts for a transmitted file are assumed to
  #                                    originate from the same client.
  #
  #    N.N                             Two sequence numbers of unknown use. They are set to random values between 0 and
  #                                    999_999.
  #
  #    YYYY-MM-DD                      Date stamp of file part.
  #
  #    HH-MM-SS                        Time stamp of file part.
  #
  #    .txt                            Fixed suffix, indicating a plain text file.
  #
  # Currently, the Walmart eligibility files comes in 4 parts.
  class WalmartMultipartFilename < Filename
    PREFIX = 'X12~005010X220A1~834~OUT-'.freeze

    # Creates a new Walmart multipart filename generator for the specified number of files (parts), originating from the
    # specified client. The first filename will be based on the specified time.
    def initialize(now = Time.now, nfiles = 4, client = 1)
      super(now, nfiles, PREFIX)
      @base = PREFIX +
              client.to_s + '.' +
              rand(1_000_000).to_s + '.' +
              rand(1_000_000).to_s + '.'
    end

    # Generates the current filename based on the current state.
    def current_file
      @base + @now.strftime('%F_%H-%M-%S') + SUFFIX
    end
  end
end

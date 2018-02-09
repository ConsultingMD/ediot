module FileFaker
  # Base class for generating sequences of one or more X12 EDI 834 data filenames. Some AS2 clients enforce a maximum
  # file size and thus must split files that exceed the maximum into parts. The filenames of the parts are assumed to be
  # related in some fashion. The base class provides the following state:
  #
  #    prefix        A settable file prefix. Defaults to '834_fake_file_'.
  #
  #    now           A timestamp that is set by the initializer, and updated by a random number of seconds between 1 and 10
  #                  for each subsequent file. This is meant to simulate sequences of files being transferred in time.
  #
  #    nfiles        The total number of files (parts).
  #
  #    next          The next file part.
  #
  #    SUFFIX        A fixed '.txt' suffix.
  #
  # Derived classes should add their own state variables and an override for the 'current_file' member function.
  class Filename
    include Enumerable

    DEF_PREFIX = '834_fake_file_'.freeze
    SUFFIX = '.txt'.freeze
    MAXTIMEDIFF = 10

    # Creates a new filename generator for the specified number of files (parts). Each filename will have the specified
    # prefix and the first filename will be based on the specified time.
    def initialize(now = Time.now, nfiles = 1, prefix = DEF_PREFIX)
      @now = now
      @prefix = prefix
      @nfiles = nfiles
      @next = 1
    end

    # Generates the current filename based on the current state. The default format is:
    #
    #    834_fake_file_<epoch-time>.txt
    #
    # where <epoch-time> is the current timestamp in UNIX epoch time form. Derived classes should override this method.
    def current_file
      @prefix + @now.to_i.to_s + SUFFIX
    end

    # Returns the next filename in the sequence (or nil if done) and updates the state for the next file. A random number
    # of seconds is added to the current timestamp and the file counter is incremented.
    def next_file
      name = nil
      if @next <= @nfiles
        name = current_file
        @now += (rand(MAXTIMEDIFF - 1) + 1)
        @next += 1
      end
      name
    end

    # Yields to a specified code block for each filename in the sequence.
    def each
      while (name = next_file)
        yield name
      end
    end
  end
end

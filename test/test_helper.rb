# Add the lib directory to the search path
$LOAD_PATH.unshift( "#{File.expand_path(File.dirname(__FILE__))}/../lib" )

require 'bundler/setup'

# Set-up SimpleCov (code coverage tool for Ruby 1.9)
if /^1.9/ === RUBY_VERSION
  begin
    require 'simplecov'
    require 'simplecov-rcov'

    class SimpleCov::Formatter::MergedFormatter
      def format(result)
         SimpleCov::Formatter::HTMLFormatter.new.format(result)
         SimpleCov::Formatter::RcovFormatter.new.format(result)
      end
    end

    SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
    SimpleCov.start do
      add_filter "/test/"
    end
  rescue LoadError
    puts "[ERROR] Unable to load 'simplecov' - please run 'bundle install'"
  end
end

require 'test/unit'
require 'shoulda'
require 'vcr'
require 'webmock'
require 'mocha'
require 'awesome_print'
require 'ols'

# Backport some useful assertions from minitest
unless Test::Unit::Assertions.method_defined?(:assert_output) || Test::Unit::Assertions.method_defined?(:assert_silent)
  module Test::Unit::Assertions
    def assert_output stdout = nil, stderr = nil
      out, err = capture_io do
        yield
      end

      x = assert_equal stdout, out, "In stdout" if stdout
      y = assert_equal stderr, err, "In stderr" if stderr

      (!stdout || x) && (!stderr || y)
    end

    def assert_silent
      assert_output "", "" do
        yield
      end
    end

    def capture_io
      require 'stringio'

      orig_stdout, orig_stderr         = $stdout, $stderr
      captured_stdout, captured_stderr = StringIO.new, StringIO.new
      $stdout, $stderr                 = captured_stdout, captured_stderr

      yield

      return captured_stdout.string, captured_stderr.string
    ensure
      $stdout = orig_stdout
      $stderr = orig_stderr
    end
  end
end

# Set-up VCR for mocking up web requests.
VCR.config do |c|
  if /^1\.8/ === RUBY_VERSION
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.8'
  elsif RUBY_VERSION == "1.9.1"
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.1'
  else
    c.cassette_library_dir = 'test/vcr_cassettes_ruby1.9.2+'
  end

  c.stub_with                :webmock
  c.ignore_localhost         = true
  c.default_cassette_options = {
    # :record             => :new_episodes,
    # :re_record_interval => 5184000, # 60 days in seconds
    :record             => :none,
    :match_requests_on  => [:uri, :method, :body]
  }
end


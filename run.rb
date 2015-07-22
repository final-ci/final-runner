#!/usr/bin/ruby

$: << 'lib'

require 'bundler/setup'

require 'optparse'
require 'ostruct'

require 'faraday'
require 'faraday_middleware'
require 'multi_json'
require "active_support/core_ext/numeric/time"

require 'final-api'
require 'logger'

require 'pp'


class OptParser
  def self.parse(args)
    options = OpenStruct.new

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] payload-file.json|-"
      opts.separator ""
      opts.separator "Schedule build through Final-CI API, streams logs and waits to builds finish."
      opts.separator "Returns exit code according to build result (0 = passed, 1=failed, 2= errored, 3=canceled, 4=other error)."
      opts.separator ""

      opts.on("-d", "--debug", "Run verbosely (sets log level to DEBUG)") do |d|
        puts 'jsem zde'
        options.debug = d
        options.log_level = Logger::DEBUG
      end

      opts.on("-v", "--verbose", "Run verbosely (sets log level to INFO)") do |v|
        puts 'jsem ve verbose'
        options.verbose = v
        options.log_level = Logger::INFO
      end

      opts.on("-b URL", "--base-url", "Base URL to Final-CI API") do |b|
        options.base_url = b
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)

    if ARGV.size != 1
      puts opt_parser
      exit 4
    end

    payload_file = File.read(ARGV.shift)
    payload_file = ARGF.gets(nil) if payload_file == '-'


    begin
      options.payload = MultiJson.load(payload_file)
    rescue MultiJson::ParseError => err
      STDERR.puts "Cannot parse JSON payload: #{err.to_s}"
      exit 3
    end
    options

  end
end


options = OptParser.parse(ARGV)

logger = Logger.new(STDOUT)
logger.level = options.log_level || Logger::FATAL
FinalAPI.logger = logger




FinalAPI.base_url = options.base_url 


request_payload = options.payload

request = FinalAPI::Request.create(request_payload)
logger.info "Scheduled request with jid: #{request.jid_or_id}"

begin
  last_build = request.last_build
rescue => Timeout::TimeoutError
  STDERR.puts "Timeout Error - your payload was probably wrong."
  exit 4
end
logger.info "Request id: #{request.id}, requests' last build id: #{last_build['id']}"
logger.debug "Last build: #{last_build.pretty_inspect}"

jobs = request.jobs
job_ids = jobs.map { |j| j['id'] }
job_numbers = jobs.map { |j| j['number'] }
logger.info "JOB ids: #{job_ids.join(', ')}; with numbers: #{job_numbers.join(', ')}"
logger.debug "JOB: #{jobs.pretty_inspect}"

job = FinalAPI::Job.find(request.jobs.first['id'])
logs = job.logs

while !logs.finished? do
  logs.read_logs do |stdout, number|
    puts stdout
  end
  sleep 3
end

job.reload!
logger.info "Job result: #{job.state}"

case job.state
  when 'passed' then exit 0
  when 'failed' then exit 1
  when 'errored' then exit 2
  else exit 4
end

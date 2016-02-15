#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'cyclid/hmac'
require 'net/http'
require 'uri'
require 'securerandom'
require 'optparse'
require 'logger'

options = {}
options[:scheme] = 'http'
options[:host] = 'localhost'
options[:port] = 9292
options[:log_level] = Logger::INFO

OptionParser.new do |opts|
  opts.on('-u', '--user USERNAME', 'Cyclid username') do |u|
    options[:username] = u
  end

  opts.on('-s', '--secret SECRET', 'HMAC signing secret') do |s|
    options[:secret] = s
  end

  opts.on('-H', '--host URL', "Hostname (Default: #{options[:host]}") do |h|
    options[:host] = h
  end

  opts.on('-P', '--port PORT', "Port number (Default: #{options[:port]}") do |p|
    options[:port] = p.to_i
  end

  opts.on('-d', '--debug', 'Enable verbose debug output') do |_d|
    options[:log_level] = Logger::DEBUG
  end
end.parse!

raise OptionParser::MissingArgument if options[:username].nil?
raise OptionParser::MissingArgument if options[:secret].nil?

path = ARGV[0]

# Create a logger
logger = Logger.new(STDERR)
logger.level = options[:log_level]

# Build the request & sign it
uri = URI::HTTP.build(host: options[:host],
                      port: options[:port],
                      path: path)

signer = Cyclid::HMAC::Signer.new

nonce = SecureRandom.hex
headers = signer.sign_request(uri.path,
                              options[:secret],
                              auth_header_format: '%{auth_scheme} %{username}:%{signature}',
                              username: options[:username],
                              nonce: nonce)
logger.debug headers.inspect

req = Net::HTTP::Get.new(uri)
headers[0].each do |k, v|
  logger.debug "#{k}=#{v}"
  req[k] = v
end

http = Net::HTTP.new(uri.hostname, uri.port)
http.set_debug_output(logger)
res = http.request(req)

puts res.body

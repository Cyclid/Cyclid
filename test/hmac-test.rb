#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'cyclid/hmac'
require 'net/http'
require 'uri'
require 'securerandom'

username = 'test'
secret = 'aasecret55'
uri = URI('http://localhost:9292/organizations')

nonce = SecureRandom.hex()

signer = Cyclid::HMAC::Signer.new
headers = signer.sign_request(uri.path, secret, {auth_header_format: '%{auth_scheme} %{username}:%{signature}', username: username, nonce: nonce})
puts headers.inspect

req = Net::HTTP::Get.new(uri)
headers[0].each do |k, v|
  puts "#{k}=#{v}"
  req[k] = v
end

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts res.body

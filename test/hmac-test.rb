#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'cyclid/hmac'
require 'net/http'
require 'uri'

secret = 'derp'
uri = URI('http://localhost:9292/organizations')

signer = Cyclid::HMAC::Signer.new
headers = signer.sign_request(uri.path, secret)
puts headers.inspect

req = Net::HTTP::Get.new(uri)
headers[0].each do |k, v|
  puts "#{k}=#{v}"
  req[k] = v
end
req['AUTH_USER'] = 'test'

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts res

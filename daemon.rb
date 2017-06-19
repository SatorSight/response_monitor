config_file = './local_config.rb'
require config_file if File.file? config_file
require 'net/http'
require 'mysql2'

$con = Mysql2::Client.new host:DB_HOST, username:DB_USER, password:DB_PASS, database:DB_DATABASE
uri = URI('http://ad.blinko.ru/metricaTDS1')

#the one with two redirects
uri_with_redirect = URI('http://ad.blinko.ru/zJ8Bm2')

def fetch(uri_str, limit = 10)
  raise ArgumentError, 'too many HTTP redirects' if limit == 0
  response = Net::HTTP.get_response(URI(uri_str))

  case response
  when Net::HTTPSuccess then
    response
  when Net::HTTPRedirection then
    location = response['location']
    warn "redirected to #{location}"
    fetch(location, limit - 1)
  else
    response
  end
end

def make_two_redirects(uri_str)
  timings = []

  start = Time.now
  response = Net::HTTP.get_response(URI(uri_str))
  finish = Time.now
  diff = (finish - start) * 1000.0
  diff = diff.round
  timings.push diff

  start = Time.now
  response = Net::HTTP.get_response(URI(response['location']))
  finish = Time.now
  diff = (finish - start) * 1000.0
  diff = diff.round
  timings.push diff

  #start = Time.now
  #response = Net::HTTP.get_response(URI(response['location']))
  #finish = Time.now
  #diff = (finish - start) * 1000.0
  #diff = diff.round
  #timings.push diff
  timings.push 0

  timings

end

while true

begin

	#single response timeout
	start = Time.now
	puts 'start'
	resp = fetch uri
	puts 'finish'
	finish = Time.now

	diff = (finish - start) * 1000.0
	diff = diff.round

	rs = $con.query 'insert into measure (`response`, `code`) values ('+diff.to_s+', '+resp.code+')'

	#double redirect testing
	timings = make_two_redirects uri_with_redirect
	rs = $con.query 'insert into measure_redirects (`first`, `second`, `third`) values ('+timings[0].to_s+', '+timings[1].to_s+', '+timings[2].to_s+');'
  sleep 1

rescue Exception

	sleep 10
end

end

$con.close if $con

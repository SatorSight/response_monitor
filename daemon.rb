require 'net/http'
require 'mysql'

con = Mysql.new 'localhost', 'root', '123', 'tds_measure'
uri = URI('http://ad.blinko.ru')

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
    response.value
  end
end

#10.times do
while true

	start = Time.now
	resp = fetch uri
	finish = Time.now

	diff = (finish - start) * 1000.0
	diff = diff.round

	rs = con.query 'insert into measure (`response`, `code`) values ('+diff.to_s+', '+resp.code+')'

	sleep 1

end

#puts diff


con.close if con
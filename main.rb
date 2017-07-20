config_file = './local_config.rb'
require config_file if File.file? config_file
require "sinatra"
require 'mysql2'
require 'date'

$con = Mysql2::Client.new host:DB_HOST, username:DB_USER, password:DB_PASS, database:DB_DATABASE
$running = (`ps aux | grep daemon.rb`.include? "ruby daemon.rb") ? 'Running' : 'Not running'

selectionAllHours = 	'SELECT AVG(response) as timeout, HOUR(timestamp) as hour, DATE(timestamp) as first
					 	FROM measure
					 	WHERE DATE_SUB(timestamp, INTERVAL 1 HOUR) AND code = 200 replace
					 	GROUP BY HOUR(timestamp), DATE(timestamp) ORDER BY timestamp;'

selectionAllMinutes =   'SELECT AVG(response) as timeout, MINUTE(timestamp) as second, DATE(timestamp) as first, HOUR(timestamp) as hour
						FROM measure
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) AND code = 200 replace
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp) ORDER BY timestamp;'

selectionCodes = 		'select count(code) as c, code from measure WHERE id IS NOT NULL replace GROUP BY code;'

selectionRedirects =    'SELECT AVG(first) as first, AVG(second) as second, AVG(third) as third, MINUTE(timestamp) as minute, DATE(timestamp) as date, HOUR(timestamp) as hour
						FROM measure_redirects
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) replace
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp);'

selectionRedirectsLocal =    'SELECT AVG(first) as first, AVG(second) as second, AVG(third) as third, MINUTE(timestamp) as minute, DATE(timestamp) as date, HOUR(timestamp) as hour
						FROM measure_redirects
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) AND local = 1
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp) ORDER BY timestamp;'

def getRows (query, from, to)
	rows = []
	query.sub! 'replace', 'AND timestamp BETWEEN "'+from+'" AND "'+to+'"' if query.include? 'replace'

	rs = $con.query query

	#abort rs.count.to_s
	rs.each do |h|
		rows.push h
	end
	rows
end

get "/" do
	redirect '/minutes'
end

def get_or_post(path, options = {}, &block)
	get(path, options, &block)
	post(path, options, &block)
end

get_or_post "/*" do
	route = params['splat'].pop

	from = DateTime.now - 1
	to = DateTime.now + 1

	from = from.strftime("%Y-%m-%dT%H:%M:%S")
	to = to.strftime("%Y-%m-%dT%H:%M:%S")

	from = params[:from] unless params[:from].nil? || params[:from].empty?
	to = params[:to] unless params[:to].nil? || params[:to].empty?

	if route.eql? "hours"
		rows = getRows selectionAllHours, from.to_s, to.to_s
	else
		rows = getRows selectionAllMinutes, from.to_s, to.to_s
	end
	codes = getRows selectionCodes, from.to_s, to.to_s
	redirects = getRows selectionRedirects, from.to_s, to.to_s

	redirectsLocal = getRows selectionRedirectsLocal, from.to_s, to.to_s

	#abort redirectsLocal.to_s

	erb:index, :locals => {
    	:rows => rows, 
    	:type => route, 
    	:h1 => 'Server response average by '+route, 
    	:from => from, 
    	:to => to, 
    	:codes => codes,
    	:redirectsLocal => redirectsLocal,
    	:redirects => redirects
    }
end
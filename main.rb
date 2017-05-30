config_file = './local_config.rb'
require config_file if File.file? config_file
require "sinatra"
require 'mysql2'

$con = Mysql2::Client.new host:DB_HOST, username:DB_USER, password:DB_PASS, database:DB_DATABASE
$running = `ps aux | grep daemon.rb`.empty? ? 'Not running' : 'Running'

selectionAllHours = 	'SELECT AVG(response) as timeout, HOUR(timestamp) as hour, DATE(timestamp) as first
					 	FROM measure
					 	WHERE DATE_SUB(timestamp, INTERVAL 1 HOUR) AND code = 200 replace
					 	GROUP BY HOUR(timestamp), DATE(timestamp);'

selectionAllMinutes =   'SELECT AVG(response) as timeout, MINUTE(timestamp) as second, DATE(timestamp) as first, HOUR(timestamp) as hour
						FROM measure
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) AND code = 200 replace
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp);'

selectionCodes = 		'select count(code) as c, code from measure GROUP BY code;'

selectionRedirects =    'SELECT AVG(first) as first, AVG(second) as second, AVG(third) as third, MINUTE(timestamp) as minute, DATE(timestamp) as date, HOUR(timestamp) as hour
						FROM measure_redirects
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) replace
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp);'

def getRows (query, from = Date.today.prev_day.to_s, to = Date.today.next_day.to_s)
	rows = []
	query.sub! 'replace', 'AND timestamp BETWEEN "'+from+'" AND "'+to+'"' if query.include? 'replace'
	
	rs = $con.query query
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

	from = Date.today.prev_day
	to = Date.today.next_day

	from = params[:from] unless params[:from].nil? || params[:from].empty?
	to = params[:to] unless params[:to].nil? || params[:to].empty?

	if route.eql? "hours"
		rows = getRows selectionAllHours
	else
		rows = getRows selectionAllMinutes
	end
	codes = getRows selectionCodes
	redirects = getRows selectionRedirects

	erb:index, :locals => {
    	:rows => rows, 
    	:type => route, 
    	:h1 => 'Server response average by '+route, 
    	:from => from, 
    	:to => to, 
    	:codes => codes,
    	:redirects => redirects
    }
end
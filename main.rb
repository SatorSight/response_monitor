require "sinatra"
require 'mysql'
#require 'date'

$con = Mysql.new 'localhost', 'root', '123', 'tds_measure'
$running = `ps aux | grep daemon.rb`.empty? ? 'Not running' : 'Running'


selectionAll = 'select * from measure'
selectionAllHours = 	'SELECT AVG(response) as timeout, HOUR(timestamp) as second, DATE(timestamp) as first
					 	FROM measure
					 	WHERE DATE_SUB(timestamp, INTERVAL 1 HOUR) AND code = 200 replace
					 	GROUP BY HOUR(timestamp), DATE(timestamp);'

selectionAllMinutes =   'SELECT AVG(response) as timeout, MINUTE(timestamp) as second, DATE(timestamp) as first, HOUR(timestamp) as hour
						FROM measure
						WHERE DATE_SUB(timestamp, INTERVAL 1 MINUTE) AND code = 200 replace
						GROUP BY MINUTE(timestamp), DATE(timestamp), HOUR(timestamp);'

statusCodes = 'SELECT '

def getRows (query, from = Date.today.prev_day.to_s, to = Date.today.next_day.to_s)
	rows = []
	query.sub! 'replace', 'AND timestamp BETWEEN "'+from+'" AND "'+to+'"'
	#abort query
	rs = $con.query query
	rs.each_hash do |h|
		rows.push h
	end
	rows
end

get "/" do
	redirect '/minutes'
end

get "/hours" do
	from = Date.today.prev_day
	to = Date.today.next_day

	rows = getRows selectionAllHours
    erb:index, :locals => {:rows => rows, :type => 'hour', :h1 => 'Server response average by hour', :from => from, :to => to}
end

get "/minutes" do
	from = Date.today.prev_day
	to = Date.today.next_day

	rows = getRows selectionAllMinutes
    erb:index, :locals => {:rows => rows, :type => 'min', :h1 => 'Server response average by minute', :from => from, :to => to}
end



post "/minutes" do
	from = Date.today.prev_day.to_s
	to = Date.today.next_day.to_s
	
	rows = getRows selectionAllMinutes, from, to
    erb:index, :locals => {:rows => rows, :type => 'min', :h1 => 'Server response average by minute', :from => from, :to => to}
end

post "/hours" do
	rows = getRows selectionAllHours, from, to
    erb:index, :locals => {:rows => rows, :type => 'hour', :h1 => 'Server response average by minute', :from => from, :to => to}
end
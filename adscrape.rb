#!/usr/bin/ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'dbi'
require 'mechanize'

# Set variables
host = "HOSTNAME"
db = "DATABASE"
user = "DBUSER"
pass = "DBPASS"
list_email = "EMAIL_FOR_ALERTS"
video_table = "Videos"
lookup_table = "OrgLookup"
local_video_path = "/path/to/saved/videos"
video_url_path = "http://LOCATION.COM/OF/VIDEOS"
video_url_path_index = "http://LOCATION.COM/OF/VIDEO/INDEX"
min_scrape_date = Date.strptime("2011-01-01", "%Y-%m-%d")

dbh = DBI.connect("DBI:Mysql:#{db}:#{host}","#{user}", "#{pass}")

sql = "SELECT DISTINCT youtubeid FROM #{lookup_table} WHERE active=1"
sth = dbh.execute(sql)

rows = 0
youtubeids = []
sth.fetch do |row|  
youtubeids.push(row["youtubeid"])
rows = rows + 1
end
sth.finish

youtubeids.each do |ytid|
	
	html_string = "http://gdata.youtube.com/feeds/api/users/" + ytid + "/uploads" 
	
	web_agent = Mechanize.new
	web_page = web_agent.get(html_string).body
		
	@xml_array = []	
	@xml_array = web_page.split("<entry>")
	@xml_array.shift
	
	@xml_array.each do |xml|
	
		vidid_regex = /<id>http:\/\/gdata.youtube.com\/feeds\/api\/videos\/(.*?)<\/id>/
		created_regex = /<published>(.*?)<\/published>/
		updated_regex = /<updated>(.*?)<\/updated>/
		title_regex = /<title type=\'text\'>(.*?)<\/title>/
		descr_regex = /<content type=\'text\'>(.*)<\/content>/
		url_regex = /<media\:player url=\'(http.*?)\&.*?\'/  
			
		@vidid_array = vidid_regex.match(xml)
		@created_array = created_regex.match(xml)
		@updated_array = updated_regex.match(xml)
		@title_array = title_regex.match(xml)
		@descr_array = descr_regex.match(xml)
		@url_array = url_regex.match(xml)
	
		vidid = @vidid_array[1].gsub("'", "\\\\'")
		created = @created_array[1].gsub("'", "\\\\'")
		updated = @updated_array[1].gsub("'", "\\\\'")
		title = @title_array[1].gsub("'", "\\\\'")
		
		if @descr_array.nil?
			descr = ""
		else
			descr = @descr_array[1].gsub("'", "\\\\'")
		end
			
		url = @url_array[1].gsub("'", "\\\\'")
 
		
		sql = "SELECT DISTINCT vidid FROM #{video_table} where vidid like '#{vidid}'"
		sth = dbh.execute(sql)
		vidids=[]
			sth.fetch do |row|	

			vidids.push(row["vidid"])
		end
		sth.finish
		
		created_date = created.gsub(/T.*/, "")
		created_date = Date.strptime(created_date, "%Y-%m-%d")

		if vidids[0] == vidid || created_date < min_scrape_date 
		else
		
		command = "/usr/bin/youtube-dl --max-quality=18 -q " + url + "; sleep 1; mv ./" + vidid + ".* #{local_video_path}"
		system(command)	
				
		filename = `ls #{local_video_path}/#{vidid}.* | tail -1`
		filename_short = filename.gsub("#{local_video_path}", "")	
		filename_short = filename_short.gsub(/\r/,"")
		filename_short = filename_short.gsub(/\n/,"")
		localfile = filename_short

		sql = "INSERT INTO #{video_table} (orgid,vidid,created,updated,title,url,localfile) VALUES ('#{ytid}', '#{vidid}', '#{created}', '#{updated}', '#{title}', '#{url}', '#{localfile}')"
		dbh.do(sql)

		# Send alert email
		email_alert()
		
		end	
		
	end	
end
		
dbh.disconnect

def email_alert()
	randnum = rand(1000000000000)
	temp_email_file = "/tmp/campaignads_email_notice_" + randnum.to_s + ".tmp"

	time_now = Time.now.strftime("%Y-%m-%d")

	title_clean = title.gsub("'", "\\\\'")

	orgname_sql = "SELECT DISTINCT orgname FROM #{lookup_table} where youtubeid like '#{ytid}' limit 1"
		sth_orgname = dbh.execute(orgname_sql)
		@orgnames=[]
			sth_orgname.fetch do |row|	
			@orgnames.push(row["orgname"])
		end
		sth_orgname.finish

	if @orgnames.nil?
		orgname = ""
	else
		orgname = @orgnames[0].gsub("'", "\\\\'")
	end

	proper_date_sql = "SELECT DATE_FORMAT(CONVERT_TZ(created,'GMT','US/Eastern'), '%a, %b %e, %Y at %l:%i %p') as created_proper FROM Videos where vidid like '#{vidid}' limit 1"
		sth_proper_date = dbh.execute(proper_date_sql)
		@proper_dates=[]
			sth_proper_date.fetch do |row|	
			@proper_dates.push(row["created_proper"])
		end
		sth_proper_date.finish

	if @proper_dates.nil?
		proper_date = created
	else
		proper_date = @proper_dates[0].gsub("'", "\\\\'")
	end

	updated_proper_date_sql = "SELECT DATE_FORMAT(CONVERT_TZ(updated,'GMT','US/Eastern'), '%a, %b %e, %Y at %l:%i %p') as updated_proper FROM Videos where vidid like '#{vidid}' limit 1"
		sth_updated_proper_date = dbh.execute(updated_proper_date_sql)
		@updated_proper_dates=[]
			sth_updated_proper_date.fetch do |row|	
			@updated_proper_dates.push(row["updated_proper"])
		end
		sth_updated_proper_date.finish

	if @updated_proper_dates.nil?
		updated_proper_date = updated
	else
		updated_proper_date = @updated_proper_dates[0].gsub("'", "\\\\'")
	end

	File.open(temp_email_file, 'w') { |f| 

		f.puts "To: #{list_email} \n"
		f.puts "Subject: New video by #{orgname}: #{title_clean}"  + "\n"
		f.puts "Content-Type: text/html; charset='us-ascii'\n"
		f.puts "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />"
		f.puts  "<style>body{font-family: arial, helvetica, sans-serif; font-size: 12px;} table{border: 0px; padding:3px; font-size: 12px} td{border: 0px;  padding:3px; font-size: 12px;} </style></head>"
		f.puts "<body>The following campaign video has been posted or updated:<br><table>"


		f.puts "<tr><td><img src='http://i1.ytimg.com/vi/#{vidid}/default.jpg'></td>";
				f.puts "<td><b>* Video title:</b> #{title}<br>"
		f.puts "<b>* Organization:</b> <a target='_blank' href='http://www.youtube.com/#{ytid}'>#{orgname}</a><br>"
		f.puts "<b>* Created at:</b> #{proper_date} Eastern<br>"
		f.puts "<b>* Updated at:</b> #{updated_proper_date} Eastern<br>"
		f.puts "<b>* View video:</b> <a href='#{url}'>On YouTube</a>&nbsp;|&nbsp;"
		f.puts "<a href='#{video_url_path}/#{localfile}'>On server</a>*<br>"

		f.puts "</td></tr>"
		f.puts "</table>"
		f.puts "<br>*<i>Archived videos are stored for only 30 days. To save it to your computer, open it in your web browser and select 'Save As...' from the File menu.</i><br><br>"
		f.puts "<b>You can view all saved campaign videos at <a href='#{video_url_path_index}'>#{video_url_path_index}</a></b>"
		f.puts "</body></html>"
	}

	email_subject = "New #{ytid} video: #{title_clean}"
	execstring = "/usr/sbin/sendmail " + list_email + " < " + temp_email_file
	system(execstring)	
	
	File.delete(temp_email_file)

end

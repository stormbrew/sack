# Simple web chat server

require 'sack'
require 'rack/request'
require 'sack/middleware/log_url'
server = Sack.server('simple').new(:Host=>'localhost', :Port =>1025)
chat_clients = []

Thread.new do
	while req = server.wait
		begin
			rack_req = Rack::Request.new(req.env)
			if (rack_req.post?)
				name = rack_req.params["name"]
				text = rack_req.params["text"]

				chat_clients.each do |client|
					client << "<div><em>&lt;#{name}&gt;</em> #{text}</div>\n"
				end
				req.headers(200, "Content-Type" => "text/html").done
			else
				body = req.headers(200, "Content-Type" => "text/html")
				body << '<iframe name="boom" width="0" height="0"></iframe>'
				body << '<div><form target="boom" method="post" action="/"><input type="text" name="name" value="nickname" size="15"> <input type="text" name="text" value=""> <input type="submit"></div><hr>'
				body << "        "*1024
				chat_clients.push(body)
			end
		rescue Object => e
			puts(e)
		end
	end
end

server.start
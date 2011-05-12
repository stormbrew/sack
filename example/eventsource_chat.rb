# Simple web chat server

require 'sack'
require 'rack/request'
server = Sack.server('thin').new(:Host=>'localhost', :Port =>1025)
chat_clients = []

Page = <<DOC
<html>
<head>
<script>
var stream = new EventSource("http://localhost:1025/stream");
stream.onmessage = function(event) {
	var info = event.data.split("\\n");
	var line = document.createElement('div');
	var name = document.createElement('em');
	name.appendChild(document.createTextNode("<" + info[0] + ">"));
	line.appendChild(name);
	line.appendChild(document.createTextNode(" " + info[1]));
	document.getElementById("chat").appendChild(line);
};
</script>
</head>
<body>
	<iframe name="boom" style="display:none;"></iframe>
	<div>
		<form target="boom" method="post" action="/">
			<input type="text" name="name" value="nickname" size="15"> 
			<input type="text" name="text" value=""> 
			<input type="submit">
		</form>
	</div>
	<hr>
	<div id="chat"></div>
</body>
DOC

Thread.new do
	while req = server.wait
		begin
			rack_req = Rack::Request.new(req.env)
			if (rack_req.post?)
				name = rack_req.params["name"]
				text = rack_req.params["text"]

				req.headers(200, "Content-Type" => "text/html").done
				chat_clients.each do |client|
					client << "data: #{name}\ndata: #{text}\n\n"
				end
			elsif (req.env["REQUEST_URI"] == "/stream")
				body = req.headers(200, "Content-Type" => "text/event-stream")
				body << "retry: 1\n"
				chat_clients.push(body)
			else
				body = req.headers(200, "Content-Type" => "text/html", "Content-Length" => Page.length.to_s)
				body << Page
				body.done
			end
		rescue Object => e
			puts(e)
		end
	end
end

server.start
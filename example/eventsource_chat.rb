# Simple web chat server

require 'sack'
require 'rack/request'
host = 'localhost'
server = Sack.server('simple').new(:Host=>host, :Port =>1025)
chat_clients = []

Page = <<DOC
<html>
<head>
<script src="http://www.lateststate.com/polyfills/EventSource.js"></script>
<script>
function initStream() {
	var stream = new EventSource("http://#{host}:1025/stream");
	stream.onmessage = function(event) {
		var chatArea = document.getElementById("chat");
		var info = event.data.split("\\n");
		var line = document.createElement('div');
		var name = document.createElement('em');
		name.appendChild(document.createTextNode("<" + info[0] + ">"));
		line.appendChild(name);
		line.appendChild(document.createTextNode(" " + info[1]));
		chatArea.insertBefore(line, chatArea.firstChild);
	};
	stream.onerror = function(event) {
		var timer = setTimeout(function() { clearTimeout(timer); initStream(); }, 40); // TODO: implement backoff
	};
};

function submitText(form) {
	var text = document.getElementById('text');
	if (text.value != "") {
		form.submit();
		text.value = '';
	}
	return false;
};
</script>
</head>
<body onload="initStream();">
	<iframe name="boom" style="display:none;"></iframe>
	<div>
		<form target="boom" method="post" action="/">
			<input type="text" name="name" value="nickname" size="15"> 
			<input type="text" name="text" id="text" value=""> 
			<input type="submit" onclick="return submitText(this.form);">
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
				closed = []
				chat_clients.each do |client|
					if (client.open?)
						begin
							client << "data: #{name}\ndata: #{text}\n\n"
						rescue
							closed << client
						end
					else
						closed << client
					end
				end
				closed.each {|c| chat_clients.delete(c) }
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
# System whereby requests are logged to a log url as they come in.

require 'sack'
require 'sack/middleware/log_url'
server = Sack.server('simple').new(:Host=>'localhost', :Port =>1025)
server = Sack::Middleware::LogUrl.new(server, '/log')

Thread.new do
	while req = server.wait
		begin
			body = req.headers(200, "Content-Type" => "text/html")
			body << "Oh hai thar, #{req.env["REQUEST_URI"]}"
			body.done
		rescue Object => e
			puts(e)
		end
	end
end

server.start
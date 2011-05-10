# System whereby requests are logged to a log url as they come in.

require 'sack'
server = Sack.server('thin').new(:Host=>'localhost', :Port =>1025)
log_reqs = []

Thread.new do
	while req = server.wait
		begin			
			log_reqs.each do |log_req|
				log_req << "#{req.env['HTTP_HOST']} - - #{Time.now.ctime} \"#{req.env['REQUEST_METHOD']} #{req.env['REQUEST_URI']} #{req.env['SERVER_PROTOCOL']}\" 200 -\n"
			end
			body = req.headers(200, "Content-Type" => "text/html")
			if (req.env['REQUEST_URI'] =~ %r{^/log})
				log_reqs.push(body)
			else
				body << "Oh hai thar"
				body.done
			end
		rescue Object => e
			puts(e)
		end
	end
end

server.start
require 'sack'
require 'sack/app/rack'

class SimpleHandler
	def call(env)
		[200, {"Content-Type"=>"text/html"}, ["Hello from #{Thread.current.object_id}"]]
	end
end

server = Sack.server('simple').new(:Host=>ARGV[0] || 'localhost', :Port=>1025)

app = Sack::App::Rack.new(SimpleHandler.new)

thread_count = 100
thread_count.times do
	Thread.new do
		app.run(server)
	end
end

server.start
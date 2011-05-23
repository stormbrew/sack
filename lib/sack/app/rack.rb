module Sack
	module App
		class Rack
			def initialize(rack_app)
				@rack_app = rack_app
			end

			def run(server)
				# TODO: Make this implementation less trivial. Need to do some
				# extra massaging of the functionality. In particular, make it
				# properly support async.callback and once proper non-rewindable
				# input is implemented, make it give a rewindable input to rack.
				while (req = server.wait)
					begin
						status, headers, data = @rack_app.call(req.env)
						begin
							body = req.headers(status, headers)
							data.each do |block|
								body << block
							end
						rescue Sack::ClosedError
							# Do nothing, client disconnected. Except make sure it closed.
						ensure
							body.done
						end
					rescue Exception => e
						require 'pp'; pp(:rack_error => [e, e.backtrace]) # TODO: Make this less ugly.
					end
				end
			end
		end
	end
end
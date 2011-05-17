require 'rack/utils'
require 'http/parser'

module Sack
	module Server
		# This is a simple Sack server that accepts connections on demand.
		# It is to be considered a reference/example implementation only.
		# Does not do keepalive connections or any other http/1.1 features,
		# and always returns an http/1.0 status.
		class Simple
			class Request
				attr_reader :env

				def initialize(client, rack_env)
					@client = client
					@env = rack_env
					@buffer = ""
					@parser = Http::Parser.new
					
					while ((data = @client.recv(4096)) && data != "")
						@buffer << data
						@parser.parse!(data)
						if (@parser.done?) # later make this #done_headers? and only fetch the rest when asked.
							@parser.fill_rack_env(@env)
				      @env["SERVER_PROTOCOL"] = "HTTP/" << @parser.version.join('.')
				      return
				    end
					end
					client.close
					raise "Request had no data."
				end

				def headers(status, headers)
	        match = %r{^([0-9]{3,3})( +([[:graph:] ]+))?}.match(status.to_s)
	        code = match[1].to_i
	       	@client.write("HTTP/1.0 #{match[1]} #{match[3] || Rack::Utils::HTTP_STATUS_CODES[code] || "Unknown"}\r\n")
	       	
	       	headers["Connection"] = "close"
	       	headers.delete("Transfer-Encoding")
	       	headers.each do |key, vals|
	       		vals.each_line do |val|
	       			@client.write("#{key}: #{val}\r\n")
	       		end
	       	end

	       	@client.write("\r\n")

	       	return Body.new(@client)
				end

				class Body
					def initialize(client)
						@done = false
						@client = client
					end

					def <<(data)
						begin
							raise "Write to closed connection" if @done
							@client.write(data)
						rescue
							@done = true
							raise # mark as done and let the blowup propagate.
						end
					end

					def done()
						@done = true
						@client.close_write
					end

					def open?()
						!@done
					end
				end
			end

			DefaultOptions = {
	      :Host => '0.0.0.0',
	      :Port => 8080
	    }

	    # The default values for most of the rack environment variables
	    DefaultRackEnv = {
	      "rack.version" => [1,1],
	      "sack.version" => [1,0],
	      "rack.url_scheme" => "http",
	      "rack.errors" => $stderr,
	      "rack.multithread" => true,
	      "rack.multiprocess" => false,
	      "rack.run_once" => false,
	      "SCRIPT_NAME" => "",
	      "PATH_INFO" => "",
	      "QUERY_STRING" => "",
	      "SERVER_SOFTWARE" => "Sack::Simple",
	    }

			def initialize(options = DefaultOptions)
				@options = DefaultOptions.merge(options)
				@server = TCPServer.new(@options[:Host], @options[:Port])
				@server.listen(1024)
				@stopper_mutex = Mutex.new
				@stopper_cond = ConditionVariable.new
			end

			def start()
				@stopper_mutex.synchronize do
					@stopper_cond.wait(@stopper_mutex)
				end
			end

			def wait()
				client = @server.accept()

				rack_env = DefaultRackEnv.dup
	      rack_env["SERVER_PORT"] ||= @options[:Port].to_s
	      rack_env["rack.input"] ||= StringIO.new
	      if (rack_env["rack.input"].respond_to? :set_encoding)
	        rack_env["rack.input"].set_encoding "ASCII-8BIT"
	      end
	      
	      rack_env["REMOTE_PORT"], rack_env["REMOTE_ADDR"] = Socket::unpack_sockaddr_in(client.getpeername)
	      rack_env["REMOTE_PORT"] &&= rack_env["REMOTE_PORT"].to_s
	      
	      return Request.new(client, rack_env)
			end

			def stop()
				@stopper_mutex.synchronize do
					@stopper_cond.signal
				end
			end

			def stop!()
				@stopper_mutex.synchronize do
					@stopper_cond.signal
				end
			end
		end
	end
end
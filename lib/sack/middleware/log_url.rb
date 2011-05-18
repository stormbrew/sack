require 'sack/connection_list'

module Sack
  module Middleware
    class LogUrl

      class Request
        class Body
          def initialize(real_body, status, env, log_reqs, time)
            @real_body = real_body
            @status = status
            @env = env
            @log_reqs = log_reqs
            @time = time
            @bytes = 0
          end
          def <<(str)
            @bytes += str.length
            @real_body << str
          end
          def done
            @real_body.done
            @log_reqs.each do |log_req|
              begin
                log_req << "#{@env['HTTP_HOST']} - - [#{@time}] \"#{@env['REQUEST_METHOD']} #{@env['REQUEST_URI']} #{@env['SERVER_PROTOCOL']}\" #{@status} #{@bytes}\n"
              rescue # error writing to log output, we should remove it.
              end
            end
          end
        end

        def initialize(real_req, log_reqs, time)
          @real_req = real_req
          @log_reqs = log_reqs
          @time = time
        end

        def env; @real_req.env; end

        def headers(status, headers)
          Body.new(@real_req.headers(status, headers), status, env, @log_reqs, @time)
        end
      end

      def initialize(parent, url)
        @parent = parent
        @url = url
        @log_reqs = Sack::ConnectionList.new
      end

      def wait
        req = nil
        while req.nil?
          req = @parent.wait
          if (req.env["REQUEST_URI"] == @url)
            @log_reqs.push(req.headers(200, "Content-Type"=>"text/html"))
            req = nil # don't pass out log requests.
          else
            log_req = Request.new(req, @log_reqs, Time.now)
            req = log_req
          end
        end
        return req
      end
      def start
        @parent.start
      end
      def stop
        @parent.stop
      end
      def stop!
        @parent.stop!
      end
    end
  end
end
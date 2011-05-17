require 'thin'
require 'thin/async'
require 'sack/request_queue'

module Sack
  module Server
    class Thin
      class Request
        attr :env

        def initialize(env, async_response)
          @env = env
          @async_response = async_response
        end

        def headers(code, headers)
          @async_response.status = code
          @async_response.headers.merge!(headers)
          @async_response.send_headers
          return @async_response
        end
      end

      class AdapterApp
        def initialize(queue)
          @queue = queue
        end

        def call(env)
          resp = ::Thin::AsyncResponse.new(env)
          @queue.push(Request.new(env, resp))
          resp.finish
        end
      end

      def initialize(options)
        @queue = RequestQueue.new
        @server = ::Thin::Server.new(options[:Host], options[:Port], AdapterApp.new(@queue))
      end

      def start
        @server.start
      end

      def self.start(options)
        new(options).start
      end

      def stop
        @server.stop
      end
      def stop!
        @server.stop!
      end

      def wait
        @queue.wait
      end
    end
  end
end
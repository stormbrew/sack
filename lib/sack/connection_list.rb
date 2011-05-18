require 'set'

module Sack
  # Maintains a list of open client connections. If a connection dies during
  # processing and correctly raises a Sack::ClosedError, it will remove the
  # connection from the list. The container is thread safe such that one thread
  # finding a connection to remove will not cause another thread to be working
  # on a modified underlying array.
  class ConnectionList
    include Enumerable

    def initialize
      @connections = Set.new
      @mutex = Mutex.new
    end

    # removes dead connections from the list
    def clean
      each {}
    end
    def each
      closed = Set.new
      # so we're not iterating over a potentially mutating array
      connections = @connections # Note: Assumes refcopy of attrib is threadsafe.
      res = connections.each do |c|
        if (c.open?)
          begin
            yield c
          rescue Sack::ClosedError => e
            if (e.con == c)
              closed << c
            else
              raise
            end
          end
        else
          closed << c
        end
      end
      if (closed.length > 0)
        @mutex.synchronize do
          @connections = @connections - closed
        end
      end
      res
    end
    def add(c)
      @mutex.synchronize do
        @connections.add(c)
      end
    end
    alias_method :<<, :add
    alias_method :push, :add

    def delete(c)
      @mutex.synchronize do
        @connections.delete(c)
      end
    end
  end
end
require 'thread'

module Sack
	class RequestQueue
		def initialize()
			@queue = []
			@mutex = Mutex.new
			@condition = ConditionVariable.new
		end

		def push(req)
			@mutex.synchronize do
				@queue.push(req)
				@condition.signal
			end
		end
		def get
			@mutex.synchronize do
				@queue.pop
			end
		end
		def wait
			ret = nil
			while (ret.nil?) # in case of spurious wakes
				@mutex.synchronize do
					@condition.wait(@mutex)
					ret = @queue.pop
				end
			end
			return ret
		end
	end
end
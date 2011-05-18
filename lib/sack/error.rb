module Sack
	class Error < ::RuntimeError; end
	class ClosedError < Error
		attr :con, :orig_err
		def initialize(con, orig_err)
			@con = con
			@orig_error = orig_err
			super("Connection Closed")
		end
	end
end
module Sack
	module Server; end

	def self.server(name)
		require "sack/server/#{name}"
		return Server.const_get(name.gsub(/(^|_)([a-z])/) { $2.upcase })
	end

	require 'sack/version'
	require 'sack/request_queue'
end
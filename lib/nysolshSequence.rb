#!/usr/bin/env ruby
# encoding: utf-8
require 'nysolmod'
class NysolShellSequence

	def initialize()
		@cmdlist=nil
		@msgFlg=false

 	end


	def msgOn()
		@msgFlg=true
		return self
	end 
	
	def msgOff()
		@msgFlg=false
		return self
	end

	def add(obj)
		if @cmdlist == nil then
			@cmdlist = obj
		else
			obj.inp = @cmdlist
			@cmdlist = obj
		end
	end

	def show()
		@cmdlist.show()
	end	

	def run()
		@cmdlist.msgOn if @msgFlg
		return @cmdlist.run()
	end
		
end
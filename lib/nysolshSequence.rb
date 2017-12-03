#!/usr/bin/env ruby
# encoding: utf-8
require 'nysolmod'
class NysolShellSequence

	def initialize()
		@cmdlist=[]
		@msgFlg=false
 	end

	def add(obj,iokwd={})
		@cmdlist.push([obj,iokwd])
	end

	def msgOn()
		@msgFlg=true
		return self
	end 
	
	def msgOff()
		@msgFlg=false
		return self
	end

	def show()
		p @cmdlist
	end	

	def makeNetwork(cmdlists)

		conectLIST={}
		#f.w.コマンド毎にする
		ioParams = {"i"=>0,"m"=>0,"o"=>1,"u"=>1}

		# IO list check
		# f.w.
		# コマンド毎にチェックし方を変えれるようにする 
		# io以外にも拡張 
		cmdlists.each_with_index{|cmd,linno|
			cmdptn = cmd[0]
			cmdio = cmd[1]
			cmdio.each{|k,v|
				next unless v.is_a?(String)
				ioTP = ioParams[k]
				if ioTP == 0 then
					unless conectLIST.has_key?(v) then
						print( k + " model err before output") 
					end
					conectLIST[v][1].push([k,linno])
				elsif ioTP == 1 then
					conectLIST[v] =[[],[]] unless conectLIST.has_key?(v)
					conectLIST[v][0].push([k,linno])
				end

			}
		}
		conectLIST.each{|key,val|
			if val[0].size != 1 or val[1].empty? then
				print( key + " model err")
			end
		}

		#cmd作成 
		# f.w. できるならcheckのときに同時に作成する
		newcmdlist = []
		interobj = {}
		newruncmd = nil

		cmdlists.each_with_index{|cmd,linno|
			cmdptn = cmd[0]
			cmdio = cmd[1]

			if newruncmd != nil and ( !cmdio.has_key?("i") or cmdio["i"].empty? ) then
					tmpptn  = cmdptn
					tmpptn.inplist["i"].push(newruncmd)
					newruncmd.outlist[newruncmd.nowdir].push(cmdptn)
					newruncmd = tmpptn
			else
				newruncmd = cmdptn
			end

			cmdio.each{|k,v|
				if v.is_a?(String) then
					ioTP = ioParams[k]
					if ioTP == 0 then
						newruncmd.paraUpdate({k=>interobj[v][0]})
						interobj[v][0].outlist[interobj[v][1]].push(newruncmd)
					elsif ioTP == 1 then
						interobj[v] = [newruncmd,k]
					end
				else
					newruncmd.paraUpdate({k=>v})
				end
			}

			#writescv ,writelistで終了
			if cmdptn.name == "writecsv" or cmdptn.name=="writelist"  then
				newcmdlist.push(newruncmd)
				newruncmd = nil
			end
		}

		return newcmdlist
	end


	def run(kwd={}) 

		runlist_org = Marshal.load(Marshal.dump(@cmdlist))

		runcmds = makeNetwork(@cmdlist)

		nowMsgFlg = @msgFlg
		nowMsgFlg=true if kwd.has_key?("msg") and  kwd["msg"] == "on"

		if nowMsgFlg then
			NysolMOD.runs(runcmds,{"msg"=>"on"})
		else
			NysolMOD.runs(runcmds)
		end
		@cmdlist = runlist_org

	end

	def drawModel(fname=nil)

		runlist = Marshal.load(Marshal.dump(@cmdlist))

		runcmds = makeNetwork(runlist)

		NysolMOD.drawModels(runcmds,fname)
	end

	def drawModelD3(fname=nil)

		runlist = Marshal.load(Marshal.dump(@cmdlist))

		runcmds = makeNetwork(runlist)

		NysolMOD.drawModelsD3(runcmds,fname)
	end


	def modelInfo()

		runlist = Marshal.load(Marshal.dump(@cmdlist))
		runcmds = makeNetwork(runlist)

		return NysolMOD.modelInfos(runcmds)

	end
		
end
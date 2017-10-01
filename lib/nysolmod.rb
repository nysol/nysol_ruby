#!/usr/bin/env ruby
# encoding: utf-8
require 'mparallelEXT'
require 'nysolshell_core'

# arg :hash or string
def args2dict(arg,klist,uk=nil)
	kwargs ={}
	if arg.instance_of?(String) then
		args = arg.split(' ')
		args.each{|val|
			vals = val.split("=")
			if vals.size()==1 then
				if vals[0] =~ /^-/ then
					kwargs[vals[0].sub(/^-/,"")] = true  
				elsif uk!=nil then
					kwargs[uk] = vals[0]
				else
					p "unknown parameter"
				end
			elsif vals.size()==2 then
				kwargs[vals[0]] = vals[1]
			else 
				p "unknown parameter"
			end
		}
	elsif arg.instance_of?(Hash) then
		kwargs = arg		
	else
		p "args type str or hash"
		return None
	end
	
	exval = []
	kwargs.each{|k,v|
		next if klist[0].include?(k) and v.instance_of?(String)
		next if klist[0].include?(k)
		next if klist[1].include?(k) and v == true
		exval.push(k)
		p k + " is not keyword"
	}
	exval.each{|k|
		kwargs.delete(k)
	}
	return kwargs
end

class NysolMOD

	attr_accessor :name, :kwd,:inp,:outp,:refp,:unp,:msg

	def initialize(name=nil,kwd=nil)
		@name = name
		@kwd   = kwd
		@inp  = kwd["i"]
		@kwd.delete("i") if kwd.has_key?("i") 
		@outp = kwd["o"]
		@kwd.delete("o") if kwd.has_key?("o") 
		@refp = kwd["m"]
		@kwd.delete("m") if kwd.has_key?("m") 
		#@unp  = kwd["u"]
		#@kwd.delete("u") if kwd.has_key?("u") 
		@msg=false

	end

	def msgOn()
		@msg=true
		return self
	end 
	
	def msgOff()
		@msg=true
		return self
	end
	
	def addPre(pre)
		@inp = pre
		return self
	end

	def para2str()
		rtnStr = ""
		@kwd.each{|k,v|
			if v.instance_of?(String) then
				rtnStr += k + "=" + v + " "
			elsif v.instance_of?(TrueClass) then
				rtnStr += "-" + k + " "
			end	
		}
		return rtnStr
	end

	def make_modlist()
		i0 = nil
		i1 = nil
		if @inp.is_a?(NysolMOD) then
			i0 = @inp.make_modlist()
		elsif @inp.is_a?(Array) then
			i0 = @inp
		elsif @inp.is_a?(String) then
			i0 = @inp
		end
			 
		if @refp.is_a?(NysolMOD) then
			i1 = @refp.make_modlist() 
		elsif @refp.is_a?(Array) then
			i1 = @refp
		elsif @refp.is_a?(String) then
			i1 = @refp
		end
		return [@name,para2str(),i0,i1]
	end

	def run()

		runA = false
		outf = @outp
		if not outf.instance_of?(String)then
			outf = nil
			runA = true 
		end

		list = make_modlist()
		shobj = NYSOLRUBY::MshCore.new(@msg)
		if runA then
			return shobj.run(list,runA)
		else
			list[1] += " o=" + outf 
			shobj.run(list,runA)
			return outf
		end
	end

	def show()
		list = []
		runA = false
		outf = @outp
		if not outf.instance_of?(String)then
			outf = nil
			runA = true 
		end
		list = make_modlist()
		p list
	end

  def each()
		list = []
		runA = false
		outf = @outp
		if not outf.instance_of?(String)then
			outf = nil
			runA = true 
		end
		list = make_modlist()

		shobj = NYSOLRUBY::MshCore.new(@msg)

		vvv = shobj.runiter(list,runA)
		
		while (line = shobj.readline(vvv)) != nil do
			yield line
		end
		
  end


	def parallelrun(ilist,olist=nil,num=2)

		list = make_modlist()

		runlist = []
		alist = list
		while alist[2] != nil do
			alist = alist[2] 
		end

		chagVALi = alist[1].dup
		chagVALo = list[1].dup

		rtnA = true if olist==nil ? true : false
		
		ilist.each_with_index{|v,i|
			if alist == list then
				if olist == nil then
					alist[1] = chagVALi + " i=" + v
				else
					alist[1] = chagVALi + " i=" + v + " o=" + olist[i]
				end
			else		
				if olist == nil then
					alist[1] = chagVALi + " i=" + v
				else
					alist[1] = chagVALi + " i=" + v 
					list[1] = chagVALo + " o=" + olist[i]
				end
			end
			runlist.push([Marshal.load(Marshal.dump(list)),rtnA,@msg])	

		}
		#結果の反映方法考える
		runlist.meachEXT(num){|val|
			runA = val[1]
			list = val[0]
			shobj = NYSOLRUBY::MshCore.new(val[2])
			if runA then
				#return shobj.run(list,runA)
				shobj.run(list,runA)
			else
				shobj.run(list,runA)
				#return outf
			end
		}
		#return output
	end


	def self.mload(args)
		return Nysol_Mload.new(args)
  end
	def self.msave(args)
		return Nysol_Msave.new(args)
  end

	def msave(args)
		return Nysol_Msave.new(args).addPre(self)
	end


	def self.m2cross(args)
		return Nysol_M2cross.new(args)
  end

	def m2cross(args)
		return Nysol_M2cross.new(args).addPre(self)
	end

	def self.maccum(args)
		return Nysol_Maccum.new(args)
  end

	def maccum(args)
		return Nysol_Maccum.new(args).addPre(self)
	end

	def self.marff2csv(args)
		return Nysol_Marff2csv.new(args)
  end

	def marff2csv(args)
		return Nysol_Marff2csv.new(args).addPre(self)
	end

	def self.mavg(args)
		return Nysol_Mavg.new(args)
  end

	def mavg(args)
		return Nysol_Mavg.new(args).addPre(self)
	end

	def self.mbest(args)
		return Nysol_Mbest.new(args)
  end

	def mbest(args)
		return Nysol_Mbest.new(args).addPre(self)
	end

	def self.mbucket(args)
		return Nysol_Mbucket.new(args)
  end

	def mbucket(args)
		return Nysol_Mbucket.new(args).addPre(self)
	end

	def self.mcal(args)
		return Nysol_Mcal.new(args)
  end

	def mcal(args)
		return Nysol_Mcal.new(args).addPre(self)
	end

	def self.mchgnum(args)
		return Nysol_Mchgnum.new(args)
  end

	def mchgnum(args)
		return Nysol_Mchgnum.new(args).addPre(self)
	end

	def self.mchgstr(args)
		return Nysol_Mchgstr.new(args)
  end

	def mchgstr(args)
		return Nysol_Mchgstr.new(args).addPre(self)
	end

	def self.mcombi(args)
		return Nysol_Mcombi.new(args)
  end

	def mcombi(args)
		return Nysol_Mcombi.new(args).addPre(self)
	end

	def self.mcommon(args)
		return Nysol_Mcommon.new(args)
  end

	def mcommon(args)
		return Nysol_Mcommon.new(args).addPre(self)
	end

	def self.mcount(args)
		return Nysol_Mcount.new(args)
  end

	def mcount(args)
		return Nysol_Mcount.new(args).addPre(self)
	end

	def self.mcross(args)
		return Nysol_Mcross.new(args)
  end

	def mcross(args)
		return Nysol_Mcross.new(args).addPre(self)
	end

	def self.mcut(args)
		return Nysol_Mcut.new(args)
  end

	def mcut(args)
		return Nysol_Mcut.new(args).addPre(self)
	end

	def self.mcat(args)
		return Nysol_Mcat.new(args)
  end

	def mcat(args)
		return Nysol_Mcat.new(args).addPre(self)
	end



	def self.mdelnull(args)
		return Nysol_Mdelnull.new(args)
  end

	def mdelnull(args)
		return Nysol_Mdelnull.new(args).addPre(self)
	end

	def self.mdformat(args)
		return Nysol_Mdformat.new(args)
  end

	def mdformat(args)
		return Nysol_Mdformat.new(args).addPre(self)
	end

	def self.mduprec(args)
		return Nysol_Mduprec.new(args)
  end

	def mduprec(args)
		return Nysol_Mduprec.new(args).addPre(self)
	end

	def self.mfldname(args)
		return Nysol_Mfldname.new(args)
  end

	def mfldname(args)
		return Nysol_Mfldname.new(args).addPre(self)
	end

	def self.mfsort(args)
		return Nysol_Mfsort.new(args)
  end

	def mfsort(args)
		return Nysol_Mfsort.new(args).addPre(self)
	end

	def self.mhashavg(args)
		return Nysol_Mhashavg.new(args)
  end

	def mhashavg(args)
		return Nysol_Mhashavg.new(args).addPre(self)
	end

	def self.mhashsum(args)
		return Nysol_Mhashsum.new(args)
  end

	def mhashsum(args)
		return Nysol_Mhashsum.new(args).addPre(self)
	end

	def self.mjoin(args)
		return Nysol_Mjoin.new(args)
  end

	def mjoin(args)
		return Nysol_Mjoin.new(args).addPre(self)
	end

	def self.mkeybreak(args)
		return Nysol_Mkeybreak.new(args)
  end

	def mkeybreak(args)
		return Nysol_Mkeybreak.new(args).addPre(self)
	end

	def self.mmbucket(args)
		return Nysol_Mmbucket.new(args)
  end

	def mmbucket(args)
		return Nysol_Mmbucket.new(args).addPre(self)
	end

	def self.mmvavg(args)
		return Nysol_Mmvavg.new(args)
  end

	def mmvavg(args)
		return Nysol_Mmvavg.new(args).addPre(self)
	end

	def self.mmvsim(args)
		return Nysol_Mmvsim.new(args)
  end

	def mmvsim(args)
		return Nysol_Mmvsim.new(args).addPre(self)
	end

	def self.mmvstats(args)
		return Nysol_Mmvstats.new(args)
  end

	def mmvstats(args)
		return Nysol_Mmvstats.new(args).addPre(self)
	end

	def self.mnewnumber(args)
		return Nysol_Mnewnumber.new(args)
  end

	def mnewnumber(args)
		return Nysol_Mnewnumber.new(args).addPre(self)
	end

	def self.mnewrand(args)
		return Nysol_Mnewrand.new(args)
  end

	def mnewrand(args)
		return Nysol_Mnewrand.new(args).addPre(self)
	end

	def self.mnewstr(args)
		return Nysol_Mnewstr.new(args)
  end

	def mnewstr(args)
		return Nysol_Mnewstr.new(args).addPre(self)
	end

	def self.mnjoin(args)
		return Nysol_Mnjoin.new(args)
  end

	def mnjoin(args)
		return Nysol_Mnjoin.new(args).addPre(self)
	end

	def self.mnormalize(args)
		return Nysol_Mnormalize.new(args)
  end

	def mnormalize(args)
		return Nysol_Mnormalize.new(args).addPre(self)
	end

	def self.mnrcommon(args)
		return Nysol_Mnrcommon.new(args)
  end

	def mnrcommon(args)
		return Nysol_Mnrcommon.new(args).addPre(self)
	end

	def self.mnrjoin(args)
		return Nysol_Mnrjoin.new(args)
  end

	def mnrjoin(args)
		return Nysol_Mnrjoin.new(args).addPre(self)
	end

	def self.mnullto(args)
		return Nysol_Mnullto.new(args)
  end

	def mnullto(args)
		return Nysol_Mnullto.new(args).addPre(self)
	end

	def self.mnumber(args)
		return Nysol_Mnumber.new(args)
  end

	def mnumber(args)
		return Nysol_Mnumber.new(args).addPre(self)
	end

	def self.mpadding(args)
		return Nysol_Mpadding.new(args)
  end

	def mpadding(args)
		return Nysol_Mpadding.new(args).addPre(self)
	end

	def self.mpaste(args)
		return Nysol_Mpaste.new(args)
  end

	def mpaste(args)
		return Nysol_Mpaste.new(args).addPre(self)
	end

	def self.mproduct(args)
		return Nysol_Mproduct.new(args)
  end

	def mproduct(args)
		return Nysol_Mproduct.new(args).addPre(self)
	end

	def self.mrand(args)
		return Nysol_Mrand.new(args)
  end

	def mrand(args)
		return Nysol_Mrand.new(args).addPre(self)
	end

	def self.mrjoin(args)
		return Nysol_Mrjoin.new(args)
  end

	def mrjoin(args)
		return Nysol_Mrjoin.new(args).addPre(self)
	end

	def self.msed(args)
		return Nysol_Msed.new(args)
  end

	def msed(args)
		return Nysol_Msed.new(args).addPre(self)
	end

	def self.msel(args)
		return Nysol_Msel.new(args)
  end

	def msel(args)
		return Nysol_Msel.new(args).addPre(self)
	end

	def self.mselnum(args)
		return Nysol_Mselnum.new(args)
  end

	def mselnum(args)
		return Nysol_Mselnum.new(args).addPre(self)
	end

	def self.mselrand(args)
		return Nysol_Mselrand.new(args)
  end

	def mselrand(args)
		return Nysol_Mselrand.new(args).addPre(self)
	end

	def self.mselstr(args)
		return Nysol_Mselstr.new(args)
  end

	def mselstr(args)
		return Nysol_Mselstr.new(args).addPre(self)
	end

	def self.msetstr(args)
		return Nysol_Msetstr.new(args)
  end

	def msetstr(args)
		return Nysol_Msetstr.new(args).addPre(self)
	end

	def self.mshare(args)
		return Nysol_Mshare.new(args)
  end

	def mshare(args)
		return Nysol_Mshare.new(args).addPre(self)
	end

	def self.msim(args)
		return Nysol_Msim.new(args)
  end

	def msim(args)
		return Nysol_Msim.new(args).addPre(self)
	end

	def self.mslide(args)
		return Nysol_Mslide.new(args)
  end

	def mslide(args)
		return Nysol_Mslide.new(args).addPre(self)
	end

	def self.msortf(args)
		return Nysol_Msortf.new(args)
  end

	def msortf(args)
		return Nysol_Msortf.new(args).addPre(self)
	end

	def self.msplit(args)
		return Nysol_Msplit.new(args)
  end

	def msplit(args)
		return Nysol_Msplit.new(args).addPre(self)
	end

	def self.mstats(args)
		return Nysol_Mstats.new(args)
  end

	def mstats(args)
		return Nysol_Mstats.new(args).addPre(self)
	end

	def self.msum(args)
		return Nysol_Msum.new(args)
  end

	def msum(args)
		return Nysol_Msum.new(args).addPre(self)
	end

	def self.msummary(args)
		return Nysol_Msummary.new(args)
  end

	def msummary(args)
		return Nysol_Msummary.new(args).addPre(self)
	end

	def self.mtab2csv(args)
		return Nysol_Mtab2csv.new(args)
  end

	def mtab2csv(args)
		return Nysol_Mtab2csv.new(args).addPre(self)
	end

	def self.mtonull(args)
		return Nysol_Mtonull.new(args)
  end

	def mtonull(args)
		return Nysol_Mtonull.new(args).addPre(self)
	end

	def self.mtra(args)
		return Nysol_Mtra.new(args)
  end

	def mtra(args)
		return Nysol_Mtra.new(args).addPre(self)
	end

	def self.mtraflg(args)
		return Nysol_Mtraflg.new(args)
  end

	def mtraflg(args)
		return Nysol_Mtraflg.new(args).addPre(self)
	end

	def self.muniq(args)
		return Nysol_Muniq.new(args)
  end

	def muniq(args)
		return Nysol_Muniq.new(args).addPre(self)
	end

	def self.mvcat(args)
		return Nysol_Mvcat.new(args)
  end

	def mvcat(args)
		return Nysol_Mvcat.new(args).addPre(self)
	end

	def self.mvcommon(args)
		return Nysol_Mvcommon.new(args)
  end

	def mvcommon(args)
		return Nysol_Mvcommon.new(args).addPre(self)
	end

	def self.mvcount(args)
		return Nysol_Mvcount.new(args)
  end

	def mvcount(args)
		return Nysol_Mvcount.new(args).addPre(self)
	end

	def self.mvdelim(args)
		return Nysol_Mvdelim.new(args)
  end

	def mvdelim(args)
		return Nysol_Mvdelim.new(args).addPre(self)
	end

	def self.mvdelnull(args)
		return Nysol_Mvdelnull.new(args)
  end

	def mvdelnull(args)
		return Nysol_Mvdelnull.new(args).addPre(self)
	end

	def self.mvjoin(args)
		return Nysol_Mvjoin.new(args)
  end

	def mvjoin(args)
		return Nysol_Mvjoin.new(args).addPre(self)
	end

	def self.mvnullto(args)
		return Nysol_Mvnullto.new(args)
  end

	def mvnullto(args)
		return Nysol_Mvnullto.new(args).addPre(self)
	end

	def self.mvreplace(args)
		return Nysol_Mvreplace.new(args)
  end

	def mvreplace(args)
		return Nysol_Mvreplace.new(args).addPre(self)
	end

	def self.mvsort(args)
		return Nysol_Mvsort.new(args)
  end

	def mvsort(args)
		return Nysol_Mvsort.new(args).addPre(self)
	end

	def self.mvuniq(args)
		return Nysol_Mvuniq.new(args)
  end

	def mvuniq(args)
		return Nysol_Mvuniq.new(args).addPre(self)
	end

	def self.mwindow(args)
		return Nysol_Mwindow.new(args)
  end

	def mwindow(args)
		return Nysol_Mwindow.new(args).addPre(self)
	end

	def self.mxml2csv(args)
		return Nysol_Mxml2csv.new(args)
  end

	def mxml2csv(args)
		return Nysol_Mxml2csv.new(args).addPre(self)
	end


end


class  Nysol_Mload < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mload")
	def initialize(args)
		super("mload",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msave < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mload")
	def initialize(args)
		super("msave",args2dict(args,@@kwdList))
	end
end

class  Nysol_M2cross < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("m2cross")
	def initialize(args)
		super("m2cross",args2dict(args,@@kwdList))
	end
end

class  Nysol_Maccum < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("maccum")
	def initialize(args)
		super("maccum",args2dict(args,@@kwdList))
	end
end

class  Nysol_Marff2csv < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("marff2csv")
	def initialize(args)
		super("marff2csv",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mavg < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mavg")
	def initialize(args)
		super("mavg",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mbest < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mbest")
	def initialize(args)
		super("mbest",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mbucket < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mbucket")
	def initialize(args)
		super("mbucket",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcal < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcal")
	def initialize(args)
		super("mcal",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mchgnum < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mchgnum")
	def initialize(args)
		super("mchgnum",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mchgstr < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mchgstr")
	def initialize(args)
		super("mchgstr",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcombi < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcombi")
	def initialize(args)
		super("mcombi",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcommon < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcommon")
	def initialize(args)
		super("mcommon",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcount < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcount")
	def initialize(args)
		super("mcount",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcross < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcross")
	def initialize(args)
		super("mcross",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mcut < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcut")
	def initialize(args)
		super("mcut",args2dict(args,@@kwdList))
	end
end


class Nysol_Mcat < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mcat")
	def initialize(args)
		super("mcat",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mdelnull < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mdelnull")
	def initialize(args)
		super("mdelnull",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mdformat < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mdformat")
	def initialize(args)
		super("mdformat",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mduprec < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mduprec")
	def initialize(args)
		super("mduprec",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mfldname < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mfldname")
	def initialize(args)
		super("mfldname",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mfsort < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mfsort")
	def initialize(args)
		super("mfsort",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mhashavg < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mhashavg")
	def initialize(args)
		super("mhashavg",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mhashsum < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mhashsum")
	def initialize(args)
		super("mhashsum",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mjoin < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mjoin")
	def initialize(args)
		super("mjoin",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mkeybreak < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mkeybreak")
	def initialize(args)
		super("mkeybreak",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mmbucket < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mmbucket")
	def initialize(args)
		super("mmbucket",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mmvavg < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mmvavg")
	def initialize(args)
		super("mmvavg",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mmvsim < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mmvsim")
	def initialize(args)
		super("mmvsim",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mmvstats < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mmvstats")
	def initialize(args)
		super("mmvstats",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnewnumber < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnewnumber")
	def initialize(args)
		super("mnewnumber",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnewrand < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnewrand")
	def initialize(args)
		super("mnewrand",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnewstr < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnewstr")
	def initialize(args)
		super("mnewstr",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnjoin < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnjoin")
	def initialize(args)
		super("mnjoin",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnormalize < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnormalize")
	def initialize(args)
		super("mnormalize",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnrcommon < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnrcommon")
	def initialize(args)
		super("mnrcommon",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnrjoin < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnrjoin")
	def initialize(args)
		super("mnrjoin",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnullto < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnullto")
	def initialize(args)
		super("mnullto",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mnumber < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mnumber")
	def initialize(args)
		super("mnumber",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mpadding < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mpadding")
	def initialize(args)
		super("mpadding",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mpaste < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mpaste")
	def initialize(args)
		super("mpaste",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mproduct < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mproduct")
	def initialize(args)
		super("mproduct",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mrand < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mrand")
	def initialize(args)
		super("mrand",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mrjoin < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mrjoin")
	def initialize(args)
		super("mrjoin",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msed < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msed")
	def initialize(args)
		super("msed",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msel < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msel")
	def initialize(args)
		super("msel",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mselnum < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mselnum")
	def initialize(args)
		super("mselnum",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mselrand < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mselrand")
	def initialize(args)
		super("mselrand",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mselstr < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mselstr")
	def initialize(args)
		super("mselstr",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msetstr < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msetstr")
	def initialize(args)
		super("msetstr",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mshare < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mshare")
	def initialize(args)
		super("mshare",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msim < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msim")
	def initialize(args)
		super("msim",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mslide < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mslide")
	def initialize(args)
		super("mslide",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msortf < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msortf")
	def initialize(args)
		super("msortf",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msplit < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msplit")
	def initialize(args)
		super("msplit",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mstats < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mstats")
	def initialize(args)
		super("mstats",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msum < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msum")
	def initialize(args)
		super("msum",args2dict(args,@@kwdList))
	end
end

class  Nysol_Msummary < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("msummary")
	def initialize(args)
		super("msummary",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mtab2csv < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mtab2csv")
	def initialize(args)
		super("mtab2csv",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mtonull < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mtonull")
	def initialize(args)
		super("mtonull",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mtra < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mtra")
	def initialize(args)
		super("mtra",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mtraflg < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mtraflg")
	def initialize(args)
		super("mtraflg",args2dict(args,@@kwdList))
	end
end

class  Nysol_Muniq < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("muniq")
	def initialize(args)
		super("muniq",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvcat < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvcat")
	def initialize(args)
		super("mvcat",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvcommon < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvcommon")
	def initialize(args)
		super("mvcommon",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvcount < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvcount")
	def initialize(args)
		super("mvcount",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvdelim < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvdelim")
	def initialize(args)
		super("mvdelim",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvdelnull < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvdelnull")
	def initialize(args)
		super("mvdelnull",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvjoin < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvjoin")
	def initialize(args)
		super("mvjoin",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvnullto < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvnullto")
	def initialize(args)
		super("mvnullto",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvreplace < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvreplace")
	def initialize(args)
		super("mvreplace",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvsort < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvsort")
	def initialize(args)
		super("mvsort",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mvuniq < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mvuniq")
	def initialize(args)
		super("mvuniq",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mwindow < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mwindow")
	def initialize(args)
		super("mwindow",args2dict(args,@@kwdList))
	end
end

class  Nysol_Mxml2csv < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mxml2csv")
	def initialize(args)
		super("mxml2csv",args2dict(args,@@kwdList))
	end
end



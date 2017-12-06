#!/usr/bin/env ruby
#/* ////////// LICENSE INFO ////////////////////
#
# * Copyright (C) 2013 by NYSOL CORPORATION
# *
# * Unless you have received this program directly from NYSOL pursuant
# * to the terms of a commercial license agreement with NYSOL, then
# * this program is licensed to you under the terms of the GNU Affero General
# * Public License (AGPL) as published by the Free Software Foundation,
# * either version 3 of the License, or (at your option) any later version.
# * 
# * This program is distributed in the hope that it will be useful, but
# * WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF 
# * NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
# *
# * Please refer to the AGPL (http://www.gnu.org/licenses/agpl-3.0.txt)
# * for more details.
#
# ////////// LICENSE INFO ////////////////////*/
require 'mparallelEXT'
require 'nysolshell_core'


def dicisionPosSub(mlist,iolist,baselist,dsppos,y,counter)

	baselist.each{|i|
		next if dsppos[i] != nil
		dsppos[i] = [counter[y],y]
		counter[y]+=1
		newlist = iolist[i][2] + iolist[i][3] 
		counter.push(0) if counter.size==y+1
		dicisionPosSub(mlist,iolist,newlist,dsppos,y+1,counter)
	}
end

	
def dicisionPos(mlist,iolist)

	startpos = []
	mlist.each_with_index{|mm,i|
		unless mm[2].empty? then
			startpos.push(i) if mm[2].has_key?("i")
			startpos.push(i) if mm[2].has_key?("m")
		end
	}

	dsppos   = Array.new(mlist.size)
	y=0
	counter =[0]
	dicisionPosSub(mlist,iolist,startpos,dsppos,y,counter)
	
	return dsppos , counter.size ,counter.max

end

def changeSVG(mlist,iolist,linklist,fname=nil)

	dsppos,ymax,xmax = dicisionPos(mlist,iolist)

	begin
		if fname == nil then
			f=STDOUT
		else
			f=open(fname, 'w')
		end
	
		f.write("<svg height='#{ymax*60}' width='#{xmax*60}'>\n")
		f.write("<defs>\n")
		f.write("<marker id='endmrk' markerUnits='strokeWidth' markerWidth='3' markerHeight='3' viewBox='0 0 10 10' refX='5' refY='5' orient='auto'>\n")
		f.write("<polygon points='0,0 5,5 0,10 10,5 ' fill='black'/>\n")
		f.write("</marker>\n")
		f.write("</defs>\n")

		dsppos.each_with_index{|mm,i|
			modobj = mlist[i]
			x,y = mm
			f.write("<g>\n")
			f.write("<title>#{modobj[0]} #{modobj[1]}</title>\n" )

			mstr = "<circle cx='#{x*60+20}' cy='#{y*60+20}' r='20' stroke='blue' fill='white' stroke-width='1'/>\n"
			f.write(mstr)
			mstr = "<text x='#{x*60}' y='#{y*60+20}' fill='black'>"
			mstr +=  modobj[0]
			mstr += " </text>\n"
			f.write(mstr)
			f.write("</g>\n")
		}

		linklist.each{|fr,to|
			frNo = fr[1] 
			toNo = to[1] 
			frTp = fr[0] 
			toTp = to[0] 
			frX , frY = dsppos[frNo]
			toX , toY = dsppos[toNo]
			x = toX-frX
			y = toY-frY
			z = ((x ** 2) + (y ** 2)) ** 0.5
		
			xsub = 20.0 * x / z
			ysub = 20.0 * y / z

			f.write("<g>\n")
			f.write("<title>#{frTp} => #{toTp}</title>\n" )
			f.write("<line x1='#{20+frX*60+xsub}' y1='#{20+frY*60+ysub}' x2='#{20+toX*60-xsub}' y2='#{20+toY*60-ysub}' stroke='black' stroke-width='5' marker-end='url(#endmrk)'/>\n")
			f.write("</g>\n")
		}

		f.write("</svg>\n")

		f.close() if fname != nil
	rescue => error 
		puts error
	end
end




def changeSVG_D3(mlist,iolist,linklist,fname=nil)

	dsppos,ymax,xmax = dicisionPos(mlist,iolist)

	begin
		if fname == nil then
			f=STDOUT
		else
			f=open(fname, 'w')
		end

	
		f.write("<html>\n")
		f.write("<head>\n")
	
		f.write("<script src='http://d3js.org/d3.v3.min.js' charset='utf-8'></script>\n")
		f.write("<script>\n")
		f.write("var NodeDATA=[")

		mlastNo = dsppos.size
		dsppos.each_with_index{|mm,i|
			modobj = mlist[i]
			x,y = mm
			if  modobj[3] == "" then
				f.write("{ title:\"#{modobj[0]} #{modobj[1]}\",")
			else
				f.write("{ title:\"#{modobj[0]} #{modobj[1]} @ #{modobj[3]}\",")
			end

			f.write(" x:#{x*60+20} , y:#{y*60+20} , name:\"#{modobj[0]}\"}" ) 

			if mlastNo==i+1 then
				f.write("]\n")
			else
				f.write(",\n")
			end
		}
		f.write("var EdgeDATA=[")

		elastNo = linklist.size
		linklist_n2e=Array.new(mlastNo)

		linklist.each_with_index{|frto,i|
			fr,to = frto
			frNo = fr[1] 
			toNo = to[1] 
			frTp = fr[0] 
			toTp = to[0] 
			frX , frY = dsppos[frNo]
			toX , toY = dsppos[toNo]

			linklist_n2e[frNo] =[[],[]] if linklist_n2e[frNo] == nil 
			linklist_n2e[frNo][0].push(i.to_s)

			linklist_n2e[toNo] =[[],[]] if linklist_n2e[toNo] == nil
			linklist_n2e[toNo][1].push(i.to_s)

			f.write("{ title:\"#{frTp} => #{toTp} \"," )
			f.write(" x1:#{frX*60+20},y1:#{frY*60+20},x2:#{toX*60+20},y2:#{toY*60+20} }" )
			if elastNo==i+1 then
				f.write("]\n")
			else
				f.write(",\n")
			end
		}

		n2elastNo = linklist_n2e.size()
		f.write("var LinkLIST=[")
		
		linklist_n2e.each_with_index{|n2elist,i|

			f.write("[[#{n2elist[0].join(',')}],[#{n2elist[1].join(',')}]]")
			if n2elastNo ==i+1 then
				f.write("]\n")
			else
				f.write(",\n")
			end
		}

		f.write("</script>\n")
		f.write("</head>")
		f.write("<body>")
		f.write("<svg id='flowDspArea' height='#{ymax*60*2}' width='#{xmax*60*2}'>\n")
		f.write("<defs>\n")
		f.write("<marker id='endmrk' markerUnits='strokeWidth' markerWidth='3' markerHeight='3' viewBox='0 0 10 10' refX='5' refY='5' orient='auto'>\n")
		f.write("<polygon points='0,0 5,5 0,10 10,5 ' fill='black'/>\n")
		f.write("</marker>\n")
		f.write("</defs>\n")
		f.write("</svg>\n")
		scp =<<EOS
	<script>
	svgGroup = d3.select('#flowDspArea');
	node_g = svgGroup.selectAll('g .node').data(NodeDATA);
	edge_g = svgGroup.selectAll('g .edge').data(EdgeDATA);
	// 移動処理用
	var drag = d3.behavior.drag()
	drag.on('drag', dragMove);
	function dragMove(d,i) {
		d.x += d3.event.dx
  	d.y += d3.event.dy
   	d3.select(this)
   		.attr('transform','translate('+d.x+','+d.y+')')
		for(var j=0 ; j<LinkLIST[i][0].length;j++){
			EdgeDATA[LinkLIST[i][0][j]].x1 += d3.event.dx
			EdgeDATA[LinkLIST[i][0][j]].y1 += d3.event.dy
	   	d3.select('#edgeP-'+LinkLIST[i][0][j])
				.attr('x1',function(d) {
					return d.x1 + ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('x2',function(d) {
					return d.x2 - ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('y1',function(d) {
					return d.y1 + ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('y2',function(d) { 
					return d.y2 - ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
		}
		for(var j=0 ; j<LinkLIST[i][1].length;j++){
			EdgeDATA[LinkLIST[i][1][j]].x2 += d3.event.dx
			EdgeDATA[LinkLIST[i][1][j]].y2 += d3.event.dy
	   	d3.select('#edgeP-'+LinkLIST[i][1][j])
				.attr('x1',function(d) {
					return d.x1 + ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('x2',function(d) {
					return d.x2 - ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('y1',function(d) {
					return d.y1 + ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
				.attr('y2',function(d) { 
					return d.y2 - ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
				})
		}
	}
 	node_g2 = node_g.enter().append('g')
		.attr('class', 'node')
		.attr('id', function (d,i) {return 'node-' + i;})
		.attr('transform',function (d) { return 'translate('+d.x+','+d.y+')'})
    .call(drag)		

	node_g2.append('title')
			.text(function(d) { return d.title})

	node_g2.append('circle')
		.attr('r',20)
		.attr('stroke','blue')
		.attr('fill','white')
		.attr('stroke-width',1)

	node_g2.append('text')
		.attr('x',function(d) { return -20})
		.attr('fill','black')
		.text(function(d) { return d.name})

 	edge_g2 = edge_g.enter().append('g')
		.attr('class', 'edge')
		.attr('id', function (d,i) {return 'edge-' + i;})

	edge_g2.append('line')
		.attr('id', function (d,i) {return 'edgeP-' + i;})
		.attr('x1',function(d) {
			return d.x1 + ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
		})
		.attr('x2',function(d) {
			return d.x2 - ( 20.0 * (d.x2-d.x1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
		})
		.attr('y1',function(d) {
			return d.y1 + ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
		})
		.attr('y2',function(d) { 
			return d.y2 - ( 20.0 * (d.y2-d.y1) / (Math.pow(Math.pow(d.x2-d.x1,2)+Math.pow(d.y2-d.y1,2),0.5)))
		})
		.attr('stroke','black')
		.attr('stroke-width','5')
		.attr('marker-end','url(#endmrk)')
	</script>
EOS

		f.write(scp)
		f.write("</body>\n")
		f.write("</html>\n")
		f.close()

	rescue => error 
		puts error
	end

end

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
					p "unknown parameter1"
					p arg,klist
				end
			elsif vals.size()==2 then
				kwargs[vals[0]] = vals[1]
			else 
				p "unknown parameter2"
					p arg,klist
			end
		}
	elsif arg.instance_of?(Hash) then
		kwargs = arg		
	elsif arg.instance_of?(Array) and uk!=nil then
		kwargs[uk] = arg	
	else
		p "args type str or hash"
		return nil
	end
	
	exval = []
	kwargs.each{|k,v|
		next if klist[0].include?(k) and v.instance_of?(String)
		next if klist[0].include?(k)
		next if klist[1].include?(k) and v == true
		next if k == "tag"
		next if k == "dlog"
		exval.push(k)
		p k + " is not keyword"
	}
	exval.each{|k|
		kwargs.delete(k)
	}
	return kwargs
end



# arg :hash or string
def arg2dict(arg,klist,uk=nil)
	kwargs ={}
	if arg.instance_of?(String) then
		kwargs["cmdstr"] = "'#{arg}'" 
	elsif arg.instance_of?(Hash) then
		kwargs = arg		
	else
		p "args type str or hash"
		return nil
	end
	
	exval = []
	kwargs.each{|k,v|
		next if klist[0].include?(k) and v.instance_of?(String)
		next if klist[0].include?(k)
		next if klist[1].include?(k) and v == true
		next if k == "tag"
		next if k == "dlog"
		exval.push(k)
		p k + " is not keyword"
	}
	exval.each{|k|
		kwargs.delete(k)
	}
	return kwargs
end


class NysolMOD

	attr_accessor :name, :kwd,:inplist,:outlist,:nowdir,:msg,:tag,:dlog

	def initialize(name=nil,kwd=nil)
		@name = name
		@kwd   = kwd
		@defaltdir = "o"
		@nowdir   = @defaltdir
		@inplist ={"i"=>[],"m"=>[]}
		@outlist ={"o"=>[],"u"=>[]}
		@tag = ""
		@dlog = ""


		if @kwd.has_key?("tag") then
			@tag = kwd["tag"]
			@kwd.delete("tag") 
		end

		if @kwd.has_key?("dlog") then
			@dlog = kwd["dlog"]
			@kwd.delete("dlog") 
		end

			
		if @kwd.has_key?("i") then
			@inplist["i"].push(@kwd["i"])
			@kwd.delete("i") 
		end

		if @kwd.has_key?("o") then
			@outlist["o"].push(@kwd["o"])
			@kwd.delete("o") 
		end

		if @kwd.has_key?("m") then
			@inplist["m"].push(@kwd["m"])
			@kwd.delete("m") 
		end

		if @kwd.has_key?("u") then
			@outlist["u"].push(@kwd["u"])
			@kwd.delete("u") 
		end
		@msg=false
	end

	def direction(dir)
		@nowdir   = dir
		return self
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
		@inplist["i"].push(pre) 
		pre.outlist[pre.nowdir].push(self)
		if not @inplist["m"].empty? and inplist["m"][0].is_a?(NysolMOD) then			
			@inplist["m"][0].outlist[@inplist["m"][0].nowdir].push(self)
		end
		return self
	end

	#数値入れる？
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
	# f.w キーワードチェック入れる

	def paraUpdate(kw)
		@kwd.update(kw)

		if @kwd.has_key?("i") then
			@inplist["i"].push(@kwd["i"])
			@kwd.delete("i") 
		end

		if @kwd.has_key?("o") then
			@outlist["o"].push(@kwd["o"])
			@kwd.delete("o") 
		end

		if @kwd.has_key?("m") then
			@inplist["m"].push(@kwd["m"])
			@kwd.delete("m") 
		end

		if @kwd.has_key?("u") then
			@outlist["u"].push(@kwd["u"])
			@kwd.delete("u") 
		end
	end

	def check_dupObjSub(sumiobj,dupobj,obj)
		if sumiobj.has_key?(obj) then
			if dupobj.has_key?(obj) then
				dupobj[obj] += 1
			else
				dupobj[obj] = 2			
			end
			return true 
		else
			if not obj.is_a?(String) then
				sumiobj[obj] = true 
			end
			return false
		end
	end


	def check_dupObj(sumiobj,dupobj)

		return if check_dupObjSub(sumiobj,dupobj,self) 

		if ! @inplist["i"].empty? then
			if @inplist["i"][0].is_a?(NysolMOD)then
				@inplist["i"][0].check_dupObj(sumiobj,dupobj)
			elsif @inplist["i"][0].is_a?(String) then
				check_dupObjSub(sumiobj,dupobj,@inplist["i"][0])
			elsif @inplist["i"][0].is_a?(Array) then
			end
		end

		if ! @inplist["m"].empty? then
			if @inplist["m"][0].is_a?(NysolMOD) then
				@inplist["m"][0].check_dupObj(sumiobj,dupobj) 
			elsif @inplist["m"][0].is_a?(String) then
				check_dupObjSub(sumiobj,dupobj,@inplist["m"][0])
			elsif @inplist["m"][0].is_a?(Array) then
			end
		end
	end



	def self.addTee(dupobj)

		dupobj.each{|obj,_v|
			obj.outlist.each{|k,_vv|
				next if obj.outlist[k].empty?
				
				if obj.outlist[k].size() == 1 then
					outll = obj.outlist[k][0]
					fifoxxx=Nysol_Mfifo.new({"i"=>obj})			
					obj.outlist[k][0] = fifoxxx
					fifoxxx.outlist["o"]=[outll]
					if ! outll.inplist["i"].empty? and obj == outll.inplist["i"][0] then
						outll.inplist["i"] = [fifoxxx]
					end
					if outll.inplist["m"]!=0 and obj == outll.inplist["m"][0] then
						outll.inplist["m"] = [fifoxxx]
					end
				else 
					outll = obj.outlist[k]
					teexxx = Nysol_M2tee.new({"i"=>obj})
					obj.outlist[k]= [teexxx]
					teexxx.outlist["o"] = [] 
					outll.each{|outin|
						if !outin.inplist["i"].empty? and obj == outin.inplist["i"][0] then
							fifoxxx=Nysol_Mfifo.new({"i"=>teexxx})			
							teexxx.outlist["o"].push(fifoxxx)
							fifoxxx.outlist["o"]=[outin]
							outin.inplist["i"] = [fifoxxx]
						end
						if !outin.inplist["m"].empty? and obj == outin.inplist["m"][0] then
							fifoxxx=Nysol_Mfifo.new({"i"=>teexxx})
							teexxx.outlist["o"].push(fifoxxx)
							fifoxxx.outlist["o"]=[outin]
							outin.inplist["m"] = [fifoxxx]
						end
					}
				end
			}
		}
	end



	def change_modNetwork()
		self.change_modNetworks([self])
	end


	def self.change_modNetworks(mods)
		sumiobj={}
		dupobj={}
		mods.each{|mod|
			mod.check_dupObj(sumiobj,dupobj)
		}
		add_mod =[]
		sumiobj.each{|obj,_t|
			if obj.is_a?(NysolMOD) then
				next if obj.name=="readlist"
				next if obj.name=="writelist"
				if ! obj.inplist["i"].empty?  and obj.inplist["i"][0].is_a?(Array) then
					rlmod = Nysol_Readlist.new(obj.inplist["i"][0])
					rlmod.outlist["o"] = [obj]
					obj.inplist["i"][0]=rlmod
				end

				if ! obj.inplist["m"].empty?  and obj.inplist["m"][0].is_a?(Array) then
					rlmod = Nysol_Readlist.new(obj.inplist["m"][0])
					rlmod.outlist["o"] = [obj]
					obj.inplist["m"][0]=rlmod
				end
				if ! obj.outlist["o"].empty?  and obj.outlist["o"][0].is_a?(Array) then
					wlmod = Nysol_Writelist.new(obj.outlist["o"][0])
					wlmod.inplist["i"]=[obj]
					obj.outlist["o"][0] = wlmod
				end

				if ! obj.outlist["u"].empty?  and obj.outlist["u"][0].is_a?(Array) then
					wlmod = Nysol_Writelist.new(obj.outlist["u"][0])
					wlmod.inplist["i"]=[obj]
					obj.outlist["u"][0] = wlmod
				end

				if obj.dlog != "" then
					if !obj.outlist["o"].empty? then

						wcsv_o = Nysol_Writecsv.new(obj.dlog+"_o")
						wcsv_o.inplist["i"]=[obj]
						obj.outlist["o"].push(wcsv_o)
						
						if dupobj.has_key?(obj) then
							dupobj[obj] += 1
						else
							dupobj[obj] = 2
						end
						add_mod.push(wcsv_o)
					end

					if !obj.outlist["u"].empty? then

						wcsv_u = Nysol_Writecsv.new(obj.dlog+"_u")
						wcsv_u.inplist["i"]=[obj]
						obj.outlist["u"].push(wcsv_u)

						if dupobj.has_key?(obj) then
							dupobj[obj] += 1
						else
							dupobj[obj] = 2
						end
						add_mod.push(wcsv_u)
					end
				end
			end
		}
		NysolMOD.addTee(dupobj) if !dupobj.empty? 

		mods.concat(add_mod)

	end

	def selectUniqMod(sumiobj,modlist)

		return nil if sumiobj.has_key?(self)

		pos = sumiobj.size()
		sumiobj[self] = true
		modlist[self]=pos
		
		@inplist["i"].each{|obj|
			obj.selectUniqMod(sumiobj,modlist) if obj.is_a?(NysolMOD)
		}
		@inplist["m"].each{|obj|
			obj.selectUniqMod(sumiobj,modlist) if obj.is_a?(NysolMOD)
		}
	end


	def self.makeModList(uniqmod,modlist,iolist)

		uniqmod.each{|obj,no|
			modlist[no]= [obj.name,obj.para2str(),{},obj.tag]
			iolist[no]=[[],[],[],[]]

			obj.inplist["i"].each{|ioobj|
				#uniqmodに無ければ今回のルート外のはず
				if ioobj.is_a?(NysolMOD) and uniqmod.has_key?(ioobj) then
					iolist[no][0].push(uniqmod[ioobj])
				elsif ioobj.is_a?(Array) then
					modlist[no][2]["i"]=ioobj
				elsif ioobj.is_a?(String) then
					modlist[no][2]["i"]=ioobj
				end
			}
			obj.inplist["m"].each{|ioobj|
				#uniqmodに無ければ今回のルート外のはず
				if ioobj.is_a?(NysolMOD) and uniqmod.has_key?(ioobj) then
					iolist[no][1].push(uniqmod[ioobj])
				elsif ioobj.is_a?(Array) then
					modlist[no][2]["m"]=ioobj
				elsif ioobj.is_a?(String) then
					modlist[no][2]["m"]=ioobj
				end
			}
			obj.outlist["o"].each{|ioobj|
				#uniqmodに無ければ今回のルート外のはず
				if ioobj.is_a?(NysolMOD) and uniqmod.has_key?(ioobj) then
					iolist[no][2].push(uniqmod[ioobj])
				elsif ioobj.is_a?(Array) then
					modlist[no][2]["o"]=ioobj
				elsif ioobj.is_a?(String) then
					modlist[no][2]["o"]=ioobj
				end
			}
			obj.outlist["u"].each{|ioobj|
				#uniqmodに無ければ今回のルート外のはず
				if ioobj.is_a?(NysolMOD) and uniqmod.has_key?(ioobj) then
					iolist[no][3].push(uniqmod[ioobj])
				elsif ioobj.is_a?(Array) then
					modlist[no][2]["o"]=ioobj
				elsif ioobj.is_a?(String) then
					modlist[no][2]["o"]=ioobj
				end
			}
		}
	end


	def self.getLink(iolist,base,to)

		iolist[base][2].each{|v|
			return "o" if v == to
		}
		iolist[base][3].each{|v|
			return "u" if v == to
		}
		return nil
	end


	def self.makeLinkList(iolist,linklist)

		iolist.each_with_index{|val,idx|
			rtn = nil
			val[0].each{|v|
				if v.is_a?(Integer) then
					rtn = getLink(iolist,v,idx)
					linklist.push([[rtn,v],["i",idx]]) if rtn != nil
				end
			}
			val[1].each{|v|
				if v.is_a?(Integer) then
					rtn = getLink(iolist,v,idx)
					linklist.push([[rtn,v],["m",idx]]) if rtn != nil
				end
			}
		}
	end


	def run(kw_args={})

		self.runs([self],kw_args)

	end

	def self.runs(mods,kw_args={})

		msgF =  (kw_args.has_key?("msg") and  kw_args["msg"] == "on") ? true : false
				

		stocks =Array.new(mods.size)
		outfs = Array.new(mods.size)
		
		mods.each_with_index{|mod,i|
			stocks[i] = mod.outlist["o"][0] unless mod.outlist["o"].empty?
		}		
				
		dupobjs = Marshal.load(Marshal.dump(mods))

		#oが無ければlist出力追加
		runobjs =Array.new(dupobjs.size)

		dupobjs.each_with_index{|dupobj,i| 

			if dupobj.outlist["o"].empty? then
				runobjs[i]= dupobj.writelist(Array.new())
			elsif dupobj.name != "writelist" and dupobj.outlist["o"][0].is_a?(Array) then
				runobj = dupobj.writelist(stocks[i])
				dupobj.outlist["o"] = [runobj]
				runobjs[i]= runobj
			elsif dupobj.outlist["o"][0].is_a?(Array) then				
				dupobj.outlist["o"][0] = stocks[i]
				runobjs[i]= dupobj
			else
				runobjs[i]= dupobj
			end
			outfs[i] = runobjs[i].outlist["o"][0]
		}

		NysolMOD.change_modNetworks(runobjs)
		
		uniqmod={} 
		sumiobj= {}
		
		runobjs.each{|mod|
			mod.selectUniqMod(sumiobj,uniqmod)
		}

		modlist = Array.new(uniqmod.size()) #[[name,para]]
		iolist  = Array.new(uniqmod.size()) #[[iNo],[mNo],[oNo],[uNo]]

		NysolMOD.makeModList(uniqmod,modlist,iolist)

		linklist=[]
		NysolMOD.makeLinkList(iolist,linklist)

		shobj = NYSOLRUBY::MshCore.new(msgF)
		shobj.runL(modlist,linklist)
		return outfs
	end

	def self.drawModelsCore(mod)

		dupshowobjs = Marshal.load(Marshal.dump(mod))
		showobjs =[]
		rtnlist = []

		dupshowobjs.each{|dupshowobj|
			if dupshowobj.outlist["o"].empty? then
				showobjs.push(dupshowobj.writelist(rtnlist))
			elsif dupshowobj.name != "writelist" and dupshowobj.outlist["o"][0].is_a?(Array) then
				showobj = dupshowobj.writelist(dupshowobj.outlist["o"][0])
				dupshowobj.outlist["o"] = [showobj]
				showobjs.push(showobj)
			else
				showobjs.push(dupshowobj)
			end
		}

		NysolMOD.change_modNetworks(showobjs)

		uniqmod={} 
		sumiobj={}

		showobjs.each{|modx|
			modx.selectUniqMod(sumiobj,uniqmod)
		}
		modlist=Array.new(uniqmod.size) #[[name,para]]
		iolist=Array.new(uniqmod.size) #[[iNo],[mNo],[oNo],[uNo]]
		NysolMOD.makeModList(uniqmod,modlist,iolist)

		linklist=[]
		NysolMOD.makeLinkList(iolist,linklist)
		return modlist,iolist,linklist

	end



	#GRAPH表示 #deepコピーしてからチェック
	def self.drawModels(mod,fname=nil)

		modlist,iolist,linklist = NysolMOD.drawModelsCore(mod)		
		changeSVG(modlist,iolist,linklist,fname)		

	end

	#GRAPH表示 #deepコピーしてからチェック
	def drawModel(fname=nil)

		NysolMOD.drawModels([self],fname)
		
	end


	#GRAPH表示 #deepコピーしてからチェック
	def self.drawModelsD3(mod,fname=nil)

		modlist,iolist,linklist = NysolMOD.drawModelsCore(mod)		
		changeSVG_D3(modlist,iolist,linklist,fname)		

	end

	#GRAPH表示 #deepコピーしてからチェック
	def drawModelD3(fname=nil)

		NysolMOD.drawModelD3s([self],fname)

	end


	def self.modelInfos(mod)

		dupshowobjs = Marshal.load(Marshal.dump(mod))

		showobjs =[]
		rtnlist = []
		dupshowobjs.each{|dupshowobj|
			if dupshowobj.outlist["o"].empty? then
				showobjs.push(dupshowobj.writelist(rtnlist))
			elsif dupshowobj.name != "writelist" and dupshowobj.outlist["o"][0].is_a?(Array) then 
				showobj = dupshowobj.writelist(dupshowobj.outlist["o"][0])
				dupshowobj.outlist["o"] = [showobj]
				showobjs.push(showobj)
			else
				showobjs.push(dupshowobj)
			end
		}
		NysolMOD.change_modNetworks(showobjs)

		uniqmod={} 
		sumiobj= {}

		showobjs.each{| mod|
			mod.selectUniqMod(sumiobj,uniqmod)
		}

		modlist=Array.new(uniqmod.size) #[[name,para]]
		iolist=Array.new(uniqmod.size) #[[iNo],[mNo],[oNo],[uNo]]
		NysolMOD.makeModList(uniqmod,modlist,iolist)

		linklist=[]
		NysolMOD.makeLinkList(iolist,linklist)
		
		return {"modlist"=>modlist,"iolist"=>iolist,"linklist"=>linklist}
	end

	def modelInfo()
		NysolMOD.modelInfos([self])
	end


  def each()

		if @outlist["o"].empty? then
			runobj = Marshal.load(Marshal.dump(self))
		else
			print ("type ERORR")
			return None
		end


		runobj.change_modNetwork()

		uniqmod={} 
		sumiobj= {}
		runobj.selectUniqMod(sumiobj,uniqmod)

		modlist= Array.new(uniqmod.size()) 
		iolist=Array.new(uniqmod.size()) 
		NysolMOD.makeModList(uniqmod,modlist,iolist)

		linklist=[]
		NysolMOD.makeLinkList(iolist,linklist)

		shobj = NYSOLRUBY::MshCore.new(runobj.msg)
		vvv = shobj.runiter(modlist,linklist)

		
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


	def mfifo(args)
		return Nysol_Mfifo.new(args).addPre(self)
  end
	def self.mfifo(args)
		return Nysol_Mfifo.new(args)
  end

	def writecsv(args)
		return Nysol_Writecsv.new(args).addPre(self)
  end

	def self.writecsv(args)
		return Nysol_Writecsv.new(args)
  end

	def writelist(args)
		return Nysol_Writelist.new(args).addPre(self)
  end

	def self.writelist(args)
		return Nysol_Writelist.new(args)
  end

	def readcsv(args)
		return Nysol_Readcsv.new(args).addPre(self)
  end

	def self.readcsv(args)
		return Nysol_Readcsv.new(args)
  end

	def readlist(args)
		return Nysol_Readlist.new(args).addPre(self)
  end

	def self.readlist(args)
		return Nysol_Readlist.new(args)
  end

	def self.cmd(args)
		return Nysol_Excmd.new(args)
  end

	def cmd(args)
		return Nysol_Excmd.new(args).addPre(self)
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


class  Nysol_Mfifo < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("mfifo")
	def initialize(args)
		super("mfifo",args2dict(args,@@kwdList))
	end
end

class  Nysol_M2tee < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("m2tee")
	def initialize(args)
		super("m2tee",args2dict(args,@@kwdList))
	end
end


class  Nysol_Writelist < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("writelist")
	def initialize(args)
		super("writelist",args2dict(args,@@kwdList,uk="o"))
	end
end

class  Nysol_Writecsv < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("writecsv")
	def initialize(args)
		super("writecsv",args2dict(args,@@kwdList,uk="o"))
	end
end

class  Nysol_Readcsv < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("readcsv")
	def initialize(args)
		kwargs={}
		if args.instance_of?(String) then
			kwargs["i"] = args	
		elsif args.instance_of?(Hash) then
			kwargs = args		
		elsif args.instance_of?(Array) then
			kwargs["i"] = args.join(",")
		else 
			p "unsuport type"
		end
		super("readcsv",args2dict(kwargs,@@kwdList))
	end
end
class  Nysol_Readlist < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("readlist")
	def initialize(args)
		super("readlist",args2dict(args,@@kwdList,uk="i"))
	end
end


class  Nysol_Excmd < NysolMOD
	@@kwdList = NYSOLRUBY::MshCore.new().getparalist("cmd")
	def initialize(args)
		super("cmd",arg2dict(args,@@kwdList))
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



pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

function _init()
	t=time()
	dt=0
	debug=false

	-- constants
	gravity=9.81*2
	drag=0.1
	game_dur=25.5 -- seconds

	scn=nil
	game_flow=flow.scene(credits_scn)
	.andthen(
		-- main game loop
		flow.forever(
			flow
			.scene(title_scn)
			.flatmap(function(strings)
			  return flow.scene(dialogue_scn,strings)
			 end)
			.flatmap(function(strings)
			  return flow.scene(explainer_scn,strings)
    end)
			.flatmap(function(strings)
			  return flow.scene(game_scn,strings)
    end)
			.flatmap(function(score)
				return flow.scene(results_scn, score)
			end)
		)
	)

	game_flow.go(
		-- transition to next scene
		function(nxt)
			if scn and scn.destroy then scn:destroy() end
			scn = nxt
			if scn.init then scn:init() end
		end,
		-- end game
		function() end
	)
end

function _update()
	local tt=time()
	dt=tt-t
	t=tt
	scn:update(dt)
end

function _draw()
	scn:draw()
end

-->8
--scenes

function credits_scn(nxt)
	local scn = {
		t=0,
	}

	function scn.update(s,dt)
		s.t += dt
		if s.t > 3 then
			nxt(nil)
		end
		if btnp(❎) then
			nxt(nil)
		end
	end

	function scn.draw()
		cls(1)
		color(7)
		print("a game by:",44,60)
		print("josiah, honamiさん, and matt",10,70)
	end

	return scn
end

function title_scn(nxt)
 local strings=strings_init()
	local scn = {
	 langs=strings:getlangs(),
	 lang=1,
	 strings=strings,
	}

	function scn.init(s)
		music(0)
	end

	function scn.update(s,dt)
	 if btnp(⬆️) then
	  s.lang=max(s.lang-1,1)
	  s.strings:setlang(s.lang)
	 elseif btnp(⬇️) then
	  s.lang=min(s.lang+1,#s.langs)
	  s.strings:setlang(s.lang)
	 end
		if btnp(❎) then
			nxt(s.strings)
		end
	end

	function scn.draw(s)
		cls(1)
		color(7)
		local title="\^w\^t".."せつbun"
		local x,y=36,48
		 print("setsubun",x+12,y+14,13)
		for xx=-1,1,1 do
			for yy=-1,1,1 do
				print(title,x+xx,y+yy,13)
			end
		end
		print(title, 36, 48,7)
		
		y=80
		
		--show language indicator
		print("▶",41,y+(s.lang-1)*8,9)
		
		--show languages
		for k,v in pairs(s.langs) do
		 print(v.name,47,y,7)
		 y+=8
		end
	end

	return scn
end

function explainer_scn(nxt,strings)
	local scn = {
		timer=0,
		dur=1,
		is_done=false,
		strings=strings,
	}

	function scn.update(s,dt)
		s.timer+=dt
		if s.timer<s.dur then return end
		s.is_done=true
		if btnp(❎) then
			nxt(s.strings)
		end
	end

	function scn.draw(s)
		cls(1)
		color(7)
		
		print(s.strings:get("how_to_play_1"), 40, 24)
		print(s.strings:get("how_to_play_2"), 4, 48)

		if s.is_done then
			print("press ❎ to start", 32, 102)
		end
	end

	return scn
end

function results_scn(nxt, score)
 local scn = {
  t=0,
  inputlock=1,
  result=nil,
  done=false,
  
  scorespd=0.075,
  scorecounter=0,
  scoretimer=0,
  
  --the speed of the change of
  -- the result display
  resulttimer=0,
  resultspd=0.1,
 }

 --sspr params for kanji
 local kanji = {
  {
   name="daikichi",
   params={
    {120,0},
    {120,8},
   },
  },
  {
   name="kichi",
   params={
    {120,8},
   },
  },
  {
   name="chuukichi",
   params={
    {120,16},{120,8},
   },
  },
  {
   name="shoukichi",
   params={
    {120,24},{120,8},
   },
  },
  {
   name="mikichi",
   params={
    {112,0},{120,8},
   },
  },
  {
   name="kyou",
   params={
    {112,8},
   },
  },
  {
   name="daikyou",
   params={
    {120,0},{112,8},
   },
  }
 }

	function scn.init()
		music(24)
	end
	
	function scn.update(s,dt)
	 s.t+=dt
	 
	 if not s.done then
	  s.scoretimer+=dt
	 	s.resulttimer+=dt
	 
	  --update kanji
		 if s.resulttimer>=s.resultspd then
		  s.result=rnd(kanji)
		  s.resulttimer%=s.resultspd
		 end
		 
		 --update score
		 if s.scoretimer>=s.scorespd then
		  s.scorecounter=min(score,s.scorecounter+1)
		  s.scoretimer%=s.scorespd
		 end
		 
		 --settle the result
		 if s.scorecounter==score then
		  s.done=true
		  s.result=rnd(kanji)
		 end
		end
	 
		if s.t>=s.inputlock and btnp(❎) then
			nxt(nil)
		end
	end

	function scn.draw(s)
		cls(1)
		color(7)
		
		if s.result then
		 x=64-#s.result.params*8
		 for k,v in ipairs(s.result.params) do
		  local sx,sy=unpack(v)
		  sspr(sx,sy,8,8,x,32,16,16)
		  x+=17
		 end
		end
		local scorex,scorey=58,58
		box(scorex-2,scorey-2,17,13,7)
		if s.scorecounter<10 then
			scorex+=7
		end
		print("\^w\^t"..s.scorecounter, scorex, scorey)
		if s.done then
		 print("press ❎ to restart",26,100)
		end
	end

	return scn
end

-->8
--game scene

function game_scn(nxt,strings)
	local scn={
		t=0,
		score=0,
		effects={},
		beans={},
		kids={},
		strings=strings,
	}

	add(scn.kids, kids_new(v3(32,0,14),8))
	add(scn.kids, kids_new(v3(96,0,14),12))
	
	local dad=dad_new(v3(63,0,14))
	local cam=cam_new()
	map_init()

	function scn.init()
		music(16)
	end

	function scn.update(s, dt)
		dad:update(dt)
		cam:update(dt,dad.pos.x-63)
		
		for k,v in pairs(s.kids) do
			v:update(dt,scn)
		end
		for k,v in pairs(s.beans) do
			v:update(dt,scn)
			--collide with dad
			if not v.collided
				and v.pos.x>=dad.pos.x-8
				and v.pos.x<=dad.pos.x+8
				and v.pos.y>=dad.pos.y
				and v.pos.y<=dad.pos.y+24
			then
				s:bean_hit(v)
			end
			-- cleanup beans past their lifetime
			if v.age>=v.ttl then
				del(s.beans,v)
			end
		end
		for k,v in pairs(s.effects) do
			v:update(dt)
			--cleanup barks+particles past their lifetime
			if v.age>=v.ttl then
				del(s.effects,v)
			end
		end
		
		s.t += dt
		if s.t>game_dur then
			nxt(s.score)
		end
	end
	
	function scn.draw(s)
		cls()
		cam:draw()
		map_draw()
		
		local actors={}
		add(actors,dad)
		add_all(actors,s.kids)
		add_all(actors,s.beans)
		--scan through all possible depths
		--draw kids+dad+beans sorted
		--from back (+z) to front (-z)
		local lo,hi=mapinfo.char_minz,mapinfo.char_maxz
		for depth=hi,lo,-1 do
			for _,a in pairs(actors) do
				if a.pos.z>=depth then
					a:draw()
					del(actors,a)
				end
			end
		end
		--draw effects on top
		for k,v in pairs(s.effects) do
			v:draw()
		end
		
		local time_left=game_dur-scn.t
		hud_draw(s,time_left)
	end

	function scn.destroy()
		music(-1,500) --fade out music
	end

	function scn.bean_hit(s,b)
		s.score+=1
		del(s.beans,b)
		local p=particle_new(b.pos)
		add(s.effects,p)
	end
	function scn.add_beans(s,beans)
		-- add all beans
		add_all(s.beans,beans)
	end
	function scn.add_bark(s,bark)
		add(s.effects,bark)
	end

	return scn
end


function dialogue_scn(nxt,strings)
	local scn={
		strings=strings,
	}

	local dialogue_flow = 
	 flow.scene(dialogue_box,
	 scn.strings:get("intro_1"))
	 .andthen(
	 flow.scene(dialogue_box,
	 scn.strings:get("intro_2")))
	 .andthen(
	 flow.scene(dialogue_box, 
	 scn.strings:get("intro_3")))
	 .andthen(
	 flow.scene(dialogue_box, 
	 scn.strings:get("intro_4")))
	 .andthen(
	 flow.scene(dialogue_box,
	 scn.strings:get("intro_5")))
	local dialogue=nil
	dialogue_flow.go(
		-- next dialogue box
		function(nxt)
			dialogue = nxt
		end,
		-- end scene
		function()
		 nxt(strings)
		end
	)

	function scn.update(s, dt)
		dialogue:update(dt)
	end
	
	function scn.draw(s)
		cls()
		dialogue:draw()
	end

	return scn
end


-->8
--dad,kids
dad_proto={
	--dad is 24 pixels tall, so
	-- 1.5m == 24px
	-- 9.8m == 156px?
	start_diving=function(d)
		d.state="diving"
		d.dive_timer=0
	end,
	start_cooldown=function(d)
		d.state="cooldown"
		d.cooldown_timer=0
	end,
	start_walking=function(d)
		d.state="walking"
	end,
	update=function(d,dt)
		if d.state == "walking" then
			d:update_walking(dt)
		elseif d.state == "diving" then
			d:update_diving(dt)
		elseif d.state == "cooldown" then
			d:update_cooldown(dt)
		end
	end,
	update_walking=function(d,dt)
		local v=v3(0,0,0)
		if btn(⬅️) then
			v.x-=1
		elseif btn(➡️) then
			v.x+=1
		end
		d:move(dt*d.spd*v)
		-- switch to diving
		if btn(⬅️) then
			d.direction=⬅️
		elseif btn(➡️) then
			d.direction=➡️
		end
		if btnp(❎) then
			d:start_diving()
			return
		end
	end,
	update_diving=function(d,dt)
		local v=v3(0,0,0)
		if d.direction==⬅️ then
			v.x-=1
		elseif d.direction==➡️ then
			v.x+=1
		end
		d:move(dt*d.dive_spd*v)
		-- switch to cooldown
		d.dive_timer+=dt
		if d.dive_timer>=d.dive_dur then
			d:start_cooldown()
		end
	end,
	update_cooldown=function(d,dt)
		-- switch back to walking
		d.cooldown_timer+=dt
		if d.cooldown_timer>=d.cooldown_dur then
			d:start_walking()
		end
	end,
	move=function(d,v)
		d.pos=d.pos+v
		d.pos.x=mid(mapinfo.char_minx,d.pos.x,mapinfo.char_maxx)
		d.pos.z=mid(mapinfo.char_minz,d.pos.z,mapinfo.char_maxz)
	end,
	draw=function(d)
		local fac=0
		if d.state=="diving" then
			fac=d.dive_timer/d.dive_dur
		elseif d.state=="cooldown" then
			fac=1
		end
		local rot=0.25*fac
		local flip=d.direction==⬅️
		local x,y=project(d.pos)
		-- dad sprite
		pd_rotate(x,y-12,rot,5.5,61,3,flip)
		--dad's mask
		local sign=flip and -1 or 1
		local mask_x,mask_y=rotate(sign*rot,0,-2)
		pd_rotate(x+mask_x,y-12+mask_y,rot,2,63,1,flip)
	end,
}
dad_meta={__index=dad_proto}

function dad_new(pos)
	local dad={
		pos=pos,
		spd=50,
		dive_spd=150,
		dive_dur=0.2,
		dive_timer=0,
		cooldown_dur=0.5,
		cooldown_timer=0,
		state="walking",
		direction=➡️
	}
	setmetatable(dad,dad_meta)
	return dad
end

--kids
kids_proto={
	start_moving=function(k)
		k.target=nil
		k.state="move"
	end,
	start_targeting=function(k)
		k.next=nil
		k.state="target"
	end,
	update=function(k,dt,scn)
		if k.state=="target" then
			k:update_target(dt,scn)
		elseif k.state=="move" then
			k:update_move(dt,scn)
		end
	end,
	update_target=function(k,dt,scn)
		--get target
		if not k.target then
			local x=k.pos.x+rnd(60)-30
			local y=8
			local z=14
			k.target=target_new(v3(x,y,z),rnd(1)+2)
			return
		end
		k.target:update(dt)
		--throw target
		if k.target.age>=k.target.ttl then
			k:throw_beans(scn)
			k:start_moving()
		end
	end,
	update_move=function(k,dt,scn)
		--kid movement
		--get pos
		if not k.next then
			local x=rnd_btwn(mapinfo.char_minx, mapinfo.char_maxx)
			local z=rnd_btwn(mapinfo.char_minz, mapinfo.char_maxz)
			k.next=v3(x,0,z)
		end
		if (k.pos-k.next):len()<=8 then
			--reached pos
			k:start_targeting()
		else
			--move
			local vel=vtoward(k.next,k.pos)
			k.pos+=k.spd*dt*vel
			if vel.x>0 then
				k.direction=⬅️
			else
				k.direction=➡️
			end
		end
	end,
	throw_beans=function(k,scn)
		local bark=barks_new("おにはそと!",k.pos+v3(0,20,0))
		scn:add_bark(bark)
		local vel=vtoward(k.target.pos,k.pos)
		local bg=beans_new(k.pos,vel,3)
		scn:add_beans(bg)
	end,
	draw=function(k)
		local x,y=project(k.pos)
		local flip=k.direction==⬅️
		if k.target then
			flip=k.target.pos.x>k.pos.x
		end
		pal(14,k.shirtcolor)
		spr(20,x-4,y-16,1,2,flip)
		pal(14,14)
		if k.target then
			k.target:draw()
		end
	end,
}
kids_meta={__index=kids_proto}

function kids_new(pos,shirtcolor)
	local k={
		pos=pos,
		direction=⬅️,
		targettime=0,
		spd=60,
		state="move",
		shirtcolor=shirtcolor or rnd({8,12}),
	}
	setmetatable(k,kids_meta)
	return k
end

-->8
--beans, particles
bean_proto={
	update=function(b,dt,scn)
		b.age+=dt
		
		local minx=mapinfo.char_minx
		local maxx=mapinfo.char_maxx
		
		if not b.grounded then
			--gravity
			b.vel.y-=gravity*dt
		end
		
		local x1,y1=(b.pos+b.vel):unpack()
		--collide with floor
		if y1<=0 then
			b.collided=true
			b.vel.y*=-1
		end
		--collide with wall
		if x1<=minx or x1>=maxx then
			b.collided=true
			b.vel.x*=-1
		end
		
		--add drag to reduce
		-- velocity over time
		b.vel*=1-drag

		--if the bean is close to
		-- to the ground and low
		-- velocity, lets stop
		-- the physics
		if abs(b.vel.y)<1 and abs(b.pos.y+b.vel.y)<5 then
			b.pos.y=0
			b.vel.y=0
			b.grounded=true
		end
		
		b.pos=b.pos+b.vel
	end,
	draw=function(b)
		local x,y=project(b.pos)
		spr(3,x-4,y-4)
	end,
}
bean_meta={__index=bean_proto}

function bean_new(p,v)
	local bean={
		pos=p,
		vel=v,
		grounded=false,
		ttl=10+rnd(3),
		age=0,
	}
	setmetatable(bean,bean_meta)
	return bean
end

function beans_new(p,v,n)
	local beans={}
	for n=1,n do
		local bean=bean_new(
			v3(
				p.x+rnd(10)-5,
				p.y+rnd(10),
				p.z
			),
			v3(
				v.x*8+rnd(6)-3,
				v.y*8+10,
				v.z
			)
		)
		add(beans, bean)
	end
	return beans
end

--particles
particles_proto={
	update=function(p,dt)
		p.age+=dt
	end,
	draw=function(p)
		local fac=p.age/p.ttl
		local r=4*(1-fac)
		local x,y=project(p.pos)
		circfill(x,y,r,7)
		circ(x,y,r,6)
	end,
}
particles_meta={__index=particles_proto}

function particle_new(p)
	local particle={
		pos=p,
		age=0,
		ttl=1,
	}
	setmetatable(particle,particles_meta)
	return particle
end

-->8
--targeting
target_proto={
	update=function(t,dt)
		t.age+=dt

		--stop moving target before
		--ttl
		if t.age/t.ttl<0.8 then
			local offset=v3(
				cos((t.t0+time())/2)*t.move.x,
				sin((t.t0+time())/2)*t.move.y,
				0
			)
			t.pos=t.base+offset
		end
	end,
	draw=function(t)
		local tcolor=7
		local fac=t.age/t.ttl
		if fac>0.8 then
			tcolor=8
		elseif fac>0.5 then
			tcolor=14
		end
		local x,y=project(t.pos)
		pal(7,tcolor)
		spr(4,x-4,y-4)
		pal(7,7)
	end,
}
target_meta={__index=target_proto}

function target_new(p,ttl)
	local t={
		--these are calculcated from
		--base+offset
		pos=p,
		base=p,
		move=v2(
			rnd(10)+5,
			rnd(3)+5
		),
		
		ttl=ttl,
		age=0,
		t0=rnd(1),
	}
	setmetatable(t,target_meta)
	return t
end

-->8
--camera and map

function map_init()
	mapinfo={
		-- wall dimensions (in map space)
		minx=0,
		maxx=48,
		miny=0,
		maxy=16,
		-- floor dimensions (in isometric space)
		char_minx=20,
		char_maxx=256,
		char_minz=0,
		char_maxz=28
	}
end

function map_draw()
	map(mapinfo.minx,mapinfo.miny,0,0,mapinfo.maxx,mapinfo.maxy)
	local y0=95

	--draw wall
	local y=y0
	for w=8,23 do
		tline(w,y,w,y-8,0,63-1/8,0,-1/8)
		y-=1
	end
	
	--draw tatami
	for tatami=3,33,2 do 
		local x=tatami*8-1
		local size=15
		for y=y0-size,y0 do
			tline(x,y,x+size,y,0,63)
			x-=1
		end
	end
end

-- project from 3d isometric space into screen space
function project(v)
	local x,y,z=v:unpack()
	local x1=x+0.5*z
	local y1=96-(y+0.5*z)
	return x1,y1
end

cam_proto={
	update=function(c,dt,target_x)
		c.x=mid(0,target_x,c.maxx)
	end,
	draw=function(c)
		camera(c.x,c.y)
	end
}
cam_meta={__index=cam_proto}
function cam_new()
	local cam={
		x=32,
		y=0,
		minx=0,
		maxx=152,
		followdist=32,
		followx=63,
		followy=63,
	}
	setmetatable(cam,cam_meta)
	return cam
end

-->8
-- hud
palette={
	-- colors
	bg=5,
	bg_alt=1,
	fg=7,
	border=13,
	accent=8,
	transparent=7,
	text=7,
	-- sprites
	ehomaki=1,
}

function hud_draw(s,time_left)
	camera()
	local x,y=0,0
	local w,h=128,16

	-- background for us to draw on top of
	boxfill(x,y,w,h, palette.bg)

	x=2
	y=2

	-- time remaining
	print(s.strings:get("hud_time"),x,y,palette.fg)

	x+=32
	w,h=128-12-x,7
 
	local fac=time_left/game_dur
	palt(palette.transparent,true)
	spr(40,x,y-1)
	local fillwidth=w*fac
	if fillwidth > 1 then
		boxfill(x+5,y-1,fillwidth,h,palette.ehomaki)
	end
	spr(42,x+5+w*fac,y-1)
	palt(palette.transparent,false)

	-- score
	x=2
	y+=8
	print(s.strings:get("hud_score"),x,y,palette.fg)

	x+=32
	print(s.score,x,y,palette.fg)
	
	-- controls
	x,y=0,128-16
	w,h=128,16
	
	boxfill(x,y,w,h,palette.bg)
	x+=6
	y+=6
	print(
		s.strings:get("hud_move")..
		": ⬅️➡️    "..
		s.strings:get("hud_dive")..
		": ❎",x,y,palette.fg
	)
end

function box(x,y,w,h,col)
	rect(x,y,x+w,y+h,col)
end

function boxfill(x,y,w,h,col)
	rectfill(x,y,x+w,y+h,col)
end

-- dialogue
textspeed=20 --characters per second

function dialogue_box(nxt, text)
	local dialogue = {
		t=0,
		dur=#text/textspeed,
		text="",
		is_done=false,
	}
	
	function dialogue.update(d,dt)
		d.t+=dt
		local num_chars=flr(#text*d.t/d.dur)
		d.text=sub(text,1,num_chars)
		-- go to next if text is done scrolling
		if d.t>=d.dur and btnp(❎) then
			nxt(nil)
		end
		-- skip to end of text
		if btnp(🅾️) or btnp(❎) then
			d.t=d.dur
		end
	end
	
	function dialogue.draw(d)
		camera()
		local x,y=1,92
		local w,h=125,34
		-- background for us to draw on top of
		boxfill(x,y,w,h, palette.bg)
		box(x,y,w,h, palette.border)
		-- draw the text
		x+=2
		y+=2
		print(d.text,x,y,palette.text)
		-- draw button hint
		if d.t>=d.dur then
			x=128-12
			y=128-8
			print("❎",x,y)
		end
	end

	return dialogue
end

-->8
--barks
barks_proto={
	update=function(b,dt)
		b.age+=dt
		b.pos.y+=15*dt
	end,
	draw=function(b)
		local x,y=project(b.pos)
		print(b.txt,x,y+1,6)
		print(b.txt,x-1,y+1,6)
		print(b.txt,x,y,5)
	end,
}
barks_meta={__index=barks_proto}

function barks_new(txt,pos)
	local b={
		pos=pos,
		txt=txt,
		ttl=2,
		age=0,
	}
	setmetatable(b,barks_meta)
	return b
end

-->8
--flow

function once(f)
	local is_done = false
	return function(val)
		if not is_done then
			is_done = true
			f(val)
		end
	end
end

flow = {}

function flow.create(go)
	local m = {}
	m.go = go
	
	function m.map(f)
		local new_go = function(nxt, done)
			m.go(nxt, function(x)
				done(f(x))
			end)
		end
		return flow.create(new_go)
	end

	function m.flatten()
		local new_go = function(nxt, done)
			m.go(nxt, function(n)
				n.go(nxt, done)
			end)
		end
		return flow.create(new_go)
	end

	function m.flatmap(f)
		return m.map(f).flatten()
	end
 
	function m.andthen(scn)
		return m.flatmap(function() return scn end)
	end
	
	return m
end

function flow.scene(make_scene, ...)
	local args = pack(...)
	local go = function(nxt, done)
		local scene = make_scene(once(done), unpack(args))
		nxt(scene)
	end
	return flow.create(go)
end


function flow.forever(scn)
	return scn.flatmap(function()
		return flow.forever(scn)
	end)
end

-->8
--math

function easein(i)
	return i*i*i--1-cos((i*3.14)/2)
end

function easeout(i)
 return 1-(1-i)^3
end

function rnd_btwn(lo,hi)
	return lo+rnd(hi-lo)
end

function add_all(table, to_add)
	for k,v in pairs(to_add) do
		add(table, v)
	end
end

function vtoward(u,v)
	return (u-v):unit()
end

function rotate(angle,x,y)
	local c,s=cos(angle),sin(angle)
	local tx=c*x+s*y
	local ty=-s*x+c*y
	return tx,ty
end

--https://www.lexaloffle.com/bbs/?pid=78451
function pd_rotate(x,y,rot,mx,my,w,flip,scale)
	scale=scale or 1
	local halfw, cx=scale*-w/2, mx + .5
	local cy,cs,ss=my-halfw/scale,cos(rot)/scale,sin(rot)/scale
	local sx, sy, hx, hy=cx+cs*halfw, cy+ss*halfw, w*(flip and -4 or 4)*scale, w*4*scale
	for py=y-hy, y+hy do
		tline(x-hx, py, x+hx, py, sx -ss*halfw, sy + cs*halfw, cs/8, ss/8)
		halfw+=.125
	end
end

--2d vector
v2_meta={
	__mul=function(a,b)
		if type(b) == "number" then
			return v2(a.x*b,a.y*b)
		end
		if type(a) == "number" then
			return v2(a*b.x,a*b.y)
		end
	end,
	__add=function(u,v)
		return v2(u.x+v.x,u.y+v.y)
	end,
	__sub=function(u,v)
		return v2(u.x-v.x,u.y-v.y)
	end,
	__index={
		len=function(v)
			return sqrt(v.x^2+v.y^2)
		end,
		unit=function(v)
			local fac=1/v:len()
			return fac*v
		end,
		unpack=function(v)
			return v.x,v.y
		end
	},
}
function v2(x,y)
	local v={x=x,y=y}
	setmetatable(v,v2_meta)
	return v
end

--3d vector
v3_meta={
	__mul=function(a,b)
		if type(b) == "number" then
			return v3(a.x*b,a.y*b,a.z*b)
		end
		if type(a) == "number" then
			return v3(a*b.x,a*b.y,a*b.z)
		end
	end,
	__add=function(u,v)
		return v3(u.x+v.x,u.y+v.y,u.z+v.z)
	end,
	__sub=function(u,v)
		return v3(u.x-v.x,u.y-v.y,u.z-v.z)
	end,
	__index={
		len=function(v)
			return sqrt(v.x^2+v.y^2+v.z^2)
		end,
		unit=function(v)
			local fac=1/v:len()
			return fac*v
		end,
		unpack=function(v)
			return v.x,v.y,v.z
		end
	},
}
function v3(x,y,z)
	local v={x=x,y=y,z=z}
	setmetatable(v,v3_meta)
	return v
end

-->8
--localized text

function strings_init()
 return {
  langs={
   {code="jp",name="にほんこ゛",},
   {code="en",name="english"},
  },
  lang=1,
  get=function(self,s)
   return self._data[s][self.langs[self.lang].code]
  end,
  getlangs=function(self)
   return self.langs
  end,
  setlang=function(self,l)
   self.lang=l
  end,
  _data={
   hud_move={
    jp="うこ゛く",
    en="move",
   },
   hud_dive={
    jp="タ゛イフ゛",
    en="dive",
   },
   hud_time={
    jp="し゛かん",
    en="time",
   },
   hud_score={
    jp="スコア",
    en="score",
   },
	  intro_1={
	   jp="おとん、せつふ゛んはな-に?",
	   en="dad, what's setsubun?",
	  },
	  intro_2={
	   jp="せつふ゛んはむかし、\n"..
	      "いちねんのいちは゛んはし゛まり\n"..
	      "のひた゛ったんた゛よ。",
	   en="a long time ago the first day\n"..
	      "of each new year was called\n"..
	      "setsubun.",
	  },
	  intro_3={
	   jp="むかしのひとはいちねんの\n"..
		     "はし゛まりに、「よいことか゛\n"..
		     "ありますように」と\faまめ\f7を\n"..
		     "まいておいのりしてたんた゛って。",
		  en="in order to bring good fortune\n"..
		     "in the new year, our ancestors\n"..
		     "would plant \fabeans.\f7",
    },
    intro_4={
     jp="むかしからせつふ゛んのひに\n"..
		      "「おうちにわるいものか゛はいって\n"..
		      "くる」といわれてる、\faまめ\f7を\n"..
		      "つかっておいはらってるんた゛よ。",
		   en="since then, it was said that\n"..
		      "on setsbun bad luck will come\n"..
		      "into our homes, so we use\n"..
		      "\fabeans\f7 to drive it away.",
		  },
		  intro_5={
		   jp="\faまめ\f7はわるいものをやっつけて\n"..
		      "くれるんた゛って。すこ゛いね。\n"..
		      "「まめ」はからた゛か゛け゛んきという\n"..
		      "いみもあるんた゛って。\n",
		   en="\fabeans\f7 can drive away bad luck.\n"..
		      "isn't that cool! cool! also,\n"..
		      "in our language the word `bean'\n"..
		      "sounds like the word `healthy'.",
		  },
		  
		  how_to_play_1={
		   jp="あそひ゛かた:",
		   en="how to play:",
		  },
		  how_to_play_2={
		   jp="あなたはオニ。\n"..
		      "オニはやっつけられるのか゛\nしこ゛とて゛す。\n"..
		      "こと゛もたちか゛せつふ゛んを\nたのしめるように、\n\faまめ\f7か゛あたるよう`にか゛んは゛れ!",
		   en="you are the oni.\n"..
		      "your job is to be defeated.\n\n"..
		      "in order for your kids to\n"..
		      "enjoy setsubun, do your best\n"..
		      "to get hit by the \fabeans\f7!",
		  },
		  
	 },
 }
end
__gfx__
0000000000000770000777000000000070777707777777770000000000000000ffffff94b3bf9ff9ff9ff9ffffffffffffffffffffffffff0007700000077000
0000000000007770007777000004400007000070777777770000000000000000fffff9423b3f9ff9ff9ff9ffffffffffffffffffffffffff7777777700077000
0070070000076670077766000042f40070700707777777770000000000000000ffff942fb3bf9ff9ff9ff9ffffffffffffffffffffffffff0007700077777777
00077000000766700776600004f2ff4070000007777777770000000000000000fff942ff3b3f9ff9ff9ff9ffffffffffffffffffffffffff0777777000077000
00077000000766777766600004ff2f4070000007777777770000000000000000ff942fffb3bf9ff9ff9ff9ffff99999999999999ffffffff0077770000777700
007007000000667777660000004ff40070700707777777770000000000000000f942ffff3b3f9ff9ff9ff9fff944444444444444999999990707707007700770
0000000000077777777770000004400007000070777777770000000000000000942fffffb3bf9ff9ff9ff9ff9422222222222222444444447007700777000077
000000000007771777177000000000007077770777777777000000000000000042ffffff3b3f9ff9ff9ff9ff42ffffffffffffff222222220007700000000000
0000000000677717771777000a0000a007700070000000000000000000000000ffffffff000000000000000000000000ffffff94000000007000000700077000
000000000006777777777600aaa99aaa00770770000000000000000000000000ffffffff000000000000000000000000fffff942000000007000070777777777
0000000000677777777777009999999900670760000000000000000000000000ffffffff000000000000000000000000ffff942f000000007070700700077000
000000000007777d7d7776000978978900076700000000000000000000000000ffffffff000000000000000000000000fff942ff000000007007700707777770
0000000000067777d77760008978879900777700000000000000000000000000ffffffff000000000000000000000000ff942fff000000007007070700000000
0000000000006777777600008888888807177170000000000000000000000000ffffffff000000000000000000000000f942ffff000000007070000777777777
00000000000776677667700008a22a80077d7770000000000000000000000000ffffffff000000000000000000000000942fffff000000007000000770000007
0000000000777776677777000088880006777760000000000000000000000000ffffffff00000000000000000000000042ffffff000000007777777777777777
00000000007777777777770000000000006776000000000000000000000000007711111111111111115555550000000077777777000770007707777700077000
0000000000767777777767000000000000eeee000000000000000000000000007149111111111111155555550000000070000007000770000000700000077000
000000000066677777776600000000000eeeee600000000000000000000000001449911111111111155555550000000070000007777777777700777077777777
0000000000067777777660000000000007eeee67000000000000000000000000148b911111111111155555550000000077777777007777000007777770077007
0000000000067777777760000000000000eeee67000000000000000000000000188ba11111111111115555550000000070000007070770707700000070077007
00000000000767777777700000000000007777600000000000000000000000001aaaa11111111111155555550000000070000007700770070007777777777777
000000000077776606777700000000000776677000000000000000000000000071aa111111111111155555550000000070000007077777707707000700077000
00000000006777000067760000000000076006600000000000000000000000007711111111111111115555550000000077777777000770007707777700077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007077070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077077077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070077007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777000
fffff444444fffffffffffffffffffffffff444444444444444444444444ffff0000000000000000000000000000000000000000000000000000000000000000
fff4477777744ffffffffffffffffffffff42222222222242222222222224fff0000000000000000000000000000000000000000000000000000000000000000
ff477707007774ffffffff8fffffffffff42cccccccccc244ccccccccccc24ff0000000000000000000000000000000000000000000000000000000000000000
f47777077077074ffffff8a8fffffffff42ccccccccccc244cc7777cccccc24f0000000000000000000000000000000000000000000000000000000000000000
f47777070070774ffffff38fffffffff42cccccccccccc244c7776ccc777cc240000000000000000000000000000000000000000000000000000000000000000
4777777777077774f8fff8ffffffffff4ccccccccccccc244cc66cccc6677cc40000000000000000000000000000000000000000000000000000000000000000
47777777707777748a8f8a8fffffffff4ccccccccccccc244ccccccccc667cc40000000000000000000000000000000000000000000000000000000000000000
4700000007770074f83fb8ffcffccfff444444444444444444444444444444440000000000000000000000000000000000000000000000000000000000000000
4700777007777074ffbff3ffcccffcff444444444444444444444444444444440000000000000000000000000000000000000000000000000000000000000000
4770777777770074ff5b5bfffcc11cff422222222222222442222222222222240000000000000000000000000000000000000000000000000000000000000000
4777777777777774f51b1b5fffccccff4ccccccccccccc244cccccccccccccc40000000000000000000000000000000000000000000000000000000000000000
2477777077777742f155551ff91cc19f4cccccccc77ccc244cccccccccccccc40000000000000000000000000000000000000000000000000000000000000000
f47777700777774fff1111fff444444f94ccccccc677cc244ccccccccccccc490000000000000000000000000000000000000000000000000000000000000000
f24777700777742f9955559992444429f94ccccccc667c244cccccccccccc49f0000000000000000000000000000000000000000000000000000000000000000
ff244777777442ff4455554442444424ff94cccccccccc244ccccccccccc49ff0000000000000000000000000000000000000000000000000000000000000000
fff2244444422fff2215512222222222fff94444444444444444444444449fff0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2999944999999999999999994999999999949994ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4244444444444444444444444444444444444442ffddffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4477777777777777777777777777777777777722ffddffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4477777777777777777777777777777777777722fffdffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4477777777777777777777777777777777777722fff6dfff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4477771111111111111111111111111117777722ff6ff6ff00000000000000000000000000000000000000000000000000000000000000000000000000000000
4477771111111111111111111111111117777722f6ffff6f00000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711111771111777444114441111177777226ffffff600000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711117771117777444414444111177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
447777111766711777664ff441444111177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4477771117667117766114ff41ff4411177777240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4477771117667777666111ff41ff4411177777240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
447777111166777766111144444ff411177777240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
447777111777777777711f44444444f1177777240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4477771117771777177114144414444f177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711677717771777f414441444f1177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711167777777776444444444441177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24777711677777777777f44d4d44444f177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2477771117777d7d77761444d44444f1177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24777711167777d777611f4444444ff1177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24777711116777777611114444444111177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2477771117766776677111ff444f44f1177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
447777117777766777771144fff4444f177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
447777117777777777771f4444444444177777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711767777777767f44444444444477777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711666777777766f44444444444477777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777711167777777661f44444444444477777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777777777777777777777777777777777777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777777777777777777777777777777777777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44777777777777777777777777777777777777220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000000001121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90a03100001222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111dddd11dddd111111dddddddddddd11dddddddddddddddddddddd111111111111111111111111111111111111111
1111111111111111111111111111111111111d77d11d77d111111d7777777777d11d777777dd77dd77dd7777d111111111111111111111111111111111111111
11111111111111111111111111111111111ddd77dddd77ddd1111d7777777777dddd777777dd77dd77dd7777ddd1111111111111111111111111111111111111
11111111111111111111111111111111111d777777777777d1111ddddddddddd77dd77dd77dd77dd77dd77dd77d1111111111111111111111111111111111111
11111111111111111111111111111111111d777777777777d11111111111111d77dd77dd77dd77dd77dd77dd77d1111111111111111111111111111111111111
11111111111111111111111111111111111ddd77dddd77ddd11111111111111d77dd7777dddd77dd77dd77dd77d1111111111111111111111111111111111111
1111111111111111111111111111111111111d77d11d77d11111111111111ddd77dd7777dddd77dd77dd77dd77d1111111111111111111111111111111111111
1111111111111111111111111111111111111d77d11dddd11111111111111d77dddd77dd77dd77dd77dd77dd77d1111111111111111111111111111111111111
1111111111111111111111111111111111111d77ddddddd1111111111ddddd77d11d77dd77dd77dd77dd77dd77d1111111111111111111111111111111111111
1111111111111111111111111111111111111ddd777777d1111111111d7777ddd11d777777dddd7777dd77dd77d1111111111111111111111111111111111111
111111111111111111111111111111111111111d777777d1111111111d7777d1111d777777d11d7777dd77dd77d1111111111111111111111111111111111111
111111111111111111111111111111111111111dddddddd1111111111dddddd1111dddddddd11dddddddddddddd1111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111777177717771177117711111177777111111777117711111177177717771777177711111111111111111111111111111
11111111111111111111111111111111717171717111711171111111771717711111171171711111711117117171717117111111111111111111111111111111
11111111111111111111111111111111777177117711777177711111777177711111171171711111777117117771771117111111111111111111111111111111
11111111111111111111111111111111711171717111117111711111771717711111171171711111117117117171717117111111111111111111111111111111
11111111111111111111111111111111711171717771771177111111177777111111171177111111771117117171717117111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018181818181818851818181818404118181818181818181818181818181844471818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018181818188081828384181818505118181818181818181818181818181854571818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018181818189091929394181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001818181818a0a1a2a3a4181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001818181818b0b1b2b3b4181818181818181818184445464718181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018181818181818181818181818181818184243185455565718181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018180d0d0d0d0d0d0d0d0d0d0d0d0d0d0d52530d0d0d0d0d0d0d0d0d0d0d0d0d0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011018001d0701d0601d0501d0501d0501d0501d0501d05518050180501d0501d0502407024050240502405024050240502405524000220702205021050210500000000000000000000000000000000000000000
01101800220702206022050220502205022050220502205521070210501d0501d0551d0501d0501d0501d0501d0501d0551f0701f0501f0501f0501f0501f0500000000000000000000000000000000000000000
011018001d0701d0501d0501d0501d0501d0501d0501d05518050180501d0501d0502407024050240502405024050240502405024055220702205024050240500000000000000000000000000000000000000000
011018002607026050260502605028070280502805028050290702905029050290502407024050240502405024050240502405024050240502405024050240550000000000000000000000000000000000000000
01101800200702005020050200502005020050200502005522070220502405024050220702205022050220501f0701f0501f0501f0501b0701b0501b0501b0500000000000000000000000000000000000000000
011018001d0701d0601d0501d0501d0501d0501d0501d0501d0501d0501d0501d0501d0401d0401d0401d0401d0301d0301d0301d0301d0201d0201d0101d0150000000000000000000000000000000000000000
011018002605026050260502605026050260502605026050280502805029050290502d0602d0502d0402d0402d0402d0402b0602b0502b0402b0402b0402b0400000000000000000000000000000000000000000
011018002406024050240402404024040240402404024040260602605028050280502b0602b0502b0502b0502b0502b0502906029050290502905029050290500000000000000000000000000000000000000000
011018002e0602e0502e0402e0402e0402e0402e0402e0402d0602d0502e0502e0502d0602d0502d0502d0502d0502d0502b0602b0502b0502b0502b0502b0500000000000000000000000000000000000000000
011018002907029060290502905029050290502905029050290502905029050290502904029040290402904029030290302903029030290202902029010290100000000000000000000000000000000000000000
911018001925519250192551925019255192551925019255192501925519250192552125521250212552125021255212552125021255212502125521250212550020000200002000020000200002000020000200
911018001d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2501d2550c2000c2000c2000c2000c200002000020000200
911018001925519250192551925019255192551925019255192501925519250192551825518250182551825018255182551825018255182501825518250182550020000200002000020000200002000020000200
911018001d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2501d2550c2000c2000c2000c2000c200002000020000200
911018001825518250182551825018255182551825018255182501825518250182551825518250182551825018255182551825018255182501825518250182550020000200002000020000200002000020000200
911018001d2551d2501d2551d2501d2551d2551d2501d2551d2501d2551d2501d2551c2551c2501c2551c2501c2551c2551c2501c2551c2501c2551c2501c2550c2000c2000c2000c2000c200002000020000200
491018001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2001f2000020000200002000020000200002000020000200
491018001d2001d2001d2001d2001d2001d2001d2001d2001d2001d2001d2001c2001c2001c2001c2001c2001c2001c2001c2001c2001c2001c2001c2001c2000c2000c2000c2000c2000c200002000020000200
490c00001500015000150001500015000150001500015000150001500015000150001500015000150001500009000090000900009000090000900009000090000900009000090000900009000090000900009000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490c000001070010700107506000080720807208075020000f0720f0720f0720f0750d0700d0720d0720d07500070000700007500005050700507005075000050c0720c0720c0720c07509072090720907209075
490c000001070010700107506000080720807208075020000f0720f0720f0720f0750d0700d0700d0750000000070000700007500005050700507005075000050c0720c0720c0720c0720c0720c0720c0720c075
490c00000a0700a0700a075090001107211072110750500016072160721607216075110721107211075030000807008070080750600011072110721107502000140721407214072140751107011070110750c000
490c0000070700707007075090000d0720d0720d07505000110721107211072110750d0720d0720d075030000707007070070750600007072070720707502000000720007200072000750007000070000750c000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
491000000504000000110401104015040150400000000000000000000000000000000904000000150401504018040180400000000000000000000000000000000000000000000000000000000000000000000000
001000000a0400000016040160401a0401a0400000000000000000000000000000000c04000000180401804000000000000004000000180401804000000000000000000000000000000000000000000000000000
0110000005040000001104011040150401504000000000000000000000000000000002040000000e0400e04011040110400000000000000000000000000000000000000000000000000000000000000000000000
001000000704000000130401304016040160450000000000000000000000000000000004000000130401304016040160450000000000100401004010040100450000000000000000000000000000000000000000
001000000104000000140401404018040180400000000000000000000000000000000304000000160401604018040180400000000000030400000000000000000000000000000000000000000000000000000000
00100000000400004016020160201802018020180201802018020180250a0400a0400704007040070400704007040070450004000040000400004000040000400000000000000000000000000000000000000000
001000000a0400000016040160401a0401a0450000000000000000000000000000000c04000000180400000000000000000004000000180400000000000000000000000000000000000000000000000000000000
001000000904000000150401504018040180400000000000000000000000000000000e040000001a04000000000000000002040000001a0400000000000000000000000000000000000000000000000000000000
001000000704000000130401304016040160400000000000000000000000000000000c0400c0400c0400000000000000000004000040000400000000000000000000000000000000000000000000000000000000
000f0000050400000011040110401504015040110401104009040090400c0400c0400504005040050400504005040050400504005040050400504005040050400000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000290562d0563005635056290562d0563005635056350303503035030350350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000024010240102401024015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000000000000000000000000000000000002d0102d0102d0102d015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000505005050050500505005050050500505529010290102901029010290150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01204344
00 02214344
00 03204344
00 04214344
00 01204344
00 02214344
00 05244344
00 06254344
00 01204344
00 02214344
00 03224344
00 04234344
00 07264344
00 08274344
00 09284344
02 0a294344
01 0b0c1844
00 0b0c1944
00 0d0e1a44
02 0f101b44
02 51525344
02 51525344
00 41424344
00 41424344
04 30313233


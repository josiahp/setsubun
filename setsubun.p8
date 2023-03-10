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
	game_dur=24.5 -- seconds
	strings=strings_init()

	map_init()

	-- scene switching
	scn=nil
	game_flow=flow.scene(credits_scn)
	.andthen(
		-- main game loop
		flow.forever(
			flow.scene(title_scn)
			.andthen(flow.scene(dialogue_scn))
			.andthen(flow.scene(explainer_scn))
			.andthen(flow.scene(game_scn))
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

function spawn_beans(beans)
	while beans do
		-- wait 5 frames
		for i=1,5 do
			yield()
		end
		--then spawn a new bean
		-- move the bean in the +x dir
		-- so that it doesn't collide
		-- with the "wall" at x=0
		local x=64+rnd(128)
		local y=128+28+rnd(64)
		local z=0
		local b=bean_new(
			v3(x,y,z),
			v3(0,0,0)
		)
		add(beans, b)
	end
end

function title_scn(nxt)
	local scn = {
		langs=strings:getlangs(),
		lang=1,
	}
	local beans={}
	local make_beans=cocreate(spawn_beans)

	function scn.init(s)
		music(0)
		strings:setlang(s.lang)
	end

	function scn.update(s,dt)
		if btnp(⬆️) then
			s.lang=max(s.lang-1,1)
			strings:setlang(s.lang)
		elseif btnp(⬇️) then
			s.lang=min(s.lang+1,#s.langs)
			strings:setlang(s.lang)
		end
		if btnp(❎) then
			coresume(make_beans, nil)
			nxt()
		end

		-- update beans
		if costatus(make_beans) then
			coresume(make_beans, beans)
		end
		for k,v in pairs(beans) do
			v:update(dt)
			if v.age >= v.ttl then
				del(beans,v)
			end
		end
	end

	function scn.draw(s)
		cls(1)

		--offset the camera
		-- to center the falling beans
		camera(64,-28)
		for k,v in pairs(beans) do
			v:draw()
		end
		camera()
		
		local title="\^w\^t".."せつbun"
		local x,y=36,48
		outline_text(title,x,y,7,13)
		color(7)
		print("setsubun",x+12,y+14,13)
		
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

function explainer_scn(nxt)
	local scn = {
		timer=0,
		dur=1,
		is_done=false,
	}

	function scn.update(s,dt)
		s.timer+=dt
		if s.timer<s.dur then return end
		s.is_done=true
		if btnp(❎) then
			nxt(nil)
		end
	end

	function scn.draw(s)
		cls(1)
		color(7)
		
		print(strings:get("how_to_play_1"), 40, 24)
		print(strings:get("how_to_play_2"), 4, 48)

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
	
	local beans = {}

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
		
		if s.t>=s.inputlock and btnp(❎) then
			nxt(nil)
			return
		end

		-- update beans
		for k,v in pairs(beans) do
			v:update(dt)
			if v.age >= v.ttl then
				del(beans,v)
			end
		end

		if s.done then return end

		--update kanji
		s.resulttimer+=dt
		if s.resulttimer>=s.resultspd then
			s.result=rnd(kanji)
			s.resulttimer%=s.resultspd
		end
		
		--update score
		s.scoretimer+=dt
		if s.scoretimer>=s.scorespd then
			s.scorecounter=min(score,s.scorecounter+1)
			s.scoretimer%=s.scorespd
			s:add_bean()
		end

		--settle the result
		if s.scorecounter==score then
			--fortune is random, but better scores
			-- should lead to better results
			-- every 5 beans improves your fortune by 1 rank
			-- 35 beans needed to guarantee best fortune
			local base = score/5
			local odds = flr(1 + base + rnd(#kanji - base))
			local idx = mid(1, odds, #kanji) --sanity check: make sure we're still in range
			s.result=kanji[idx]
			s.done=true
		end
	end

	function scn.draw(s)
		cls(1)

		-- draw beans
		camera(0,-28)
		for k,v in pairs(beans) do
			v:draw()
		end
		camera()

		-- draw results
		color(7)
		if s.result then
			-- draw kanji
		 local x=64-#s.result.params*8
		 local y=32
		 for k,v in ipairs(s.result.params) do
		  local sx,sy=unpack(v)
		  sspr(sx,sy,8,8,x,y,16,16)
		  x+=17
		 end
		 -- draw furigana or english translation
		 local key = "result_"..s.result.name
		 local name = strings:get(key)
		 local w = textwidth(name)
		 x,y=64-(w/2),20
		 print(name,x,y)
		end
		local scorex,scorey=58,58
		box(scorex-2,scorey-2,17,13,7)
		if s.scorecounter<10 then
			scorex+=7
		end
		print("\^w\^t"..s.scorecounter, scorex, scorey)
		if s.done then
		 print("press ❎ to restart",28,100)
		end
	end

	function scn.add_bean(s)
		-- then spawn a new bean
		local x=63-4+rnd(8)
		local y=128+28
		local z=0
		local b=bean_new(
			v3(x,y,z),
			v3(0,0,0)
		)
		add(beans, b)
	end

	return scn
end

-->8
--game scene

function game_scn(nxt)
	local scn={
		t=0,
		score=0,
		effects={},
		beans={},
		kids={},
	}

	add(scn.kids, kids_new(v3(32,0,14),8))
	add(scn.kids, kids_new(v3(96,0,14),12))
	
	local dad=dad_new(v3(63,0,14))
	local cam=cam_new()

	function scn.init()
		music(16)
	end

	function scn.update(s, dt)
	 -- stop the action
		if s.t<game_dur then
			dad:update(dt,scn)
			for k,v in pairs(s.kids) do
				v:update(dt,scn)
			end
		end
		
		cam:update(dt,dad.pos.x-64+8)

		local bbox=dad:bbox()
		for k,v in pairs(s.beans) do
			v:update(dt,scn)
			--collide with dad
			if not v.collided
				and v.pos.x>=bbox.x0
				and v.pos.x<=bbox.x1
				and v.pos.y>=bbox.y0
				and v.pos.y<=bbox.y1
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
		-- wait an extra second on "time's up!" message
		if s.t>game_dur+1 then
			nxt(s.score)
		end
	end
	
	function scn.draw(s)
		cls()
		cam:draw()
		map_draw()
		
		-- draw shadows first
		-- large shadows get dithered fill
		color(5)
		fillp(0b1000001010000010.1)
		dad:draw_shadow()
		for k,v in pairs(s.kids) do
			v:draw_shadow()
		end
		fillp()
		-- small shadows get solid fill
		for k,v in pairs(s.beans) do
			v:draw_shadow()
		end
		
		-- draw actors
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
		for k,v in pairs(s.kids) do
			v:draw_target()
		end
		
		local time_left=max(0, game_dur-scn.t)
		hud_draw(s,time_left)
		
		-- draw time warning
		local t_warn=ceil(time_left)
		local txt
		if t_warn<=3 and t_warn>0 then
			txt=""..t_warn
		elseif t_warn==0 then
			txt=strings:get("time_up")
		end
		if txt then
			local x=64-2*textwidth(txt)/2
			outline_text("\^w\^t"..txt,x,36,7,8)
		end
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
	function scn.add_effect(s,bark)
		add(s.effects,bark)
	end

	return scn
end


function dialogue_scn(nxt)
	local scn={}

	local dialogue_flow = 
	flow.scene(dialogue_box,
		{actor="kids", align="right"},
		strings:get("intro_1")
	)
	.andthen(
		flow.scene(dialogue_box,
		{actor="dad", align="left"},
		strings:get("intro_2")
	))
	.andthen(
		flow.scene(dialogue_box, 
		{actor="dad", align="left"},
		strings:get("intro_3")
	))
	.andthen(
		flow.scene(dialogue_box, 
		{actor="dad", align="left"},
		strings:get("intro_4")
	))
	.andthen(
		flow.scene(dialogue_box,
		{actor="dad", align="left"},
		strings:get("intro_5")
	))
		
	local dialogue=nil
	dialogue_flow.go(
		-- next dialogue box
		function(nxt)
			dialogue = nxt
		end,
		-- end scene
		nxt
	)

	function scn.update(s, dt)
		dialogue:update(dt)
	end
	
	function scn.draw(s)
		cls()
		-- draw dad
		local x,y,dy
		x,y=14,60
		dy=0
		if dialogue.header.actor == "dad" then
			dy-=8
		end
		sspr(48,64,32,32,x,y+dy)

		-- draw kids
		x,y=86,60
		dy=0
		if dialogue.header.actor == "kids" then
			dy-=8
		end
		sspr(80,64,32,32,x,y+dy)
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
		if d.direction==⬅️ then
			d.vel.x = -d.dive_spd
		elseif d.direction==➡️ then
			d.vel.x = d.dive_spd
		end
		d.emitter=cocreate(particle_trail)
		d.dive_timer=0
	end,
	start_cooldown=function(d)
		d.state="cooldown"
		d.cooldown_timer=0
	end,
	start_walking=function(d)
		d.state="walking"
	end,
	update=function(d,dt,scn)
		if d.state == "walking" then
			d:update_walking(dt,scn)
		elseif d.state == "diving" then
			d:update_diving(dt,scn)
		elseif d.state == "cooldown" then
			d:update_cooldown(dt,scn)
		end

		if d.emitter and costatus(d.emitter) then
			local nxt, p = coresume(d.emitter, d)
			if nxt and p then
				scn:add_effect(p)
			end
		end
	end,
	update_walking=function(d,dt,scn)
		if btn(⬅️) then
			d.vel.x=-d.spd
		elseif btn(➡️) then
			d.vel.x=d.spd
		else
			d.vel.x=0
		end
		d:move(dt*d.vel)
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
	update_diving=function(d,dt,scn)
		d:move(dt*d.vel)
		-- switch to cooldown
		d.dive_timer+=dt
		if d.dive_timer>=d.dive_dur then
			d:start_cooldown()
		end
	end,
	update_cooldown=function(d,dt,scn)
		d.vel *= d.dive_friction
		d:move(dt*d.vel)
		
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
	dive_fac=function(d)
		local fac=0
		if d.state=="diving" then
			fac=d.dive_timer/d.dive_dur
		elseif d.state=="cooldown" then
			fac=1
		end
		return fac
	end,
	bbox=function(d)
		local r = 0.25 * d:dive_fac()
		local w = 12 - 12*sin(r)
		local h = 12 + 12*cos(r)
		return {
			w=w,
			h=h,
			x0=d.pos.x-0.5*w,
			x1=d.pos.x+0.5*w,
			y0=d.pos.y,
			y1=d.pos.y+h,
		}
	end,
	draw=function(d)
		local fac=d:dive_fac()
		local dx,dy=0,-12
		dy+=fac*8
		
		local rot=0.25*fac
		local flip=d.direction==⬅️
		local x,y=project(d.pos)
		-- dad sprite
		pd_rotate(x,y+dy,rot,5.5,61,3,flip)
		-- dad's mask
		local sign=flip and -1 or 1
		local mask_x,mask_y=rotate(sign*rot,0,-2)
		pd_rotate(x+mask_x,y+dy+mask_y,rot,2,63,1,flip)
	
		if debug then
			local bbox = d:bbox()
			box(x-0.5*bbox.w, y-bbox.h, bbox.w, bbox.h, 8)
		end
	end,
	draw_shadow=function(d)
		local fac=d:dive_fac()
		local x,y=project(d.pos)
		local w=6+fac*6
		ovalfill(x-w,y-3,x+w,y+1)
	end
}
dad_meta={__index=dad_proto}

function particle_trail(dad)
	local tstart=time()
	local ttl=0.4
	while time()-tstart<ttl do
		local pos = dad.pos
		-- wait 2 extra frames
		yield()
		yield()
		-- then spawn a new particle
		local p=particle_new(pos)
		yield(p)
	end
end

function dad_new(pos)
	local dad={
		pos=pos,
		vel=v3(0,0,0),
		spd=50,
		dive_spd=150,
		dive_dur=0.2,
		dive_timer=0,
		dive_friction=0.7,
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
		scn:add_effect(bark)
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
	end,
	draw_target=function(k)
		if k.target then
			k.target:draw()
		end
	end,
	draw_shadow=function(k)
		local x,y=project(k.pos)
		ovalfill(x-3,y-2,x+3,y)
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
		if y1<=0 and b.vel.y<0 then
			b.collided=true
			b.vel.y*=-0.75 --lose some energy per bounce
			-- deflect bounce by a small random angle
			local angle = rnd(0.2)-0.1
			b.vel.x,b.vel.y=rotate(angle,b.vel.x,b.vel.y)
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
		if abs(b.vel.y)<1 and abs(b.pos.y+b.vel.y)<2 then
			b.pos.y=0
			b.vel.y=0
			b.vel.x=0
			b.grounded=true
		end
		
		b.pos=b.pos+b.vel
	end,
	draw=function(b)
		local x,y=project(b.pos)
		spr(3,x-4,y-4)
	end,
	draw_shadow=function(b)
	 local shadow_pos=v3(b.pos.x,0,b.pos.z)
		local x,y=project(shadow_pos)
		ovalfill(x-1,y+1,x+1,y+2)
	end
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
		maxx=156,
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
	print(strings:get("hud_time"),x,y,palette.fg)

	x+=32
	w,h=128-12-x,7
 
	local fac=time_left/game_dur
	palt(palette.transparent,true)
	spr(60,x,y-1)
	local fillwidth=w*fac
	if fillwidth > 1 then
		boxfill(x+5,y-1,fillwidth,h,palette.ehomaki)
	end
	spr(62,x+5+w*fac,y-1)
	palt(palette.transparent,false)

	-- score
	x=2
	y+=8
	print(strings:get("hud_score"),x,y,palette.fg)

	x+=32
	print(s.score,x,y,palette.fg)
	
	-- controls
	x,y=0,128-16
	w,h=128,16
	
	boxfill(x,y,w,h,palette.bg)
	x+=6
	y+=6
	print(
		strings:get("hud_move")..
		": ⬅️➡️    "..
		strings:get("hud_dive")..
		": ❎",x,y,palette.fg
	)
end

function box(x,y,w,h,col)
	rect(x,y,x+w,y+h,col)
end

function boxfill(x,y,w,h,col)
	rectfill(x,y,x+w,y+h,col)
end

function outline_text(text,x,y,c,o)
	for xx=-1,1,1 do
		for yy=-1,1,1 do
			print(text,x+xx,y+yy,o)
		end
	end
	print(text,x,y,c)
end


function textwidth(str)
	local symbols={}
	symbols[ord(" ")]  = 3
	symbols[ord("!")]  = 3
	symbols[ord("'")]  = 3
	symbols[ord("゛")]  = 4
	symbols[ord("よ")] = 5
	
	local function is_latin(code)
		local is_upper=code>=67 and code<=90
		local is_lower=code>=97 and code<=122
		return is_upper or is_lower
	end
	
	local function is_kana(code)
		return code>=154 and not symbols[code]
	end

	local len=0
	for i=1,#str do
		local c=ord(sub(str,i,i))
		if is_latin(c) then
			len+=4
		elseif is_kana(c) then
			len+=8
		else
			len+=symbols[c] or 5 -- assume default width
		end
	end
	return len
end

-- dialogue
textspeed=20 --characters per second

function dialogue_box(nxt, header, text)
	local dialogue = {
		t=0,
		dur=#text/textspeed,
		text="",
		header=header,
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
		-- draw the header
		local actor, align = header.actor, header.align
		local name=strings:get(actor)
		w=48
		h=8
		if align=="left" then
			x=1
		elseif align=="right" then
			x=126-w
		end
		y=84
		boxfill(x,y,w,h, palette.border)
		x+=max(2, 2+(w-textwidth(name))/2)
		y+=2
		print(name,x,y,palette.text)

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
			local code = self.langs[self.lang].code
			return self._data[s][code]
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
			time_up={
				jp="しゅうりょう",
				en="time's up!",
      },
			kids={
				jp="こと゛も",
				en="kids",
			},
			dad={
				jp="おとうさん",
				en="dad",
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
			
			result_daikichi={
				jp="た゛いきち",
				en="great fortune",
			},
			result_kichi={
				jp="きち",
				en="good fortune",
			},
			result_chuukichi={
				jp="ちゅうきち",
				en="fortune",
			},
			result_shoukichi={
				jp="しょうきち",
				en="small fortune",
			},
			result_mikichi={
				jp="みきち",
				en="future fortune",
			},
			result_kyou={
				jp="きょう",
				en="misfortune",
			},
			result_daikyou={
				jp="た゛いきょう",
				en="great misfortune",
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
0000000000000770000777000000000070777707b3bf9ff9ff9ff9ffffffffffffffffff2244cccccccccccc0000000000000000000000000007700000077000
00000000000077700077770000044000070000703b3f9ff9ff9ff9ffffffffffffddffff2244cccccccccccc0000000000000000000000007777777700077000
0070070000076670077766000042f40070700707b3bf9ff9ff9ff9ffffffffffffddffff2244cccccccccccc0000000000000000000000000007700077777777
00077000000766700776600004f2ff40700000073b3f9ff9ff9ff9fffffffffffffdffff2244cccccccccccc0000000000000000000000000777777000077000
00077000000766777766600004ff2f4070000007b3bf9ff9ff9ff9fffffffffffff6dfff2244cccccccccccc0000000000000000000000000077770000777700
007007000000667777660000004ff400707007073b3f9ff9ff9ff9ff99999999ff6ff6ff2244cccccccccccc0000000000000000000000000707707007700770
0000000000077777777770000004400007000070b3bf9ff9ff9ff9ff44444444f6ffff6f2244cccccccccccc0000000000000000000000007007700777000077
00000000000777177717700000000000707777073b3f9ff9ff9ff9ff222222226ffffff62244cccccccccccc0000000000000000000000000007700000000000
0000000000677717771777000a0000a007700070cccc4442ffffffffffffffff94442d422244cccc333333330000000000000000000000007000000700077000
000000000006777777777600aaa99aaa00770770cccc4442fffffffffffffff94442dd422244cccc333333330000000000000000000000007000070777777777
0000000000677777777777009999999900670760cccc4442ffffffffffffff944422dd4222446663333333330000000000000000000000007070700700077000
000000000007777d7d7776000978978900076700cccc4442fffffffffffff94442427d4222446653333333330000000000000000000000007007700707777770
0000000000067777d77760008978879900777700cccc4442ffffffffffff94442d427d4222446513333333330000000000000000000000007007070700000000
0000000000006777777600008888888807177170cccc4442fffffffffff94442dd427d4222465133333333330000000000000000000000007070000777777777
00000000000776677667700008a22a80077d7770cccc4442ffffffffff944422dd42444266651333333333330000000000000000000000007000000770000007
0000000000777776677777000088880006777760cccc4442fffffffff94442427d42424266513333333333330000000000000000000000007777777777777777
0000000000777777777777000000000000677600333344429999999994442d427d42222665133333000000000000000077777777000770007707777700077000
0000000000767777777767000000000000eeee0033334442444444444442dd427d42266651333333000000000000000070000007000770000000700000077000
000000000066677777776600000000000eeeee6033334442444444444424dd424442666513333333000000000000000070000007777777777700777077777777
0000000000067777777660000000000007eeee67333344422222222222247d424242665133333333000000000000000077777777007777000007777770077007
0000000000067777777760000000000000eeee6733334442442ddddd44247d422226651333333333000000000000000070000007070770707700000070077007
000000000007677777777000000000000077776033334442442777dd44247d422666513333333333000000000000000070000007700770070007777777777777
000000000077776606777700000000000776677033334442442777dd442444426665133333333333000000000000000070000007077777707707000700077000
000000000067770000677600000000000760066033334442442777dd442442426651333333333333000000000000000077777777000770007707777700077000
000000000000000000000000000000000000000033334442442777dd442422666513333300000000000000000000000077111111111111111155555500077000
00000000000000000000000000000000000000003333444244444444442426665133333300000000000000000000000071491111111111111555555500077000
00000000000000000000000000000000000000003336444244444444442466651333333300000000000000000000000014499111111111111555555507077070
000000000000000000000000000000000000000033664442442222224424665133333333000000000000000000000000148b9111111111111555555577077077
000000000000000000000000000000000000000036664442442666664426651333333333000000000000000000000000188ba111111111111155555570077007
0000000000000000000000000000000000000000666666666666666666665133333333330000000000000000000000001aaaa111111111111555555500077000
00000000000000000000000000000000000000005555555555555555555513333333333300000000000000000000000071aa1111111111111555555500777000
00000000000000000000000000000000000000001111111111111111111133333333333300000000000000000000000077111111111111111155555500777000
fffff444444fffffffffffffffffffff299994499999999999999999499999999994999400000000000000000000000000000000000000000000000000000000
fff4477777744fffffffffffffffffff424444444444444444444444444444444444444200000000000000000000000000000000000000000000000000000000
ff477707007774ffffffff8fffffffff447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
f47777077077074ffffff8a8ffffffff447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
f47777070070774ffffff38fffffffff447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
4777777777077774f8fff8ffffffffff447777111111111111111111111111111177772200000000000000000000000000000000000000000000000000000000
47777777707777748a8f8a8fffffffff447777111111111111111111111111111177772200000000000000000000000000000000000000000000000000000000
4700000007770074f83fb8ffcffccfff447777111117711117774441144411111177772200000000000000000000000000000000000000000000000000000000
4700777007777074ffbff3ffcccffcff447777111177711177774444144441111177772200000000000000000000000000000000000000000000000000000000
4770777777770074ff5b5bfffcc11cff447777111766711777664ff4414441111177772200000000000000000000000000000000000000000000000000000000
4777777777777774f51b1b5fffccccff4477771117667117766114ff41ff44111177772400000000000000000000000000000000000000000000000000000000
2477777077777742f155551ff91cc19f4477771117667777666111ff41ff44111177772400000000000000000000000000000000000000000000000000000000
f47777700777774fff1111fff444444f447777111166777766111144444ff4111177772400000000000000000000000000000000000000000000000000000000
f24777700777742f9955559992444429447777111777777777711f44444444f11177772400000000000000000000000000000000000000000000000000000000
ff244777777442ff44555544424444244477771117771777177114144414444f1177772200000000000000000000000000000000000000000000000000000000
fff2244444422fff221551222222222244777711677717771777f414441444f11177772200000000000000000000000000000000000000000000000000000000
ffff444444444444444444444444ffff447777111677777777764444444444411177772200000000000000000000000000000000000000000000000000000000
fff42222222222242222222222224fff24777711677777777777f44d4d44444f1177772200000000000000000000000000000000000000000000000000000000
ff42cccccccccc244ccccccccccc24ff2477771117777d7d77761444d44444f11177772200000000000000000000000000000000000000000000000000000000
f42ccccccccccc244cc7777cccccc24f24777711167777d777611f4444444ff11177772200000000000000000000000000000000000000000000000000000000
42cccccccccccc244c7776ccc777cc24247777111167777776111144444441111177772200000000000000000000000000000000000000000000000000000000
4ccccccccccccc244cc66cccc6677cc42477771117766776677111ff444f44f11177772200000000000000000000000000000000000000000000000000000000
4ccccccccccccc244ccccccccc667cc4447777117777766777771144fff4444f1177772200000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444447777117777777777771f44444444441177772200000000000000000000000000000000000000000000000000000000
4444444444444444444444444444444444777711767777777767f444444444444177772200000000000000000000000000000000000000000000000000000000
4222222222222224422222222222222444777711666777777766f444444444444177772200000000000000000000000000000000000000000000000000000000
4ccccccccccccc244cccccccccccccc444777711167777777661f444444444444177772200000000000000000000000000000000000000000000000000000000
4cccccccc77ccc244cccccccccccccc4447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
94ccccccc677cc244ccccccccccccc49447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
f94ccccccc667c244cccccccccccc49f447777777777777777777777777777777777772200000000000000000000000000000000000000000000000000000000
ff94cccccccccc244ccccccccccc49ff492222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000
fff94444444444444444444444449fff922222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000777770000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007777777000000077770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077777777000077777770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077766770000777777770000000066600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000777666700007777766760000000677760006606660000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007776667700077777666700000000677760007766776000666000000000000000000000
00000000000000000000000000000000000000000000000000000000007776667000677776667600000000067770067776776006777600000000000000000000
00000000000000000000000000000000000000000000000000000000067766667000777766677000000000067776067776776006777600000000000000000000
00000000000000000000000000000000000000000000000000000000077766677006777666670000000000007776067776760067777600000000000000000000
00000000000000000000000000000000000000000000000000000000677666670007777666770000000000006777607777600067776000000000000000000000
00000000000000000000000000000000000000000000000000000000777666770007776667700000000000000777606777600077770000000000000000000000
00000000000000000000000000000000000000000000000000000006777666700067776667700000000000000677606677600677760000000000000000000000
00000000000000000000000000000000000000000000000000000006776666767767766677000000000000000677767677700677700000000000000000000000
00000000000000000000000000000000000000000000000000000000776667777777766776000000000000006777777767700777600000000000000000000000
00000000000000000000000000000000000000000000000000000007777777777777777760000000000000077777777767766777600000000000000000000000
00000000000000000000000000000000000000000000000000000667777777777777777600000000000000677777777767777776000000000000000000000000
00000000000000000000000000000000000000000000000000067777777777777777776000000000000000771777177677777777000000000000000000000000
00000000000000000000000000000000000000000000000000006777777777777777777600000000000006771777177677777777600000000000000000000000
00000000000000000000000000000000000000000000000000006777777717777777177000000000000007777777776777777777700000000000000000000000
00000000000000000000000000000000000000000000000000067777777711777777117600000000000006777777767717771777700000000000000000000000
00000000000000000000000000000000000000000000000000066777777711777777117600000000000007775757767717771777770000000000000000000000
00000000000000000000000000000000000000000000000000677777777777777777777760000000000000677577677777777777760000000000000000000000
00000000000000000000000000000000000000000000000000077777777777777777777776000000000000067777767777777777760000000000000000000000
00000000000000000000000000000000000000000000000000667777777777777777777766000000000000006777667775757777770000000000000000000000
00000000000000000000000000000000000000000000000000006777777777757775777770000000000000000666616777577777600000000000000000000000
0000000000000000000000000000000000000000000000000000077777777777555777776000000000000000011111c677777776200000000000000000000000
000000000000000000000000000000000000000000000000000006677777777775777777600000000000000001cccccc67777762820000000000000000000000
000000000000000000000000000000000000000000000000000000667777777777777776000000000000000001ccccccc6666228882000000000000000000000
00000000000000000000000000000000000000000000000000000676677777777777766000000000000000001cccccccc2822288882000000000000000000000
00000000000000000000000000000000000000000000000000066777666777777776600000000000000000001cccccccc2888888888200000000000000000000
00000000000000000000000000000000000000000000000000677777776666666666000000000000000000001cccccccc2888888888200000000000000000000
00000000000000000000000000000000000000000000000000677777777666666666600000000000000000001cccccccc2888888888820000000000000000000
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
70000000001121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50603100001222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616161616161616161616161616161616161616161616161616161616161616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616161616081616161616404116161616161616161616161616161660631616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616164445464748161616505116161616161616161616161616161670731616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616165455565758161616161616161616161616161616161616161616161616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616166465666768161616161616161616161616161616161616161616161616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616167475767778161616161616161616166061626316161616161616161616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516161616161616161616161616161616164243167071727316161616161616161616090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2516160707070707070707070707070707075253070707070707070707070707070707090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2516161616161616161616161616161616161616161616161616161616161616161617090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2516161616161616161616161616161616161616161616161616161616161616161718190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526262626262626262626262626262626262626262626262626262626262626262728290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35363636363636363636363636363636363636363636363636363636363636363637381a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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


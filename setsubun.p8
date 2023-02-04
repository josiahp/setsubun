pico-8 cartridge // http://www.pico-8.com
version 40
__lua__

function _init()
 t=time()
 dt=0
 
 -- constants
 gravity=9.81*2
 drag=0.1

 scn=nil
 game_time=10 -- seconds
 
 game_flow = flow.scene(credits_scn)
  .andthen(
   -- main game loop
   flow.forever(
    flow
     .scene(title_scn)
     .andthen(flow.scene(game_scn))
     .flatmap(function(score)
       return flow.scene(results_scn, score)
      end)
    )
  )

 game_flow.go(
  -- transition to next scene
  function(nxt)
   scn = nxt
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

-- scenes

function credits_scn(nxt)
 local scn = {
  t=0
 }

 function scn.update(s,dt)
  s.t += dt
  if s.t > 2 then
   nxt(nil)
  end
  if btnp(❎) then
   nxt(nil)
  end
 end
 
 function scn.draw()
  cls(1)
  print("josiah & matt present...", 20,60)
 end

 return scn
end

function title_scn(nxt)
 local scn = {}
  
 function scn.update(s,dt)
  if btnp(❎) then
   nxt(nil)
  end
 end
 
 function scn.draw(s)
  cls(1)
  print("setsubun", 32, 48)
  print("press ❎ to start", 32, 60)
 end
 
 return scn
end

function results_scn(nxt, score)
 local scn = {}
 function scn.update(s,dt)
  if btnp(❎) then
   nxt(nil)
  end
 end

 function scn.draw()
  cls(1)
  print("your score: "..score, 28, 48)
  print("press ❎ to restart")
 end

 return scn
end

-->8
function game_scn(nxt)
 local scn={
  t=0,
  score=0,
 }
 
 --dad is 24 pixels tall, so
 -- 1.5m == 24px
 -- 9.8m == 156px?
 dad=init_dad(63,63)
 
 cam_init()
 target_init()
 kids_init()
 add(kids.group,kids_new(32,32))
 beans_init()
  
 beangroups={}
 --bg=beans_new(63,63,5)
 --tar=target_new(63,63)
 
 function scn.update(s, dt)
  cam_update(dt)
  --target demo
  -- tar:update(dt)
  -- if btn(⬆️) then
  --  tar.basey-=2
  -- elseif btn(⬇️) then
  --  tar.basey+=2
  -- end
  -- 
  -- if btn(⬅️) then
  --  tar.basex-=2
  -- elseif btn(➡️) then
  --  tar.basex+=2
  -- end

  -- debug throw beans
  -- if debug then
  --	 if btnp(❎) then
  --	  local vx,vy=vtoward(tar.x,tar.y,40,80)
  --	  bg=beans_new(40,80,5,vx,vy)
  --	 end
  --	end
    
  dad:update(dt)
  kids_update(dt)
  --beans:update(dt)
    
  for k,v in pairs(beangroups) do
   v:update(dt)
  end
 
  s.t += dt
  if s.t > game_time then
   nxt(s.score)
  end
 end
 
 function scn.draw()
  cls()
  cam_draw()
  -- target demo
  -- tar:draw()
  -- if debug then
  --  circ(40,80,3,8)
  --  print("throw from here",10,85,6)
  -- end
  map(0,0,0,0,32,32)
  dad:draw()
    
  kids_draw()
  for k,v in pairs(beangroups) do
   v:draw()
  end
    
  if debug then
   print(cam.x,cam.x+4,cam.y+4,8)
   print(dad.x,cam.x+4,cam.y+10,8)
   print(abs(dad.x-(cam.x+cam.followx)),cam.x+4,cam.y+16,8)
  end
 end
 
 return scn
end

-->8
function init_dad(x,y)
 local dad={
  x=63,
  y=63,
  spd=50,
  update=function(d,dt)
   local vx,vy=0,0
   if btn(⬅️) then
    vx-=d.spd
   elseif btn(➡️) then
    vx+=d.spd
   end
   d.x+=vx*dt
   d.y+=vy*dt
  end,
  draw=function(d)
   spr(1,d.x,d.y,2,3,false,false)
  end,
 }
 return dad
end

-->8
-- utils

function easein(i)
 return i*i*i--1-cos((i*3.14)/2)
end

function vtoward(x1,y1,x2,y2)
 local vx,vy=x1-x2,y1-y2
 local len=sqrt(vx^2+vy^2)
 vx/=len
 vy/=len
 return vx,vy
end


function once(f)
 local is_done = false
 return function(val)
  if not is_done then
   is_done = true
   f(val)
  end
 end
end

-->8
-- flow

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
--beans
function beans_init()
 beans_proto={
  update=function(b,dt)
   for k,v in pairs(b.group) do
    if not v.grounded then
	    --gravity
	    v.vy+=gravity*dt
	   end
   
    if v.y+v.vy*dt>=127 then
     v.vy*=-1
    end
    
    --add drag to reduce
    -- velocity over time
    v.vx*=1-drag
    v.vy*=1-drag
    
    --if the bean is close to
    -- to the ground and low
    -- velocity, lets stop
    -- the physics
    if abs(v.vy)<1 and abs(127-v.y+v.vy)<5 then
     v.y=127
     v.vy=0
     v.grounded=true
    end

    v.y+=v.vy
    v.x+=v.vx
   end   
  end,
  draw=function(b)
   for k,v in pairs(b.group) do
    spr(3,v.x-4,v.y-4)
   end
  end,
 }
 beans_meta={__index=beans_proto}
end

function beans_new(x,y,n,vx,vy)
 local beans={
  group={},
 }
 for n=1,n do
  add(beans.group,{
   x=x+rnd(10)-5,
   y=y+rnd(10)-5,
   
   -- initial bean velocity
   vx=vx*8,
   vy=vy*8,
   
   grounded=false,
  })
 end
 setmetatable(beans,beans_meta)
 return beans
end

-->8
--targeting
function target_init()
 target_proto={
  update=function(t,dt)
   t.txo=cos(time())*20
   t.tyo=sin(time())*5
   
   t.x=t.basex+t.txo
   t.y=t.basey+t.tyo
  end,
  draw=function(t)
   spr(4,t.x-4,t.y-4)
  end,
 }
 target_meta={__index=target_proto}
end

function target_new(x,y)
 local t={
  --these are calculcated from
  --base+offset (basex+txo)
  x=x,
  y=y,
  
  basex=x,
  basey=y,
  txo=0,
  tyo=0
 }
 setmetatable(t,target_meta)
 return t
end

-->8
--camera

function cam_init()
 cam={
	 x=32,
	 y=0,
	 minx=0,
	 maxx=128,
	 followdist=32,
	 followx=63,
	 followy=63,
	}
end

function cam_update(dt)
 if dad then
  cam.x=mid(0,dad.x-63,128)
 end
end

function cam_draw()
 camera(cam.x,cam.y)
end

-->8
--kids

function kids_init()
 kids={
  group={},
 }
 kids_proto={
  update=function(k,dt)
   k.targettime=max(0,k.targettime-dt)

   if k.target and k.targettime==0 then
    local vx,vy=vtoward(k.target.x,k.target.y,k.x,k.y)
 	  bg=beans_new(k.x,k.y,5,vx,vy)
    add(beangroups,bg)
    k.target=nil
   end

   if not k.target then
    k.target=target_new(dad.x,dad.y)
    k.targettime=2
   else
    k.target:update(dt)
   end
  end,
  draw=function(k)
   sspr(8,0,16,24,k.x,k.y,8,16)
   if k.target then
    k.target:draw()
   end
  end,
 }
 kids_meta={__index=kids_proto}
end

function kids_new(x,y)
 local k={x=x,y=y,targettime=0}
 setmetatable(k,kids_meta)
 return k
end

function kids_update(dt)
 for k,v in pairs(kids.group) do
  v:update(dt)
 end 
end

function kids_draw(dt)
 for k,v in pairs(kids.group) do
  v:draw(dt)
 end 
end
__gfx__
00000000000077000077000000000000707777077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077000077000000000000070000707777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000007ee7007ee70000004f000707007077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000007ee7007ee700000f4ff00700000077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000007ee7777ee700000ff4f00700000077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000007ee7777ee7000000ff000707007077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777777777770000000000070000707777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000707777077777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000677777777600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000767777776700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007776666667770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777700777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505050505050505050505050505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000000000

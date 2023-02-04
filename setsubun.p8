pico-8 cartridge // http://www.pico-8.com
version 40
__lua__

function _init()
 t=time()
 dt=0
 debug=true
 
 -- constants
 gravity=9.81*2
 drag=0.1

 scn=nil
 game_time=100 -- seconds
 
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
  color(7)
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
  color(7)
  print("せつbun", 49, 48)
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
  color(7)
  print("your score: "..score, 28, 48)
  print("press ❎ to restart")
 end

 return scn
end

-->8
--game scene

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
 map_init()
 target_init()
 kids_init()
 add(kids.group,kids_new(32,100))
 beans_init()
  
 beangroups={}
 --bg=beans_new(63,63,5)
 --tar=target_new(63,63)
 
 function scn.update(s, dt)
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
  cam_update(dt)

  kids_update(dt)
  --beans:update(dt)
    
  for k,v in pairs(beangroups) do
   v:update(dt,scn)
  end
 
  s.t += dt
  if s.t > game_time then
   nxt(s.score)
  end
 end
 
 function scn.draw(s)
  cls()
  cam_draw()
  map_draw()
-- target demo
-- tar:draw()
-- if debug then
--  circ(40,80,3,8)
--  print("throw from here",10,85,6)
-- end

  dad:draw()
 
  kids_draw()
  for k,v in pairs(beangroups) do
   v:draw()
  end
  
  --cls()
  

  
  if debug then
   print(cam.x,cam.x+4,cam.y+4,8)
   print(dad.x,cam.x+4,cam.y+10,8)
   print(abs(dad.x-(cam.x+cam.followx)),cam.x+4,cam.y+16,8)
  end
 

  local remaining_time=game_time-scn.t
  hud_draw(remaining_time,s.score)
  

  
  --tline(8,120,16,112,0,63)
 end
 
 return scn
end

-->8
--dad

function init_dad(x,y)
 local dad={
  x=63,
  y=104,
  spd=50,
  update=function(d,dt)
   local vx,vy=0,0
   if btn(⬅️) then
    vx-=d.spd
   elseif btn(➡️) then
    vx+=d.spd
   end
   d.x=mid(mapinfo.char_minx,d.x+vx*dt,256)
   d.y+=vy*dt
  end,
  draw=function(d)
   spr(1,d.x-8,d.y-12,2,3,false,false)
   --dad's mask
   spr(19,d.x-4,d.y-6)
  end,
 }
 return dad
end

-->8
--math

function easein(i)
 return i*i*i--1-cos((i*3.14)/2)
end

function dist(x1,y1,x2,y2)
 return sqrt((x2-x1)^2+(y2-y1)^2)
end

function vtoward(x1,y1,x2,y2)
 local vx,vy=x1-x2,y1-y2
 local len=sqrt(vx^2+vy^2)
 vx/=len
 vy/=len
 return vx,vy
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
--beans
function beans_init()
 beans_proto={
  update=function(b,dt,scn)
   for k,v in pairs(b.group) do
    if time()-v.createdat>10 then
     del(b.group,v)
    end
    
    local maxy=mapinfo.char_maxy
    local minx=mapinfo.char_minx
    local maxx=mapinfo.char_maxx

    if not v.grounded then
	    --gravity
	    v.vy+=gravity*dt
	   end
   
    --collide with floor
    if v.y+v.vy*dt>=maxy then
     v.collided=true
     v.vy*=-1
    end
    --collide with wall
    if v.x+v.vx*dt<=minx or v.x+v.vx*dt>=maxx then
     v.collided=true
     v.vx*=-1
    end
    
    --collide with dad
    if not v.collided
     and v.x+v.vx*dt>=dad.x-8
     and v.x+v.vx*dt<=dad.x+8
     and v.y+v.vy*dt>=dad.y-12
     and v.y+v.vy*dt<=dad.y+12
     then
     v.vx*=-1
     scn.score+=1
     v.collided=true
    end
    
    --add drag to reduce
    -- velocity over time
    v.vx*=1-drag
    v.vy*=1-drag
    
    --if the bean is close to
    -- to the ground and low
    -- velocity, lets stop
    -- the physics
    if abs(v.vy)<1 and abs(maxy-v.y+v.vy)<5 then
     v.y=maxy
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
   y=y-rnd(10),
   
   -- initial bean velocity
   vx=vx*8,
   vy=vy*8-rnd(10)-5,
   
   grounded=false,
   createdat=time()+rnd(3),
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
--camera and map

function map_init()
 mapinfo={
  minx=0,
  maxx=48,
  miny=0,
  maxy=16,
  
  char_minx=20,
  char_maxx=256,
  char_miny=104,
  char_maxy=108,
 }
end

function map_draw()
 map(mapinfo.minx,mapinfo.miny,0,0,mapinfo.maxx,mapinfo.maxy)
  --draw wall
  local y=118
  for w=8,23 do
   tline(w,y,w,y-8,0,63-1/8,0,-1/8)
   y-=1
  end
  
  --draw tatami
  for tatami=3,33,2 do 
	  local x=tatami*8-1
	  for y=104,119 do
	   tline(x,y,x+15,y,0,63)
	   x-=1
	  end
	 end
	 
	 if debug then
	  line(mapinfo.char_minx,mapinfo.char_miny,mapinfo.char_maxx,mapinfo.char_miny,8)
	  line(mapinfo.char_minx,mapinfo.char_miny,mapinfo.char_minx,mapinfo.char_maxy,8)

	 end
end

function cam_init()
 cam={
	 x=32,
	 y=0,
	 minx=0,
	 maxx=256,
	 followdist=32,
	 followx=63,
	 followy=63,
	}
end

function cam_update(dt)
 if dad then
  cam.x=mid(0,dad.x-63,cam.maxx)
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
   
   if not k.nextx or dist(k.x,k.y,k.nextx,k.nexty)<=8 then
    k.nextx=rnd(mapinfo.char_maxx-mapinfo.char_minx)+mapinfo.char_minx
    k.nexty=rnd(mapinfo.char_maxy-mapinfo.char_miny)+mapinfo.char_miny
   else
    local vx,vy=vtoward(k.nextx,k.nexty,k.x,k.y)
    k.x+=vx*dt*k.spd
    k.y+=vy*dt*k.spd
   end
  end,
  draw=function(k)
   sspr(8,0,16,24,k.x-4,k.y-8,8,16)
   if k.target then
    k.target:draw()
   end
  end,
 }
 kids_meta={__index=kids_proto}
end

function kids_new(x,y)
 local k={
  x=x,
  y=y,
  targettime=0,
  spd=20,
 }
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
-->8
-- hud
palette={
 bg=5,
 bg_alt=1,
 fg=7,
 border=7,
 accent=8,
 
 ehomaki=1,
 transparent=7,
}

function hud_draw(remaining_time,score)
 camera()
 local x,y=0,0
 
 -- background for us to draw on top of
 boxfill(x,y, 128, 16, palette.bg)
 
 x=2
 y=2
 
 -- time remaining
 print("time",x,y,palette.fg)
 
 x+=24
 
 local w,h=128-12-x,7
 local fac=remaining_time/game_time
 palt(palette.transparent,true)
 spr(40,x,y-1)
 boxfill(x+8,y-1,-8+w*fac,h,palette.ehomaki)
 spr(42,x+w*fac,y-1)
 palt(palette.transparent,false)

 -- score
 x=2
 y+=8
 print("score",x,y,palette.fg)
 
 x+=24
 print(score,x,y,palette.fg)
end

function box(x,y,w,h,col)
 rect(x,y,x+w,y+h,col)
end

function boxfill(x,y,w,h,col)
 rectfill(x,y,x+w,y+h,col)
end
__gfx__
0000000000007700007700000000000070777707777777770000000000000000ffffff94b3bf9ff9ff9ff9ffffffffffffffffffffffffff0000000000000000
0000000000007700007700000004400007000070777777770000000000000000fffff9423b3f9ff9ff9ff9ffffffffffffffffffffffffff0000000000000000
0070070000076670076670000042f40070700707777777770000000000000000ffff942fb3bf9ff9ff9ff9ffffffffffffffffffffffffff0000000000000000
00077000000766700766700004f2ff4070000007777777770000000000000000fff942ff3b3f9ff9ff9ff9ffffffffffffffffffffffffff0000000000000000
00077000000766777766700004ff2f4070000007777777770000000000000000ff942fffb3bf9ff9ff9ff9ffff99999999999999ffffffff0000000000000000
007007000007667777667000004ff40070700707777777770000000000000000f942ffff3b3f9ff9ff9ff9fff944444444444444999999990000000000000000
0000000000077777777770000004400007000070777777770000000000000000942fffffb3bf9ff9ff9ff9ff9422222222222222444444440000000000000000
000000000077766776677700000000007077770777777777000000000000000042ffffff3b3f9ff9ff9ff9ff42ffffffffffffff222222220000000000000000
0000000000776777777677000a0000a000000000000000000000000000000000ffffffff000000000000000000000000ffffff94000000000000000000000000
00000000007767c77c767700aaa99aaa00700700000000000000000000000000ffffffff000000000000000000000000fffff942000000000000000000000000
0000000000776707707677009999999900600600000000000000000000000000ffffffff000000000000000000000000ffff942f000000000000000000000000
0000000000077777777770000978978900600600000000000000000000000000ffffffff000000000000000000000000fff942ff000000000000000000000000
0000000000067777777760008978879900777700000000000000000000000000ffffffff000000000000000000000000ff942fff000000000000000000000000
0000000000076777777670008888888807c77c70000000000000000000000000ffffffff000000000000000000000000f942ffff000000000000000000000000
00000000007776666667770008a22a8007077070000000000000000000000000ffffffff000000000000000000000000942fffff000000000000000000000000
0000000000777777777777000088880000777700000000000000000000000000ffffffff00000000000000000000000042ffffff000000000000000000000000
00000000077677777777677000000000076776700000000000000000000000007711111111111111111111770000000000000000000000000000000000000000
00000000077677777777677000000000076776700000000000000000000000007149111111111111111117770000000000000000000000000000000000000000
00000000000677777777600000000000076776700000000000000000000000001449911111111111111117770000000000000000000000000000000000000000
0000000000076777777670000000000000777700000000000000000000000000148b911111111111111117770000000000000000000000000000000000000000
0000000000007660066700000000000000777700000000000000000000000000188ba11111111111111111770000000000000000000000000000000000000000
00000000000077700777000000000000007007000000000000000000000000001aaaa11111111111111117770000000000000000000000000000000000000000
000000000007777007777000000000000070070000000000000000000000000071aa111111111111111117770000000000000000000000000000000000000000
00000000000777000077700000000000077007700000000000000000000000007711111111111111111111770000000000000000000000000000000000000000
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
d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518180d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0518000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050500000000000000000000000000

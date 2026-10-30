-- Run from the repository: lua ForeverSprint/Tests/test_engine.lua ForeverSprint/
-- Actual addon engine and source data, mocked quest/map state; no game client required.
local F={}
local root=(arg and arg[1]) or "outputs/ForeverSprint/"
local passed=0
local function check(v,msg) assert(v,msg); passed=passed+1 end
local state={log={},ready={},turned={},items={},level=1}
local SECRET={}
issecretvalue=function(v) return rawequal(v,SECRET) end
UnitFactionGroup=function() return "Alliance" end
UnitClass=function() return "Warrior","WARRIOR" end
UnitRace=function() return "Human","Human" end
UnitLevel=function() return state.level end
C_QuestLog={
 IsQuestFlaggedCompleted=function(q) return state.turned[q] or false end,
 GetLogIndexForQuestID=function(q) return state.log[q] and 1 or nil end,
 IsComplete=function(q) return state.ready[q] or false end,
 GetQuestObjectives=function(q) return state.objectives or {} end,
 GetTitleForQuestID=function(q) return "Quest "..q end,
}
C_Item={GetItemCount=function(q) return state.items[q] or 0 end}
C_Map={}
assert(loadfile(root.."Core.lua"))("ForeverSprint",F)
F.QuestTitles={}; F.ZoneIDs={}; F.Trainers={}
F:Init()
local function fixture(steps)
 F.guides={}; F.order={}; F.db.marks={}; F.db.undo={}; F.excluded={}; F.inspect=nil
 F:RegisterGuide({id="test",name="Test",faction="Alliance",zone="Elwynn Forest",levels={1,10},steps=steps})
 F:Select("test"); return F.guide.steps
end
local s=fixture({{accept=1},{complete={1,2}},{turnin=1}})
check(not F:Done(s[1]),"empty log accept remains")
state.log[1]=true; check(F:Done(s[1]),"accepted advances")
check(not F:Done(s[2]),"group needs all eligible quests")
state.ready[1]=true; state.log[2]=true; state.ready[2]=true
check(F:Done(s[2]),"group completion")
check(not F:Done(s[3]),"ready is not turned in")
state.log[1]=nil; state.ready[1]=nil
check(not F:Done(s[3]),"abandon is not turnin")
state.turned[1]=true; check(F:Done(s[3]),"confirmed turnin")
state={log={},ready={},turned={},items={},level=1}
s=fixture({{accept=1},{turnin=1}})
F:Manual("skip"); check(F:Done(s[1]),"manual skip")
F:Undo(); check(not F:Done(s[1]),"undo reverses mark")
s=fixture({{complete={1,2},only={[2]={"MAGE"}}}})
state.log[1]=true; state.ready[1]=true
check(F:Done(s[1]),"per-quest class filter")
s=fixture({{complete=1,objectives={[1]={"wolf"}}}})
state.ready[1]=nil; state.objectives={{text="Wolves slain",finished=false},{text="Wolf pelts",finished=true}}
check(F:HuntDone(s[1],1),"matched partial objective")
state.objectives={{text="Other",finished=true}}
check(not F:HuntDone(s[1],1),"unmatched subset not false complete")
state.objectives={{text="Wolf pelts",finished=SECRET}}
check(not F:HuntDone(s[1],1),"secret completion unavailable")
s=fixture({{accept=10,dungeon="DM"},{accept=11,requires={10}},{complete={11,12}},{level=2,nodungeon="DM"}})
F:SoloExclusions()
check(not F:Applies(s[1]) and not F:Applies(s[2]),"dungeon chain excluded")
check(#F:IDs(s[3])==1 and F:IDs(s[3])[1]==12,"mixed batch preserves solo IDs")
check(F:Applies(s[4]),"solo catchup retained")
s=fixture({{accept=21,minlevel=3},{accept=22},{accept=23,fromitem=true},{turnin=23}})
check(F:Current()==s[2],"minlevel deferred")
check(not F:Done(s[1]),"deferred is not done")
state.log[22]=true
check(F:Current()==s[1],"all remaining gates produce first waiting step")
state.level=3; check(F:Current()==s[1],"level gate reopens")
state.log[21]=true; check(F:Current()==s[3],"item remains pending")
state.log[23]=true; check(F:Current()==s[4],"accepted item quest reopens turnin")
state={log={[1]=true},ready={},turned={},items={},level=1}
s=fixture({{accept=1},{complete=1,minlevel=3},{turnin=1},{accept=3,requires={1}},{accept=2}})
check(F:Current()==s[5],"gated hunt defers its turnin and follow-up accept")
check(not F:Done(s[2]) and not F:Done(s[3]),"deferred hunt chain remains incomplete")
state.level=3
check(F:Current()==s[2],"gated hunt reopens at required level")
local epsilon=.00001
if math.atan2 then
 local a,d=F:Bearing(1,0,0,1,10,0,0); check(math.abs(a)<epsilon and d==10,"north")
 a=F:Bearing(1,0,0,1,0,10,0); check(math.abs(a-math.pi/2)<epsilon,"west")
 a=F:Bearing(1,0,0,1,-10,0,0); check(math.abs(a-math.pi)<epsilon,"south")
 a=F:Bearing(1,0,0,1,0,-10,0); check(math.abs(a-3*math.pi/2)<epsilon,"east")
 a=F:Bearing(1,0,0,1,0,10,math.pi/2); check(math.abs(a)<epsilon,"facing relative")
else error("Lua runtime must expose WoW-compatible math.atan2 for bearing test") end
check(F:Bearing(1,0,0,2,1,1,0)==nil,"different continent hidden")
check(F:Bearing(1,0,0,1,nil,1,0)==nil,"missing coordinate hidden")
check(F:Bearing(1,0,0,1,SECRET,1,0)==nil,"secret coordinate hidden")
check(F:Bearing(1,0,0,1,0,1,SECRET)==nil,"secret facing hidden")
CreateVector2D=function(x,y) return {x=x,y=y} end
GetPlayerFacing=function() return 0 end
local converted={}
C_Map.GetBestMapForUnit=function() return 1429 end
C_Map.GetPlayerMapPosition=function() return {x=.1,y=.2} end
C_Map.GetWorldPosFromMapPos=function(map,v)
 converted[#converted+1]={v.x,v.y}
 return 1,{x=v.x*1000,y=v.y*1000}
end
local angle,dist=F:Offset(1429,.8,.9)
check(dist and dist>900,"offset target differs from player")
check(converted[2][1]==.8 and converted[2][2]==.9,"target coordinates preserved")
-- Register every shipped guide through the real engine.
F.guides={}; F.order={}
local toc=assert(io.open(root.."ForeverSprint.toc"))
for line in toc:lines() do
 if line:match("^Guides") then assert(loadfile(root..line:gsub("\\","/")))("ForeverSprint",F) end
end
toc:close()
check(#F.order==46,"all guide files register")
local main,draft,dungeon,catchup=0,0,0,0
for _,g in ipairs(F.order) do
 if not g.side then main=main+1; if g.draft then draft=draft+1 end end
 if g.next then check(F.guides[g.next]~=nil,"next guide exists: "..g.id) end
 for _,step in ipairs(g.steps) do
  if step.dungeon then dungeon=dungeon+1 end
  if step.nodungeon then catchup=catchup+1 end
  if step.at then check(step.at[1]>=0 and step.at[1]<=100 and step.at[2]>=0 and step.at[2]<=100,"coordinates bounded") end
 end
end
check(main==28 and draft==28,"all main chapters draft")
check(dungeon==513 and catchup==36,"source solo counts preserved")
print("PASS: "..passed.." engine/data assertions")

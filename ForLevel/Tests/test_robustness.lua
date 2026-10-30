-- Adversarial API/state regressions and actual-data coverage. No live client.
local root=assert(arg[1]); local F={}; local passed=0
local function check(v,message) assert(v,message); passed=passed+1 end
local faction,race,class,level="Alliance","Human","WARRIOR",1
local log,ready,turned,objectives={},{},{},{}
local SECRET={}
issecretvalue=function(v) return rawequal(v,SECRET) end
UnitFactionGroup=function() return faction end
UnitRace=function() return race,race end
UnitClass=function() return class,class end
UnitLevel=function() return level end
local function resetAPIs()
 C_QuestLog={IsQuestFlaggedCompleted=function(q) return turned[q] or false end,
  GetLogIndexForQuestID=function(q) return log[q] and 1 or nil end,
  IsComplete=function(q) return ready[q] or false end,
  GetQuestObjectives=function(q) return objectives[q] or {} end,
  GetTitleForQuestID=function(q) return "Quest "..q end}
 C_Item={GetItemCount=function() return 0 end}; C_Map={}; Enum=nil
 CreateVector2D=function(x,y) return {x=x,y=y} end
 GetPlayerFacing=function() return 0 end
end
resetAPIs()
for line in io.lines(root.."ForLevel.toc") do
 if line~="" and line:sub(1,1)~="#" and line~="UI.lua" then assert(loadfile(root..line:gsub("\\","/")))("ForLevel",F) end
end
local sourceGuides,sourceOrder=F.guides,F.order
local function fixture(steps)
 F.guides={}; F.order={}; ForLevelCharDB={}; log={}; ready={}; turned={}; objectives={}
 F:RegisterGuide({id="test",name="Test",zone="Elwynn Forest",faction="Alliance",levels={1,60},steps=steps})
 F:Init(); return F.guide.steps
end
local s=fixture({{accept=1,dungeon="DM"},{accept=2,requires={1}},{accept=3},{accept=2,requires={3}},{complete={2,4}}})
check(F.excluded[1] and not F.excluded[2],"valid alternative solo accept retained")
check(not F:Applies(s[2]) and F:Applies(s[4]),"only impossible accept alternative filtered")
check(#F:IDs(s[5])==2,"mixed batch keeps alternative-reachable quest")
s=fixture({{accept=1},{turnin=1}})
F:RegisterGuide({id="enemy",name="Enemy",zone="Durotar",faction="Horde",levels={1,60},steps={{accept=3}}})
ForLevelCharDB={routeVersion="BoostedXP-1.0.6",guide="removed",hidden="yes",
 marks={test={[1]="skip",[0]="manual",[1.5]="skip",[100]="skip",[2]=true},removed={[1]="manual"}},
 undo={"bad",{guide="test"},{guide="removed",index=1},{guide="enemy",index=1},{guide="test",index=0},{guide="test",index=1.5},{guide="test",index=1,previous=false},{guide="test",index=1,previous="manual"}},
 turned={[1]=true,[2]="true",[0]=true,[1.5]=true,["3"]=true},position={"INVALID","CENTER",0,0}}
F:Init()
check(F.db.marks.test[1]=="skip" and F.db.marks.test[2]==nil,"valid marks retained; malformed values removed")
check(F.db.marks.test[0]==nil and F.db.marks.test[1.5]==nil and F.db.marks.test[100]==nil and F.db.marks.removed==nil,"mark indices and guide IDs bounded")
check(#F.db.undo==1 and F.db.undo[1].previous=="manual","undo shape/compatibility/bounds sanitized")
check(F.db.turned[1] and not F.db.turned[2] and not F.db.turned[0] and not F.db.turned[1.5] and not F.db.turned["3"],"only confirmed integer quest history trusted")
check(not F.db.hidden and F.db.position==nil,"malformed visibility and anchor dropped")
F.db.undo={{guide="removed",index=2,previous="skip"}}
local oldGuide=F.guide; F.inspect=nil
check(not F:Undo() and F.guide==oldGuide and F.inspect==nil and F.db.marks.test[2]==nil,"removed guide undo never mutates current guide")
F.db.undo={{guide="test"},"bad"}; check(not F:Undo(),"runtime malformed undo cannot crash")
local oversized={}; for i=1,150 do oversized[i]={guide="test",index=1} end
F.db.undo=oversized; F:Init(); check(#F.db.undo==100,"undo storage capped at 100")
F.db.undo={[2]={guide="test",index=1}}; F:Init(); check(#F.db.undo==0,"sparse undo ignored safely")
for _,position in ipairs({{"CENTER","CENTER",0/0,0},{"CENTER","CENTER",math.huge,0},{"CENTER","CENTER","1",0},{"CENTER","CENTER",1e9,0}}) do
 F.db.position=position; F:Init(); check(F.db.position==nil,"nonfinite/non-numeric/excessive position removed")
end
F.db.position={"TOPLEFT","TOPLEFT",10,-20}; F:Init(); check(F.db.position[3]==10,"valid position retained")
-- Unknown APIs never fabricate completion; a previously confirmed turn-in is trusted history.
s=fixture({{accept=10},{complete=10},{turnin=10}})
for _,name in ipairs({"IsQuestFlaggedCompleted","GetLogIndexForQuestID","IsComplete","GetQuestObjectives"}) do
 local original=C_QuestLog[name]
 for _,behavior in ipairs({function() return nil end,function() error("unavailable") end,function() return SECRET end}) do
  C_QuestLog[name]=behavior
  check(not F:Done(s[2]) and not F:Done(s[3]),"unknown API is not completion: "..name)
 end
 C_QuestLog[name]=original
end
F.db.turned[10]=true; C_QuestLog.IsQuestFlaggedCompleted=function() error("offline") end
check(F:Done(s[3]),"confirmed cached turn-in survives unavailable query")
check(not F:Turned(11),"uncached unknown quest remains unknown")
resetAPIs(); F.db.turned={}; local original=C_QuestLog.IsComplete; C_QuestLog.IsComplete=nil
check(F:Current()==nil and F.missingAPI~=nil,"missing required API suspends current route immediately")
C_QuestLog.IsComplete=original
check(F:Current()~=nil and F.missingAPI==nil,"API recovery requires no reload or reinit")
-- Broken routing is unavailable, never a fabricated completion state.
s=fixture({{accept=1}}); turned[1]=true
F.guide.next="missing"
check(F:Current()==nil and F.routeError:find("Missing next chapter",1,true),"missing next chapter reports route error")
F.guide.next="test"
check(F:Current()==nil and F.routeError:find("Cyclic",1,true),"self cycle bounded and reported")
F.guide.next=false
check(F:Current()==nil and F.routeError:find("Invalid",1,true),"malformed next chapter reported")
F:RegisterGuide({id="enemy",name="Enemy",faction="Horde",zone="Durotar",levels={1,60},steps={{accept=2}}})
F.guide.next="enemy"
check(F:Current()==nil and F.routeError:find("Incompatible",1,true),"incompatible next chapter reported")
F.guide.next=nil; F:Select("test")
check(F.routeError==nil and F:Current()==nil and F.routeError==nil,"valid terminal chapter clears error")
for i=1,22 do F:RegisterGuide({id="chain"..i,name="Chain",faction="Alliance",zone="Elwynn Forest",levels={1,60},next=i<22 and "chain"..(i+1) or nil,steps={{accept=1}}}) end
F:Select("chain1")
check(F:Current()==nil and F.routeError=="Chapter traversal limit reached","oversized runtime chain bounded with explicit error")
F:Select("test"); check(F.routeError==nil,"valid selection recovers from traversal error")
-- All conversion and object member accesses stay inside protected boundaries.
C_Map.GetWorldPosFromMapPos=function(_,v) return 1,{x=v.x*1000,y=v.y*1000} end
CreateVector2D=function() error("vector creation unavailable") end
check(F:World(1429,.2,.3)==nil,"throwing vector factory suppressed")
CreateVector2D=function(x,y) return {x=x,y=y} end
C_Map.GetBestMapForUnit=function() return 1429 end
C_Map.GetPlayerMapPosition=function() return {x=.1,y=.1} end
GetPlayerFacing=function() error("facing unavailable") end
check(F:Offset(1429,.8,.9)==nil,"throwing facing query suppressed")
GetPlayerFacing=function() return 0 end
for _,pos in ipairs({{x=math.huge,y=.1},{x=0/0,y=.1},{x=1.1,y=.1},{x=-.1,y=.1},SECRET,setmetatable({},{__index=function() error("position inaccessible") end})}) do
 C_Map.GetPlayerMapPosition=function() return pos end
 check(F:Offset(1429,.8,.9)==nil,"invalid player position suppressed")
end
check(F:World(1429,.2,1.1)==nil and F:World(1429,0/0,.1)==nil,"invalid destination suppressed")
check(F:Bearing(1,1e308,0,1,-1e308,0,0)==nil,"derived coordinate difference overflow suppressed")
check(F:Bearing(1,0,0,1,1e308,0,0)==nil,"derived distance overflow suppressed")
-- Only verified zone metadata overrides static IDs; walk interior parents with bounds.
Enum={UIMapType={Zone=3}}
local best=9999; local maps={[9999]={name="Elwynn Forest",mapType=3}}
C_Map.GetBestMapForUnit=function() return best end
C_Map.GetMapInfo=function(id) return maps[id] end
F.learned={}; F:LearnZone(); check(F:Resolve("Elwynn Forest")==9999,"verified observed zone overrides static ID")
best=8888; maps[8888]={name="Goldshire Inn",mapType=5,parentMapID=9999}
F:LearnZone(); check(F.learned["Goldshire Inn"]==nil and F:Resolve("Elwynn Forest")==9999,"interior resolves nearest zone only")
maps[8888]={name="Elwynn Forest",mapType=5,parentMapID=8889}; maps[8889]={mapType=5,parentMapID=8888}
F:LearnZone(); check(F:Resolve("Elwynn Forest")==9999,"cyclic parents preserve verified map")
maps[8888]=setmetatable({},{__index=function() error("mapinfo inaccessible") end})
F:LearnZone(); check(F:Resolve("Elwynn Forest")==9999,"inaccessible map metadata suppressed")
maps[8888]={name="Westfall",mapType=3}; F:LearnZone()
check(F:Resolve("Elwynn Forest")==9999 and F:Resolve("Westfall")==8888,"unrelated names never overwrite another zone")
Enum=nil; F.learned={}; F:LearnZone(); check(F:Resolve("Elwynn Forest")==1429,"missing Enum retains safe static fallback")
-- Advisory-only route fields preserve eligibility and do not alter quest state.
resetAPIs()
s=fixture({{accept=1},{accept=2,class={"MAGE"}},{complete=3,onway={1,1,2},hint="Work on held quests",drops={[4]="Find item four",[5]="Find item five"}}})
log[1]=true; log[2]=true; objectives[1]={{text="Unfinished",finished=false},{text="Finished",finished=true}}
local advisory=table.concat(F:Advisory(s[3]),"\n")
check(advisory:find("Quest 1",1,true) and not advisory:find("Quest 2",1,true),"onway filters class and deduplicates")
check(advisory:find("Unfinished",1,true) and not advisory:find("[ ] Finished",1,true),"onway shows unfinished objectives only")
check(advisory:find("Find item four",1,true)<advisory:find("Find item five",1,true),"pending drop hints sorted")
log[4]=true; turned[5]=true; log[1]=nil
advisory=table.concat(F:Advisory(s[3]),"\n")
check(not advisory:find("Find item",1,true) and not advisory:find("Work on held quests",1,true),"accepted drops and unheld onway hints suppressed")
-- All actual source guide chains and all navigation candidates are inspected.
F.guides,F.order=sourceGuides,sourceOrder; resetAPIs()
local expected={["horde-40-45:111:area:16"]=true,["horde-40-45:116:area:18"]=true}
local invalid,points,steps=0,0,0
for _,g in ipairs(F.order) do
 local seen,current={},g
 while current do
  check(not seen[current.id],"source next-guide chain cycle-free: "..g.id); seen[current.id]=true
  current=current.next and F.guides[current.next]
 end
 for _,step in ipairs(g.steps) do
  steps=steps+1
  local candidates={}
  if step.at then candidates[#candidates+1]={step.at,"at"} end
  if step.healer then candidates[#candidates+1]={step.healer,"healer"} end
  for i,area in ipairs(step.areas or {}) do candidates[#candidates+1]={area,"area:"..i} end
  for _,candidate in ipairs(candidates) do
   points=points+1; local key=g.id..":"..step.index..":"..candidate[2]
   if not F.ValidPoint(candidate[1]) then
    invalid=invalid+1; check(expected[key],"unexpected invalid source coordinate: "..key)
    check(F:Coordinate(step,candidate[1],candidate[2])==nil and F.navigationWarnings[key],"known invalid candidate rejected with diagnostic")
   else check(not expected[key],"known invalid source inventory changed; review it") end
  end
 end
end
check(invalid==2 and points==13092 and steps==5938,"all source point/action inventory inspected")
-- Broad race/class superset covers every starting route without assuming unsupported client combinations are playable.
local starts={Alliance={"Human","Dwarf","Gnome","NightElf","Skyborne"},Horde={"Orc","Troll","Tauren","Scourge","Skyborne"}}
local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local profiles=0
for side,races in pairs(starts) do for _,token in ipairs(races) do for _,kind in ipairs(classes) do
 faction,race,class,level=side,token,kind,1; ForLevelCharDB={}; F:Init(); profiles=profiles+1
 check(F.guide and F:GuideApplies(F.guide) and not F.guide.side,"matching source start for "..side..":"..token..":"..kind)
 check(F:Current()~=nil,"initial current step available")
 local g=F.guide; local seen={}
 while g do
  check(not seen[g.id] and F:GuideApplies(g),"compatible bounded faction route chain"); seen[g.id]=true
  for _,step in ipairs(g.steps) do
   if step.dungeon then check(not F:Applies(step),"dungeon always filtered") end
   if step.nodungeon and F.Matches(step.class,class) and F.Matches(step.race,race) then check(F:Applies(step),"solo catchup retained") end
  end
  if not g.next then check(g.levels[2]==60,"main route reaches level60") end
  g=g.next and F.guides[g.next]
 end
end end end
check(profiles==90,"90 faction/race/class coverage profiles")
-- Confirm real-data automatic chapter handoff and terminal state without inventing quest completions.
faction,race,class="Alliance","Human","WARRIOR"; ForLevelCharDB={}; F:Init()
local initial=F.guide; for _,step in ipairs(initial.steps) do if F:Applies(step) then F:MarkTable(initial)[step.index]="manual" end end
check(F:Current()~=nil and F.guide.id==initial.next,"completed chapter hands off to next")
for _,g in ipairs(F.order) do if not g.side and F:GuideApplies(g) then for _,step in ipairs(g.steps) do F:MarkTable(g)[step.index]="manual" end end end
check(F:Current()==nil and F.guide.levels[2]==60,"terminal route state bounded")
print("PASS: "..passed.." robustness/data/profile assertions; 90 profiles; 2 known invalid coordinates rejected")

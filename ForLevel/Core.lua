-- ForLevel: original guidance-only engine. Licensed route data is separate.
local _, F = ...
F.guides, F.order = {}, {}
local kinds = {"accept","turnin","complete","go","level","sethome","flightpath","fly","hearth","train","vendor","loot","note","die"}
local questKinds = {accept=true,turnin=true,complete=true}
function F.Plain(v)
    if issecretvalue then local ok,secret=pcall(issecretvalue,v); if not ok or secret then return nil end end
    return v
end
local function call(t,k,...)
    local fn=F.Read(t,k)
    if type(fn) ~= "function" then return nil end
    local ok,v = pcall(fn,...)
    if ok then return F.Plain(v) end
end
F.Call=call
function F.Number(v)
    v=F.Plain(v)
    if type(v)=="number" and v==v and v~=math.huge and v~=-math.huge then return v end
end
function F.Table(v)
    v=F.Plain(v)
    if type(v)~="table" then return nil end
    if issecrettable then local ok,secret=pcall(issecrettable,v); if not ok or secret then return nil end end
    if canaccesstable then local ok,accessible=pcall(canaccesstable,v); if not ok or not accessible then return nil end end
    return v
end
function F.Read(t,key)
    t=F.Plain(t)
    if type(t)=="table" then if not F.Table(t) then return nil end
    elseif type(t)~="userdata" then return nil end
    local ok,value=pcall(function() return t[key] end)
    if ok then return F.Plain(value) end
end
function F.Integer(v,low,high)
    v=F.Number(v)
    if v and v==math.floor(v) and v>=low and v<=high then return v end
end
function F.Matches(filter,value)
    if filter==nil then return true end
    if type(filter)~="table" then return filter==value end
    for _,v in ipairs(filter) do if v==value then return true end end
    return false
end
function F:RegisterGuide(g)
    assert(not self.guides[g.id],"Duplicate guide ID")
    for i,s in ipairs(g.steps) do
        local count=0
        for _,k in ipairs(kinds) do if s[k]~=nil then s.kind=k; count=count+1 end end
        assert(count==1,"Invalid action in "..g.id..":"..i)
        s.index,s.owner=i,g
        if questKinds[s.kind] then s.ids=type(s[s.kind])=="table" and s[s.kind] or {s[s.kind]} end
    end
    self.guides[g.id]=g; self.order[#self.order+1]=g
end
function F:Character()
    self.faction=call(_G,"UnitFactionGroup","player")
    local function token(name)
        local fn=F.Read(_G,name)
        if type(fn)~="function" then return nil end
        local ok,_,value=pcall(fn,"player")
        if ok then return F.Plain(value) end
    end
    self.class,self.race=token("UnitClass"),token("UnitRace")
end
function F:Level() return F.Integer(call(_G,"UnitLevel","player"),1,1000) or 1 end
function F:GuideApplies(g)
    return g.faction==self.faction and self.Matches(g.races,self.race) and self.Matches(g.classes,self.class)
end
function F:Applies(s)
    if s.dungeon or not self.Matches(s.class,self.class) or not self.Matches(s.race,self.race) then return false end
    if s.quest and self.excluded and self.excluded[s.quest] then return false end
    if s.accept then for _,q in ipairs(s.requires or {}) do if self.excluded and self.excluded[q] then return false end end end
    if s.ids and #self:IDs(s)==0 then return false end
    return true
end
function F:IDs(s)
    local ids={}
    for _,q in ipairs(s.ids or {}) do
        if (not s.only or self.Matches(s.only[q],self.class)) and not (self.excluded and self.excluded[q]) then ids[#ids+1]=q end
    end
    return ids
end
function F:SoloExclusions()
    local alternatives,dungeon={},{}
    self.excluded={}
    for _,g in ipairs(self.order) do
        if self:GuideApplies(g) then
            for _,s in ipairs(g.steps) do
                if s.accept and self.Matches(s.class,self.class) and self.Matches(s.race,self.race) then
                    for _,q in ipairs(s.ids) do
                        if self.Matches(s.only and s.only[q],self.class) then
                            if s.dungeon then dungeon[q]=true else
                                alternatives[q]=alternatives[q] or {}; alternatives[q][#alternatives[q]+1]=s
                            end
                        end
                    end
                end
            end
        end
    end
    for q in pairs(dungeon) do if not alternatives[q] then self.excluded[q]=true end end
    -- Exclude a quest only if every applicable solo accept alternative is blocked.
    -- The fixed point is monotonic and bounded by the number of known quests.
    local limit=1; for _ in pairs(alternatives) do limit=limit+1 end
    for _=1,limit do
        local changed=false
        for q,options in pairs(alternatives) do if not self.excluded[q] then
            local available=false
            for _,s in ipairs(options) do
                local blocked=false
                for _,req in ipairs(s.requires or {}) do if self.excluded[req] then blocked=true; break end end
                if not blocked then available=true; break end
            end
            if not available then self.excluded[q]=true; changed=true end
        end end
        if not changed then break end
    end
end
function F:Turned(q) return call(C_QuestLog,"IsQuestFlaggedCompleted",q)==true or self.db.turned[q]==true end
function F:InLog(q)
    return F.Integer(call(C_QuestLog,"GetLogIndexForQuestID",q),1,2147483647)~=nil
end
function F:Ready(q) return self:InLog(q) and call(C_QuestLog,"IsComplete",q)==true end
function F:Item(id) return F.Number(call(C_Item,"GetItemCount",id)) or 0 end
function F:Objectives(q) return F.Table(call(C_QuestLog,"GetQuestObjectives",q)) or {} end
function F:HuntDone(s,q)
    if self:Turned(q) or self:Ready(q) then return true end
    local names=s.objectives and s.objectives[q]
    if not names or not self:InLog(q) then return false end
    local matched={}
    for _,o in ipairs(self:Objectives(q)) do
        if not F.Table(o) then return false end
        local text=F.Read(o,"text")
        if type(text)=="string" then
            for n,name in ipairs(names) do
                if text:lower():find(name:lower(),1,true) then
                    if F.Read(o,"finished")~=true then return false end
                    matched[n]=true
                end
            end
        end
    end
    for n in ipairs(names) do if not matched[n] then return false end end
    return #names>0
end
function F:MarkTable(g)
    self.db.marks[g.id]=self.db.marks[g.id] or {}
    return self.db.marks[g.id]
end
function F:Done(s)
    if self:MarkTable(s.owner)[s.index] then return true end
    if s.ids then
        for _,q in ipairs(self:IDs(s)) do
            if s.kind=="accept" and not (self:Turned(q) or self:InLog(q)) then return false end
            if s.kind=="turnin" and not self:Turned(q) then return false end
            if s.kind=="complete" and not self:HuntDone(s,q) then return false end
        end
        return true
    end
    if s.level then return self:Level()>=s.level end
    if (s.vendor or s.loot) and s.item and self:Item(s.item)>=(s.count or 1) then return true end
    if s.quest and (self:Turned(s.quest) or (s.loot and self:InLog(s.quest)) or (s.vendor and self:Ready(s.quest))) then return true end
    return false
end
function F:Blocked(s)
    if s.minlevel and self:Level()<s.minlevel then return "Requires level "..s.minlevel end
    for _,q in ipairs(s.requires or {}) do
        if not self:Turned(q) then return "Missing prerequisite: "..self:Title(q).." ("..q..")" end
    end
    if s.kind=="turnin" then
        for _,q in ipairs(self:IDs(s)) do if not (self:Turned(q) or self:Ready(q)) then return "Finish objectives first: "..self:Title(q) end end
    elseif s.kind=="complete" then
        for _,q in ipairs(self:IDs(s)) do if not (self:Turned(q) or self:InLog(q)) then return "Accept quest first: "..self:Title(q) end end
    elseif s.fromitem then
        if type(s.fromitem)=="number" and self:Item(s.fromitem)==0 then return "Loot the quest-starting item first" end
        if s.fromitem==true then return "Item-start quest: loot and use its item; Skip to defer" end
    end
end
function F:Title(q)
    local t=call(C_QuestLog,"GetTitleForQuestID",q)
    if type(t)=="string" and t~="" then return t end
    return self.QuestTitles[q] or ("Quest "..q)
end
function F:Text(s)
    local labels={accept="Accept",turnin="Turn in",complete="Do",go="Travel",level="Reach level",sethome="Set hearth",flightpath="Learn flight path",fly="Fly",hearth="Hearth",train="Train",vendor="Buy",loot="Loot",note="Note",die="Death shortcut"}
    local values={}
    if s.ids then for _,q in ipairs(self:IDs(s)) do values[#values+1]=self:Title(q) end
    else values[1]=type(s[s.kind])=="boolean" and (s.text or s.npc or "Confirm manually") or tostring(s[s.kind]) end
    return labels[s.kind]..": "..table.concat(values,", ")
end
function F:Select(id)
    local g=self.guides[id]
    if not g or not self:GuideApplies(g) then return false end
    self.guide=g; self.db.guide=id; self.inspect=nil; self.routeError=nil; return true
end
function F:DefaultGuide()
    local best
    for _,g in ipairs(self.order) do
        if not g.side and self:GuideApplies(g) and g.levels[1]<=self:Level() and (not best or g.levels[1]>best.levels[1]) then best=g end
    end
    return best
end
function F:Current()
    if not self:CheckAPIs() then return nil end
    local g=self.guide
    if not g then return nil end
    self.routeError=nil
    if self.inspect then return g.steps[self.inspect] end
    local visited={}
    for _=1,20 do
        visited[g.id]=true
        local waiting
        for _,s in ipairs(g.steps) do
            if self:Applies(s) and not self:Done(s) then
                -- Level/item gates are deferred without recording completion; revisit every refresh.
                if self:Deferred(s,{}) then waiting=waiting or s else return s end
            end
        end
        if waiting then return waiting end
        if g.next==nil then return nil end
        if type(g.next)~="string" or g.next=="" then self.routeError="Invalid next chapter in "..g.id; return nil end
        local n=self.guides[g.next]
        if not n then self.routeError="Missing next chapter: "..g.next; return nil end
        if not self:GuideApplies(n) then self.routeError="Incompatible next chapter: "..g.next; return nil end
        if visited[n.id] then self.routeError="Cyclic chapter link: "..n.id; return nil end
        self:Select(n.id); g=n
    end
    self.routeError="Chapter traversal limit reached"
end
function F:Deferred(s,seen)
    if seen[s] then return false end
    seen[s]=true
    if self:Done(s) then return false end
    if s.minlevel and self:Level()<s.minlevel then return true end
    if s.fromitem and self:Blocked(s) then return true end
    -- A turn-in inherits its earlier hunt's gate; a follow-up accept inherits
    -- prerequisite turn-ins. Otherwise an accepted, level-gated quest stalls
    -- unrelated work at its turn-in instead of remaining safely deferred.
    local dependencies={}
    if s.kind=="turnin" then
        for _,q in ipairs(self:IDs(s)) do if not (self:Ready(q) or self:Turned(q)) then dependencies[q]="complete" end end
    elseif s.kind=="accept" then
        for _,q in ipairs(s.requires or {}) do if not self:Turned(q) then dependencies[q]="turnin" end end
    end
    for q,kind in pairs(dependencies) do
        for i=s.index-1,1,-1 do
            local previous=s.owner.steps[i]
            if previous.kind==kind and self:Applies(previous) then
                local found=false
                for _,id in ipairs(self:IDs(previous)) do if id==q then found=true; break end end
                if found then if self:Deferred(previous,seen) then return true end; break end
            end
        end
    end
    local wanted={}
    for _,q in ipairs(s.requires or {}) do if not self:Turned(q) then wanted[q]=true end end
    if s.kind~="accept" then for _,q in ipairs(self:IDs(s)) do if not self:InLog(q) and not self:Turned(q) then wanted[q]=true end end end
    for _,a in ipairs(s.owner.steps) do if a.accept and self:Applies(a) then
        for _,q in ipairs(self:IDs(a)) do if wanted[q] and self:Deferred(a,seen) then return true end end
    end end
    return false
end
function F:Manual(reason)
    local s=self:Current(); if not s then return end
    local marks=self:MarkTable(s.owner)
    self.db.undo[#self.db.undo+1]={guide=s.owner.id,index=s.index,previous=marks[s.index]}
    if #self.db.undo>100 then table.remove(self.db.undo,1) end
    marks[s.index]=reason; self.inspect=nil
end
function F:Undo()
    self.db.undo=F.Table(self.db.undo) or {}
    for _=1,100 do
        local u=table.remove(self.db.undo)
        if u==nil then return false end
        local valid=self:UndoEntry(u)
        if valid and self:Select(valid.guide) then
            self:MarkTable(self.guide)[valid.index]=valid.previous; self.inspect=valid.index; return true
        end
    end
    return false
end
function F:Back()
    local s=self:Current(); if not s then return end
    for i=s.index-1,1,-1 do if self:Applies(s.owner.steps[i]) then self.inspect=i; return end end
end
function F:Bearing(pc,px,py,tc,tx,ty,facing)
    pc,tc=F.Number(pc),F.Number(tc)
    px,py,tx,ty,facing=F.Number(px),F.Number(py),F.Number(tx),F.Number(ty),F.Number(facing)
    if not pc or not tc or pc~=tc or not px or not py or not tx or not ty or not facing then return nil end
    local dx,dy=F.Number(tx-px),F.Number(ty-py)
    if not dx or not dy then return nil end
    local distance=F.Number(math.sqrt(dx*dx+dy*dy))
    if not distance then return nil end
    local atan2=math.atan2
    if not atan2 then return nil end
    return (atan2(dy,dx)-facing)%(2*math.pi),distance
end
function F:World(map,x,y)
    map,x,y=F.Integer(map,1,2147483647),F.Number(x),F.Number(y)
    local convert,vector=F.Read(C_Map,"GetWorldPosFromMapPos"),F.Read(_G,"CreateVector2D")
    if not map or not x or not y or x<0 or x>1 or y<0 or y>1 or type(convert)~="function" or type(vector)~="function" then return nil end
    local ok,c,v=pcall(function() return convert(map,vector(x,y)) end)
    if not ok then return nil end
    c=F.Number(c); v=F.Plain(v)
    if not c or not v then return nil end
    return c,F.Number(F.Read(v,"x")),F.Number(F.Read(v,"y"))
end
function F:Resolve(zone)
    if type(zone)=="number" then return F.Integer(zone,1,2147483647) end
    return self.learned and self.learned[zone] or self.ZoneIDs[zone]
end
function F:LearnZone()
    local zoneType=F.Number(F.Read(F.Read(Enum,"UIMapType"),"Zone"))
    if not zoneType then return end
    local map=F.Integer(call(C_Map,"GetBestMapForUnit","player"),1,2147483647)
    local seen={}
    for _=1,16 do
        if not map or seen[map] then return end
        seen[map]=true
        local info=call(C_Map,"GetMapInfo",map)
        local kind,name=F.Number(F.Read(info,"mapType")),F.Read(info,"name")
        if kind==zoneType then
            if type(name)=="string" and name~="" then self.learned[name]=map end
            return
        end
        map=F.Integer(F.Read(info,"parentMapID"),1,2147483647)
    end
end
function F:Offset(map,x,y)
    local pm=F.Number(call(C_Map,"GetBestMapForUnit","player"))
    if not pm then return nil end
    local pos=call(C_Map,"GetPlayerMapPosition",pm,"player")
    if not pos then return nil end
    local px,py=F.Number(F.Read(pos,"x")),F.Number(F.Read(pos,"y"))
    if not px or not py or px<0 or px>1 or py<0 or py>1 or (px==0 and py==0) then return nil end
    local pc,wx,wy=self:World(pm,px,py)
    local tc,tx,ty=self:World(map,x,y)
    local facing=F.Number(call(_G,"GetPlayerFacing"))
    return self:Bearing(pc,wx,wy,tc,tx,ty,facing)
end
function F:Target(s)
    if not s or self:Blocked(s) then return nil end
    local at=s.at
    if s.kind=="train" then
        -- Source planner coordinates may name another class's trainer. Use only our class's verified list.
        local list=self.Trainers[self.faction] and self.Trainers[self.faction][self.class] or {}
        local best,bd
        for _,t in ipairs(list) do local a,d=self:Offset(t.map,t.x/100,t.y/100); if d and (not bd or d<bd) then best,bd=t,d end end
        if best then return self:Offset(best.map,best.x/100,best.y/100) end
        return nil
    end
    if s.kind=="complete" and s.areas then
        local angle,dist,radius
        for _,a in ipairs(s.areas) do
            local relevant=false
            for _,q in ipairs(self:IDs(s)) do if a.q==q and not self:HuntDone(s,q) then relevant=true end end
            local map,x,y
            if relevant then map,x,y=self:Coordinate(s,a,"area:".._) end
            if map then
                local b,d=self:Offset(map,x,y)
                local r=F.Number(a.r) or 30; if r<0 then r=30 end
                if d and (not dist or d-r<dist-(radius or 0)) then angle,dist,radius=b,d,r end
            end
        end
        if dist then return angle,dist,radius end
    end
    if not at then return nil end
    local map,x,y=self:Coordinate(s,at,"at")
    if map then return self:Offset(map,x,y) end
end
function F.ValidPoint(point)
    local x,y=F.Number(F.Read(point,1)),F.Number(F.Read(point,2))
    return x~=nil and y~=nil and x>=0 and x<=100 and y>=0 and y<=100
end
function F:Coordinate(s,point,kind)
    if not F.ValidPoint(point) then
        self.navigationWarnings=self.navigationWarnings or {}
        self.navigationWarnings[s.owner.id..":"..s.index..":"..kind]="Invalid source coordinate ignored"
        return nil
    end
    local map=self:Resolve(point[3] or s.owner.zone)
    if map then return map,point[1]/100,point[2]/100 end
end
function F:QuestEligible(q,g)
    if self.excluded and self.excluded[q] then return false end
    local found=false
    for _,s in ipairs(g.steps) do if s.accept then
        for _,id in ipairs(s.ids) do if id==q then
            found=true
            if self:Applies(s) and self.Matches(s.only and s.only[q],self.class) then return true end
        end end
    end end
    return not found -- A held quest may have been accepted in an earlier chapter.
end
function F:Advisory(s)
    local lines,seen,held={},{},false
    for _,q in ipairs(s.onway or {}) do
        if not seen[q] and self:QuestEligible(q,s.owner) and self:InLog(q) and not (self:Ready(q) or self:Turned(q)) then
            seen[q]=true; held=true; lines[#lines+1]="On the way: "..self:Title(q)
            for _,objective in ipairs(self:Objectives(q)) do
                local text=F.Read(objective,"text")
                if type(text)=="string" and F.Read(objective,"finished")~=true then lines[#lines+1]="[ ] "..text end
            end
        end
    end
    if s.hint and (not s.onway or held) then lines[#lines+1]=s.hint end
    local drops={}; for q in pairs(s.drops or {}) do if F.Integer(q,1,2147483647) then drops[#drops+1]=q end end
    table.sort(drops)
    for _,q in ipairs(drops) do
        if self:QuestEligible(q,s.owner) and not (self:InLog(q) or self:Turned(q)) and type(s.drops[q])=="string" then lines[#lines+1]=s.drops[q] end
    end
    return lines
end
local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local function mark(value) return value=="skip" or value=="manual" end
function F:UndoEntry(value)
    value=F.Table(value)
    if not value then return nil end
    local id=F.Read(value,"guide"); local g=type(id)=="string" and self.guides[id]
    if not g or (self.faction and not self:GuideApplies(g)) then return nil end
    local index=F.Integer(F.Read(value,"index"),1,#g.steps)
    local previous=F.Read(value,"previous")
    if not index or (previous~=nil and not mark(previous)) then return nil end
    return {guide=id,index=index,previous=previous}
end
function F:SanitizeState(saved)
    saved=F.Table(saved) or {}
    local db={routeVersion="BoostedXP-1.0.6",marks={},undo={},turned={},hidden=F.Read(saved,"hidden")==true}
    local id=F.Read(saved,"guide"); local g=type(id)=="string" and self.guides[id]
    if g and (not self.faction or self:GuideApplies(g)) then db.guide=id end
    if F.Read(saved,"routeVersion")==db.routeVersion then
        for guide,values in pairs(F.Table(F.Read(saved,"marks")) or {}) do
            local owner=type(guide)=="string" and self.guides[guide]
            if owner and F.Table(values) then
                local clean={}
                for key,value in pairs(values) do
                    local index=F.Integer(key,1,#owner.steps); value=F.Plain(value)
                    if index and mark(value) then clean[index]=value end
                end
                db.marks[guide]=clean
            end
        end
        local undo=F.Table(F.Read(saved,"undo")) or {}
        for i=1,100 do
            local entry=rawget(undo,i); if entry==nil then break end
            entry=self:UndoEntry(entry); if entry then db.undo[#db.undo+1]=entry end
        end
    end
    for key,value in pairs(F.Table(F.Read(saved,"turned")) or {}) do
        local quest=F.Integer(key,1,2147483647)
        if quest and F.Plain(value)==true then db.turned[quest]=true end
    end
    local position=F.Table(F.Read(saved,"position"))
    if position then
        local point,relative=F.Read(position,1),F.Read(position,2)
        local x,y=F.Number(F.Read(position,3)),F.Number(F.Read(position,4))
        if type(point)=="string" and type(relative)=="string" and anchors[point] and anchors[relative] and x and y and math.abs(x)<=100000 and math.abs(y)<=100000 then db.position={point,relative,x,y} end
    end
    return db
end
function F:CheckAPIs()
    self.missingAPI=nil
    local required={"IsQuestFlaggedCompleted","GetLogIndexForQuestID","IsComplete","GetQuestObjectives","GetTitleForQuestID"}
    for _,name in ipairs(required) do
        if type(F.Read(C_QuestLog,name))~="function" then self.missingAPI="C_QuestLog."..name; break end
    end
    return not self.missingAPI
end
function F:Init()
    self:Character()
    self.db=self:SanitizeState(ForLevelCharDB); ForLevelCharDB=self.db
    self:SoloExclusions(); self.learned={}; self.inspect=nil; self.guide=nil; self.routeError=nil
    self:CheckAPIs(); self:LearnZone()
    if not self:Select(self.db.guide) then local g=self:DefaultGuide(); if g then self:Select(g.id) end end
end

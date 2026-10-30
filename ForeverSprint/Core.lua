-- ForeverSprint: original guidance-only engine. Licensed route data is separate.
local _, F = ...
F.guides, F.order = {}, {}
local kinds = {"accept","turnin","complete","go","level","sethome","flightpath","fly","hearth","train","vendor","loot","note","die"}
local questKinds = {accept=true,turnin=true,complete=true}
function F.Plain(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end
local function call(t,k,...)
    if not t or type(t[k]) ~= "function" then return nil end
    local ok,v = pcall(t[k],...)
    if ok then return F.Plain(v) end
end
function F.Number(v)
    v=F.Plain(v)
    if type(v)=="number" and v==v and v~=math.huge and v~=-math.huge then return v end
end
function F.Table(v)
    v=F.Plain(v)
    if type(v)~="table" or (issecrettable and issecrettable(v)) then return nil end
    if canaccesstable and not canaccesstable(v) then return nil end
    return v
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
    self.faction=F.Plain(UnitFactionGroup("player"))
    self.class=F.Plain(select(2,UnitClass("player")))
    self.race=F.Plain(select(2,UnitRace("player")))
end
function F:Level() return F.Number(UnitLevel("player")) or 1 end
function F:GuideApplies(g)
    return g.faction==self.faction and self.Matches(g.races,self.race) and self.Matches(g.classes,self.class)
end
function F:Applies(s)
    if s.dungeon or not self.Matches(s.class,self.class) or not self.Matches(s.race,self.race) then return false end
    if s.quest and self.excluded and self.excluded[s.quest] then return false end
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
    local solo,dungeon={},{}
    self.excluded={}
    for _,g in ipairs(self.order) do
        if self:GuideApplies(g) then
            for _,s in ipairs(g.steps) do
                if s.accept and self.Matches(s.class,self.class) and self.Matches(s.race,self.race) then
                    for _,q in ipairs(s.ids) do
                        if s.dungeon then dungeon[q]=true else solo[q]=true end
                    end
                end
            end
        end
    end
    for q in pairs(dungeon) do if not solo[q] then self.excluded[q]=true end end
    for _=1,100 do
        local changed=false
        for _,g in ipairs(self.order) do if self:GuideApplies(g) then
            for _,s in ipairs(g.steps) do if s.accept and not s.dungeon then
                for _,req in ipairs(s.requires or {}) do
                    if self.excluded[req] then
                        for _,q in ipairs(s.ids) do if not self.excluded[q] then self.excluded[q]=true; changed=true end end
                    end
                end
            end end
        end end
        if not changed then break end
    end
end
function F:Turned(q) return call(C_QuestLog,"IsQuestFlaggedCompleted",q)==true or self.db.turned[q]==true end
function F:InLog(q)
    local i=F.Number(call(C_QuestLog,"GetLogIndexForQuestID",q))
    return i~=nil and i>0
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
        local text=F.Plain(o.text)
        if type(text)=="string" then
            for n,name in ipairs(names) do
                if text:lower():find(name:lower(),1,true) then
                    if F.Plain(o.finished)~=true then return false end
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
    self.guide=g; self.db.guide=id; self.inspect=nil; return true
end
function F:DefaultGuide()
    local best
    for _,g in ipairs(self.order) do
        if not g.side and self:GuideApplies(g) and g.levels[1]<=self:Level() and (not best or g.levels[1]>best.levels[1]) then best=g end
    end
    return best
end
function F:Current()
    if self.missingAPI then return nil end
    local g=self.guide
    if not g then return nil end
    if self.inspect then return g.steps[self.inspect] end
    for _=1,20 do
        local waiting
        for _,s in ipairs(g.steps) do
            if self:Applies(s) and not self:Done(s) then
                -- Level/item gates are deferred without recording completion; revisit every refresh.
                if self:Deferred(s,{}) then waiting=waiting or s else return s end
            end
        end
        if waiting then return waiting end
        local n=g.next and self.guides[g.next]
        if not n or not self:GuideApplies(n) then return nil end
        self:Select(n.id); g=n
    end
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
    local u=table.remove(self.db.undo)
    if u then self:Select(u.guide); self:MarkTable(self.guide)[u.index]=u.previous; self.inspect=u.index end
end
function F:Back()
    local s=self:Current(); if not s then return end
    for i=s.index-1,1,-1 do if self:Applies(s.owner.steps[i]) then self.inspect=i; return end end
end
function F:Bearing(pc,px,py,tc,tx,ty,facing)
    pc,tc=F.Number(pc),F.Number(tc)
    px,py,tx,ty,facing=F.Number(px),F.Number(py),F.Number(tx),F.Number(ty),F.Number(facing)
    if not pc or not tc or pc~=tc or not px or not py or not tx or not ty or not facing then return nil end
    local dx,dy=tx-px,ty-py
    local atan2=math.atan2
    if not atan2 then return nil end
    return (atan2(dy,dx)-facing)%(2*math.pi),math.sqrt(dx*dx+dy*dy)
end
function F:World(map,x,y)
    if not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return nil end
    local ok,c,v=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
    if not ok then return nil end
    c=F.Number(c); v=F.Plain(v)
    if not c or not v then return nil end
    local good,x,y=pcall(function() return v.x,v.y end)
    if not good then return nil end
    return c,F.Number(x),F.Number(y)
end
function F:Resolve(zone)
    if type(zone)=="number" then return zone end
    local map=self.ZoneIDs[zone]
    if map then return map end
    return self.learned and self.learned[zone]
end
function F:Offset(map,x,y)
    local pm=F.Number(call(C_Map,"GetBestMapForUnit","player"))
    if not pm then return nil end
    local pos=call(C_Map,"GetPlayerMapPosition",pm,"player")
    if not pos then return nil end
    local good,rawX,rawY=pcall(function() return pos.x,pos.y end)
    if not good then return nil end
    local px,py=F.Number(rawX),F.Number(rawY)
    if not px or not py or (px==0 and py==0) then return nil end
    local pc,wx,wy=self:World(pm,px,py)
    local tc,tx,ty=self:World(map,x,y)
    local facing=GetPlayerFacing and F.Number(GetPlayerFacing())
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
            local map=relevant and self:Resolve(a[3] or s.owner.zone)
            if map then
                local b,d=self:Offset(map,a[1]/100,a[2]/100)
                local r=a.r or 30
                if d and (not dist or d-r<dist-(radius or 0)) then angle,dist,radius=b,d,r end
            end
        end
        if dist then return angle,dist,radius end
    end
    if not at then return nil end
    local map=self:Resolve(at[3] or s.owner.zone)
    if map then return self:Offset(map,at[1]/100,at[2]/100) end
end
function F:Init()
    ForeverSprintCharDB=F.Table(ForeverSprintCharDB) or {}
    self.db=ForeverSprintCharDB
    if self.db.routeVersion~="BoostedXP-1.0.6" then self.db.marks={}; self.db.undo={}; self.db.routeVersion="BoostedXP-1.0.6" end
    self.db.marks=F.Table(self.db.marks) or {}; self.db.undo=F.Table(self.db.undo) or {}; self.db.turned=F.Table(self.db.turned) or {}
    for k,v in pairs(self.db.marks) do if type(k)~="string" or not F.Table(v) then self.db.marks[k]=nil end end
    self:Character(); self:SoloExclusions(); self.learned={}
    self.missingAPI=nil
    local required={"IsQuestFlaggedCompleted","GetLogIndexForQuestID","IsComplete","GetQuestObjectives","GetTitleForQuestID"}
    for _,name in ipairs(required) do
        if not C_QuestLog or type(C_QuestLog[name])~="function" then self.missingAPI="C_QuestLog."..name; break end
    end
    local map=call(C_Map,"GetBestMapForUnit","player")
    local info=map and call(C_Map,"GetMapInfo",map)
    if info and type(F.Plain(info.name))=="string" then self.learned[info.name]=map end
    if not self:Select(self.db.guide) then local g=self:DefaultGuide(); if g then self:Select(g.id) end end
end

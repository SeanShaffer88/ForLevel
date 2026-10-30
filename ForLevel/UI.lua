-- Selected mockup 04: compact charcoal/red quest list, with an integrated arrow.
local _,F=...
local w=CreateFrame("Frame","ForLevelWindow",UIParent,"BackdropTemplate")
w:SetSize(320,325); w:SetPoint("CENTER",UIParent,"CENTER",350,0)
w:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
w:SetBackdropColor(.035,.039,.043,.98); w:SetBackdropBorderColor(.14,.15,.16,1)
w:SetClampedToScreen(true); w:SetMovable(true); w:EnableMouse(true); w:RegisterForDrag("LeftButton")
w:SetScript("OnDragStart",w.StartMoving)
w:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    if F.db then local point,_,relative,x,y=self:GetPoint(); F.db.position={point,relative,x,y} end
end)
local function texture(parent,x,y,width,height,r,g,b)
    local t=parent:CreateTexture(nil,"BACKGROUND"); t:SetPoint("TOPLEFT",x,y); t:SetSize(width,height)
    t:SetColorTexture(r,g,b,1); return t
end
texture(w,0,0,320,2,.84,.18,.15)
texture(w,0,-50,320,1,.12,.13,.14)
texture(w,0,-128,320,1,.12,.13,.14)
texture(w,0,-269,320,1,.12,.13,.14)
local function font(parent,x,y,width,object,height)
    local t=parent:CreateFontString(nil,"OVERLAY",object or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    if height then t:SetHeight(height) end
    return t
end
local title=font(w,12,-13,116,"GameFontHighlightSmall",14); title:SetText("ForLevel")
local status=font(w,132,-13,176,"GameFontDisableSmall",14); status:SetJustifyH("RIGHT")
status:SetWordWrap(false)
local badge=font(w,12,-34,296,"GameFontHighlightSmall",12)
local ring=w:CreateTexture(nil,"ARTWORK"); ring:SetPoint("TOPLEFT",10,-59); ring:SetSize(54,54)
ring:SetTexture("Interface\\AddOns\\ForLevel\\Ring.tga")
local arrow=w:CreateTexture(nil,"OVERLAY"); arrow:SetPoint("TOPLEFT",21,-70); arrow:SetSize(32,32)
arrow:SetTexture("Interface\\AddOns\\ForLevel\\Arrow.tga")
local action=font(w,77,-61,229,"GameFontHighlightSmall",14)
local current=font(w,77,-79,229,"GameFontHighlight",29)
local meta=font(w,77,-111,229,"GameFontDisableSmall",14)
F.ui={window=w,arrow=arrow,ring=ring,status=status,badge=badge,action=action,current=current,meta=meta,rows={}}
local function tip(text,owner)
    w.tooltip=owner or w
    GameTooltip:SetOwner(w,"ANCHOR_RIGHT"); GameTooltip:SetText("ForLevel")
    GameTooltip:AddLine(text,1,1,1,true); GameTooltip:Show()
end
local function hideTip() w.tooltip=nil; GameTooltip:Hide() end
w:SetScript("OnEnter",function() if w.fullDetail then tip(w.fullDetail) end end)
w:SetScript("OnLeave",hideTip)
for i=1,5 do
    local row=CreateFrame("Button",nil,w); row:SetSize(318,27); row:SetPoint("TOPLEFT",1,-132-(i-1)*27)
    row.highlight=texture(row,0,0,318,27,.12,.125,.135)
    row.edge=texture(row,0,0,2,27,.84,.18,.15)
    row.number=font(row,10,-8,25,"GameFontDisableSmall",14)
    row.label=font(row,36,-8,272,"GameFontHighlightSmall",14)
    row.label:SetWordWrap(false)
    row:SetScript("OnEnter",function(self) if self.step then tip(F:Text(self.step).."\n"..(self.step.text or "").."\nClick to review; /forlevel resume continues the route.",self) end end)
    row:SetScript("OnLeave",hideTip)
    row:SetScript("OnClick",function(self) if self.step then F.inspect=self.step.index; F:Render() end end)
    F.ui.rows[i]=row
end
local function button(label,x,red,callback,help)
    local b=CreateFrame("Button",nil,w,"BackdropTemplate"); b:SetSize(93,28); b:SetPoint("TOPLEFT",x,-282)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(red and .77 or .09,red and .15 or .095,red and .12 or .10,1)
    b:SetBackdropBorderColor(red and .77 or .18,red and .15 or .19,red and .12 or .20,1)
    local text=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); text:SetPoint("CENTER"); text:SetText(label)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick",function(_,mouse) if F.db then callback(mouse); F:Render() end end)
    b:SetScript("OnEnter",function() tip(help,b) end); b:SetScript("OnLeave",hideTip)
    return b
end
F.ui.back=button("Back",11,false,function(mouse) if mouse=="RightButton" then F.inspect=nil else F:Back() end end,"Back reviews a previous step. Right-click resumes automatic progression.")
F.ui.skip=button("Skip",113,false,function() F:Manual("skip") end,"Record a reversible manual skip. /forlevel undo or right-click Done restores the last manual mark.")
F.ui.done=button("Done",215,true,function(mouse) if mouse=="RightButton" then F:Undo() else F:Manual("manual") end end,"Confirm this guide step manually; this does not complete an in-game quest. Right-click undoes the last manual mark.")
function F:HeaderStatus()
    local zone=self.Call(_G,"GetZoneText")
    if type(zone)~="string" or zone=="" then zone=self.guide and self.guide.zone or "Unknown zone" end
    local text=zone.." · Lv "..self:Level()
    local xp=self.Number(self.Call(_G,"UnitXP","player"))
    local maximum=self.Number(self.Call(_G,"UnitXPMax","player"))
    if xp and maximum and maximum>0 and xp>=0 then text=text..(" · %d%%"):format(math.min(100,math.floor(xp/maximum*100))) end
    return text
end
function F:Details(s)
    local lines={self:Text(s)}
    if self.inspect then lines[#lines+1]="Review mode: right-click Back or /forlevel resume to continue" end
    local blocked=self:Blocked(s); if blocked then lines[#lines+1]=blocked end
    if s.npc then lines[#lines+1]=s.npc end
    if s.text then lines[#lines+1]=s.text end
    for _,line in ipairs(self:Advisory(s)) do lines[#lines+1]=line end
    if s.kind=="complete" then
        for _,q in ipairs(self:IDs(s)) do if self:InLog(q) then
            for _,o in ipairs(self:Objectives(q)) do if self.Table(o) then
                local text=self.Read(o,"text")
                if type(text)=="string" then lines[#lines+1]=(self.Read(o,"finished")==true and "[done] " or "[ ] ")..text end
            end end
        end end
    end
    if s.at then lines[#lines+1]=(s.at[3] or s.owner.zone)..(" · %.1f, %.1f"):format(s.at[1],s.at[2]) end
    if s.nodungeon then lines[#lines+1]="Solo catch-up: grind to the displayed level." end
    if s.level then lines[#lines+1]="Current level: "..self:Level() end
    if s.kind=="die" then lines[#lines+1]="Optional death shortcut. Skip to avoid it." end
    if s.healer and self.ValidPoint(s.healer) then lines[#lines+1]=("Spirit healer: %s · %.1f, %.1f"):format(s.healer[3] or s.owner.zone,s.healer[1],s.healer[2]) end
    local prefix=s.owner.id..":"..s.index..":"
    for key,value in pairs(self.navigationWarnings or {}) do if key:sub(1,#prefix)==prefix then lines[#lines+1]=value; break end end
    if not s.ids and not s.level then lines[#lines+1]="Confirm with Done after performing this step." end
    return table.concat(lines,"\n")
end
function F:VisibleRows(s)
    local rows={}
    for i=s.index-1,1,-1 do if self:Applies(s.owner.steps[i]) then rows[1]=s.owner.steps[i]; break end end
    rows[#rows+1]=s
    for i=s.index+1,#s.owner.steps do
        local nextStep=s.owner.steps[i]
        if self:Applies(nextStep) and not self:Done(nextStep) then rows[#rows+1]=nextStep; if #rows==5 then break end end
    end
    return rows
end
function F:Render()
    if not self.db then return end
    local s=self:Current(); local g=self.guide
    if self.ui.lastStep~=s then hideTip(); self.ui.lastStep=s end
    status:SetText(self:HeaderStatus())
    badge:SetText(g and ((g.draft and "|cffe27265DRAFT ROUTE|r" or "Solo route")..(s and s.verify and " · Verify location" or "")..(self.inspect and " · Review" or "")) or "No matching route")
    local rows={}
    if not s then
        action:SetText(""); current:SetText(self.missingAPI and "Incompatible client API" or (self.routeError and "Route unavailable" or (g and "Chapter complete" or "Route unavailable")))
        meta:SetText(self.missingAPI and ("Missing "..self.missingAPI) or (self.routeError and "Broken chapter link · hover for details" or "/forlevel guides to select a route"))
        w.fullDetail=self.missingAPI and ("Missing "..self.missingAPI..". Verify the official Forever launch client.") or (self.routeError and (self.routeError..". Use /forlevel guides and /forlevel guide ID to select a valid route.") or "All routes are drafts. Use /forlevel guides to select a compatible route.")
        arrow:Hide(); ring:Hide()
    else
        ring:Show(); action:SetText("|cffe54236"..s.kind:upper().."|r")
        current:SetText(self:Text(s):match("^[^:]+:%s*(.*)$") or self:Text(s))
        w.fullDetail=self:Details(s)
        local blocked=self:Blocked(s); local angle,distance,radius=self:Target(s)
        if angle and distance then
            local arrived=distance<=(radius or s.radius or 12)
            if arrived then arrow:Hide() else arrow:SetRotation(angle); arrow:Show() end
            meta:SetText((s.npc or (s.at and (s.at[3] or g.zone)) or "Destination")..(arrived and " · Arrived" or (" · %d yd"):format(distance)))
        else arrow:Hide(); meta:SetText(blocked or "Direction unavailable · hover for details") end
        rows=self:VisibleRows(s)
    end
    for i,row in ipairs(self.ui.rows) do
        local step=rows[i]; local previous=row.step; row.step=step
        if step then
            if w.tooltip==row and previous~=step then hideTip() end
            row.number:SetText(("%02d"):format(step.index)); row.label:SetText(self:Text(step))
            if step==s then row.highlight:Show(); row.edge:Show() else row.highlight:Hide(); row.edge:Hide() end
            row:Show()
        else if w.tooltip==row then hideTip() end; row:Hide() end
    end
    if w.tooltip==w then tip(w.fullDetail) end
end
local event=CreateFrame("Frame")
for _,name in ipairs({"ADDON_LOADED","PLAYER_LOGIN","QUEST_LOG_UPDATE","QUEST_TURNED_IN","PLAYER_LEVEL_UP","PLAYER_XP_UPDATE","BAG_UPDATE_DELAYED","ZONE_CHANGED_NEW_AREA"}) do event:RegisterEvent(name) end
local elapsed=0
local function learnZone() F:LearnZone() end
event:SetScript("OnEvent",function(_,name,...)
    if name=="ADDON_LOADED" then
        if (...)~="ForLevel" then return end
        F:Init()
        local position=F.db.position
        if F.Table(position) and type(position[1])=="string" and type(position[2])=="string" and F.Number(position[3]) and F.Number(position[4]) then
            local ok=pcall(function() w:ClearAllPoints(); w:SetPoint(position[1],UIParent,position[2],position[3],position[4]) end)
            if not ok then w:ClearAllPoints(); w:SetPoint("CENTER") end
        end
        if F.db.hidden then w:Hide() end
    elseif not F.db then return
    elseif name=="PLAYER_LOGIN" then
        F:Character(); F:SoloExclusions(); learnZone()
        if not F.guide or not F:GuideApplies(F.guide) then
            if not F:Select(F.db.guide) then local g=F:DefaultGuide(); if g then F:Select(g.id) end end
        end
    elseif name=="QUEST_TURNED_IN" then
        local q=F.Integer((...),1,2147483647); if q then F.db.turned[q]=true end
    elseif name=="ZONE_CHANGED_NEW_AREA" then learnZone() end
end)
event:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<.2 then return end
    elapsed=0
    if F.db and w:IsShown() then F:Render() end
end)
local function say(text) DEFAULT_CHAT_FRAME:AddMessage("|cffe27265ForLevel:|r "..text) end
SLASH_FORLEVEL1="/forlevel"
SLASH_FORLEVEL2="/fl"
SlashCmdList.FORLEVEL=function(message)
    if not F.db then return end
    local cmd,arg=message:match("^(%S*)%s*(.-)$"); cmd=cmd:lower()
    if cmd=="" or cmd=="show" then w:Show(); F.db.hidden=false
    elseif cmd=="hide" then w:Hide(); F.db.hidden=true; hideTip()
    elseif cmd=="skip" then F:Manual("skip")
    elseif cmd=="done" then F:Manual("manual")
    elseif cmd=="undo" then F:Undo()
    elseif cmd=="back" then F:Back()
    elseif cmd=="resume" then F.inspect=nil
    elseif cmd=="guide" then if not F:Select(arg) then say("Unknown or incompatible guide ID.") end
    elseif cmd=="guides" then for _,g in ipairs(F.order) do if F:GuideApplies(g) then say(g.id..(g.side and " (class side route)" or "")..(g.draft and " [DRAFT]" or "")) end end
    elseif cmd=="find" then
        local q=tonumber(arg); local found=false
        for _,g in ipairs(F.order) do if F:GuideApplies(g) then for _,s in ipairs(g.steps) do
            if s.accept and F:Applies(s) then for _,id in ipairs(F:IDs(s)) do if id==q then F:Select(g.id); F.inspect=s.index; found=true; break end end end
            if found then break end
        end end; if found then break end end
        if not found then say("No compatible solo accept step found.") end
    else say("/forlevel show | hide | guides | guide ID | find QUESTID | back | resume | skip | done | undo") end
    F:Render()
end

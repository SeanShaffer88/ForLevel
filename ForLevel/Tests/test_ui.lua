-- Load the shipped UI against minimal frames and exercise actual event handlers.
local root=assert(arg[1],"Pass addon folder")
local F,frames={},{}
local count=0
local function check(v,msg) assert(v,msg); count=count+1 end
local Object={}
Object.__index=Object -- Unknown fields are nil; unknown method calls fail.
local function obj(kind) return setmetatable({kind=kind or "Frame",scripts={},events={},shown=true},Object) end
local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local scripts={OnDragStart=true,OnDragStop=true,OnClick=true,OnEnter=true,OnLeave=true,OnEvent=true,OnUpdate=true}
local function frame(self) assert(self.kind=="Frame" or self.kind=="Button","frame-only method") end
function Object:SetScript(k,fn) frame(self); assert(scripts[k] and (fn==nil or type(fn)=="function")); self.scripts[k]=fn end
function Object:RegisterEvent(k) self.events[k]=true end
function Object:CreateFontString() frame(self); return obj("FontString") end
function Object:CreateTexture() frame(self); return obj("Texture") end
function Object:SetText(t) self.text=t end
function Object:SetTexture(path) assert(self.kind=="Texture"); self.texture=path end
function Object:SetSize(width,height) self.size={width,height} end
function Object:SetPoint(point,...) assert(anchors[point],"invalid anchor"); self.point={point,...} end
function Object:ClearAllPoints() self.point=nil end
function Object:SetBackdrop(value) frame(self); self.backdrop=value end
function Object:SetBackdropColor(...) frame(self); self.bg={...} end
function Object:SetBackdropBorderColor(...) frame(self); self.border={...} end
function Object:SetClampedToScreen(v) frame(self); self.clamped=v end
function Object:SetMovable(v) frame(self); self.movable=v end
function Object:EnableMouse(v) frame(self); self.mouse=v end
function Object:RegisterForDrag(...) frame(self); self.dragButtons={...} end
function Object:RegisterForClicks(...) assert(self.kind=="Button"); self.clickButtons={...} end
function Object:StartMoving() frame(self); self.moving=true end
function Object:StopMovingOrSizing() frame(self); self.moving=false end
function Object:SetColorTexture(...) assert(self.kind=="Texture"); self.color={...} end
function Object:SetRotation(angle) assert(self.kind=="Texture" and type(angle)=="number"); self.rotation=angle end
function Object:SetWidth(value) self.width=value end
function Object:SetHeight(value) self.height=value end
function Object:SetJustifyH(value) assert(self.kind=="FontString"); self.justifyH=value end
function Object:SetJustifyV(value) assert(self.kind=="FontString"); self.justifyV=value end
function Object:SetWordWrap(value) assert(self.kind=="FontString"); self.wrap=value end
function Object:SetOwner(owner,anchor) self.owner=owner; self.anchor=anchor end
function Object:AddMessage(text) self.lastMessage=text end
function Object:AddLine(text) self.lastLine=text end
function Object:Show() self.shown=true end
function Object:Hide() self.shown=false end
function Object:IsShown() return self.shown end
function Object:GetPoint() return unpack(self.point or {"CENTER",UIParent,"CENTER",0,0}) end
CreateFrame=function(kind,name) assert(kind=="Frame" or kind=="Button"); local o=obj(kind); o.name=name; frames[#frames+1]=o; return o end
UIParent=obj(); GameTooltip=obj(); DEFAULT_CHAT_FRAME=obj(); SlashCmdList={}
local logged=false
UnitFactionGroup=function() return logged and "Alliance" or nil end
UnitClass=function() return logged and "Warrior" or nil, logged and "WARRIOR" or nil end
UnitRace=function() return logged and "Human" or nil, logged and "Human" or nil end
UnitLevel=function() return 1 end
GetPlayerFacing=function() return nil end
GetZoneText=function() return "Elwynn Forest" end
UnitXP=function() return 620 end
UnitXPMax=function() return 1000 end
C_Map={}
local log,turned={},{}
C_QuestLog={
 IsQuestFlaggedCompleted=function(q) return turned[q] or false end,
 GetLogIndexForQuestID=function(q) return log[q] and 1 or nil end,
 IsComplete=function() return false end,
 GetQuestObjectives=function() return {} end,
 GetTitleForQuestID=function(q) return "Quest "..q end,
}
C_Item={GetItemCount=function() return 0 end}
for line in assert(io.open(root.."ForLevel.toc")):lines() do
 if line~="" and line:sub(1,1)~="#" then assert(loadfile(root..line:gsub("\\","/")))("ForLevel",F) end
end
local event
for _,frame in ipairs(frames) do if frame.events.PLAYER_LOGIN then event=frame end end
check(event~=nil,"UI event frame created")
event.scripts.OnEvent(event,"ADDON_LOADED","OtherAddon")
check(F.db==nil,"unrelated addon load ignored")
event.scripts.OnEvent(event,"ADDON_LOADED","ForLevel")
check(frames[1].name=="ForLevelWindow","renamed frame identity")
check(F.ui.arrow.texture=="Interface\\AddOns\\ForLevel\\Arrow.tga","renamed arrow path")
check(F.ui.ring.texture=="Interface\\AddOns\\ForLevel\\Ring.tga","renamed ring path")
check(SLASH_FORLEVEL1=="/forlevel" and SLASH_FORLEVEL2=="/fl","both renamed command aliases registered")
local function dispatch(alias,message)
 for key,handler in pairs(SlashCmdList) do
  for i=1,10 do if _G["SLASH_"..key..i]==alias then handler(message); return true end end
 end
 return false
end
for _,alias in ipairs({"/forlevel","/fl"}) do
 check(dispatch(alias,"hide") and F.db.hidden==true,"alias hides: "..alias)
 check(dispatch(alias,"show") and F.db.hidden==false,"alias shows: "..alias)
end
check(F.guide==nil,"unavailable login identity does not select wrong route")
logged=true
event.scripts.OnEvent(event,"PLAYER_LOGIN")
check(F.guide and F.guide.id=="alliance-human-1-10","login identity selects human route")
check(F:Current().accept==783,"initial current step")
log[783]=true
event.scripts.OnEvent(event,"QUEST_LOG_UPDATE")
check(F:Current().turnin==783,"quest acceptance advances to turnin")
log[783]=nil
check(F:Current().accept==783,"abandonment resurfaces accept")
event.scripts.OnEvent(event,"QUEST_TURNED_IN",783)
check(F:Turned(783),"turnin event confirms completion")
event.scripts.OnUpdate(event,.2)
check(F.ui.window.size[1]==320 and F.ui.window.size[2]==325,"selected compact geometry")
check(#F.ui.rows==5,"five native list rows")
check(F.ui.status.text=="Elwynn Forest · Lv 1 · 62%","header uses actual XP")
check(F.ui.badge.text:find("DRAFT ROUTE",1,true)~=nil,"source draft badge visible")
local active=F:Current(); local activeRow
for _,row in ipairs(F.ui.rows) do
 if row.step==active then activeRow=row end
 check(row.point[3]<0 and -row.point[3]+row.size[2]<=269,"row stays within list bounds")
end
check(activeRow and activeRow.highlight:IsShown() and activeRow.edge:IsShown(),"current row highlight and red edge")
activeRow.scripts.OnEnter(activeRow)
check(GameTooltip.lastLine:find(F:Text(active),1,true)~=nil,"row hover exposes full quest text")
activeRow.scripts.OnClick(activeRow)
check(F.inspect==active.index,"click reviews actual numbered step")
F.ui.back.scripts.OnClick(F.ui.back,"RightButton")
check(F.inspect==nil,"right-click Back resumes")
F.ui.done.scripts.OnClick(F.ui.done,"LeftButton")
local markCount=#F.db.undo
F.ui.done.scripts.OnClick(F.ui.done,"RightButton")
check(#F.db.undo==markCount-1,"right-click Done undoes manual mark")
F.ui.window.scripts.OnEnter(F.ui.window)
check(type(GameTooltip.lastLine)=="string" and #GameTooltip.lastLine>0,"current-step hover details")
local SECRET={}
issecretvalue=function(v) return rawequal(v,SECRET) end
UnitXP=function() return SECRET end
check(not F:HeaderStatus():find("%%"),"secret XP suppresses percentage")
UnitXP=function() return 1 end; UnitXPMax=function() return 0 end
check(not F:HeaderStatus():find("%%"),"zero XP denominator safe")
for _,button in ipairs({F.ui.back,F.ui.skip,F.ui.done}) do
 check(button.point[3]==-282 and button.size[2]+282<=325,"footer button stays in bounds")
end
SlashCmdList.FORLEVEL("hide")
check(F.db.hidden==true and not frames[1]:IsShown(),"hide saved")
SlashCmdList.FORLEVEL("show")
check(F.db.hidden==false and frames[1]:IsShown(),"show restored")
frames[1]:SetPoint("CENTER",UIParent,"CENTER",10,20)
frames[1].scripts.OnDragStop(frames[1])
check(F.db.position[3]==10 and F.db.position[4]==20,"position saved")
SlashCmdList.FORLEVEL("skip")
local undo=#F.db.undo
SlashCmdList.FORLEVEL("undo")
check(#F.db.undo==undo-1,"UI undo invokes engine")
-- Saved state round-trip uses the actual same persisted table on a simulated reload.
F:Init()
check(F.db==ForLevelCharDB and F.db.turned[783],"saved character state reused")
ForLevelCharDB={marks="invalid",undo=false,turned="invalid",position={}}
F:Init(); check(type(F.db.marks)=="table" and type(F.db.undo)=="table","invalid saved fields repaired")
local old=C_QuestLog.IsComplete; C_QuestLog.IsComplete=nil
F:Init(); check(F.missingAPI=="C_QuestLog.IsComplete" and F:Current()==nil,"missing API suspends route")
C_QuestLog.IsComplete=old
F:Init(); check(F.missingAPI==nil and F:Current()~=nil,"restored API recovers")
check(obj().absentField==nil,"strict mock absent fields remain nil")
check(not pcall(function() obj():InventedMethod() end),"strict mock rejects unknown methods")
check(not pcall(function() obj("Texture"):SetBackdrop({}) end),"strict mock enforces widget kinds")
check(not pcall(function() obj():SetScript("InventedScript",function() end) end),"strict mock rejects invalid scripts")
check(not pcall(function() obj():SetPoint("InventedAnchor") end),"strict mock rejects invalid anchors")
F:Render()
local oldTarget=F.Target
F.Target=function() return math.pi/2,100 end
F:Render(); check(F.ui.arrow:IsShown() and F.ui.arrow.rotation==math.pi/2,"live bearing rotates integrated arrow")
F.Target=function() return nil end
F:Render(); check(not F.ui.arrow:IsShown(),"unavailable bearing hides arrow")
F.Target=oldTarget
F.ui.window.scripts.OnEnter(F.ui.window)
check(GameTooltip:IsShown(),"current tooltip open")
local live=F:Current(); F:Manual("skip"); F:Render()
check(not GameTooltip:IsShown() and F:Current()~=live,"automatic step change clears stale tooltip")
F.ui.window.scripts.OnEnter(F.ui.window)
local complete=C_QuestLog.IsComplete; C_QuestLog.IsComplete=nil
F:Render()
check(not GameTooltip:IsShown() and not F.ui.arrow:IsShown() and not F.ui.ring:IsShown(),"API loss clears stale tooltip and navigation")
for _,row in ipairs(F.ui.rows) do check(not row:IsShown() and row.step==nil,"API loss clears rows") end
C_QuestLog.IsComplete=complete; F:Render()
check(F:Current()~=nil and F.ui.rows[1]:IsShown(),"UI recovers from API loss without reload")
F.ui.window.scripts.OnEnter(F.ui.window)
F:Select("alliance-10-15"); F:Render()
check(not GameTooltip:IsShown(),"guide switch clears old tooltip")
F.ui.window.scripts.OnEnter(F.ui.window)
SlashCmdList.FORLEVEL("hide")
check(not GameTooltip:IsShown() and not F.ui.window:IsShown(),"hide closes tooltip")
SlashCmdList.FORLEVEL("show")
check(F.ui.window:IsShown(),"show restores current window")
for _,g in ipairs(F.order) do if not g.side and F:GuideApplies(g) then for _,step in ipairs(g.steps) do F:MarkTable(g)[step.index]="manual" end end end
F.ui.window.scripts.OnEnter(F.ui.window); F:Render()
check(not GameTooltip:IsShown() and not F.ui.arrow:IsShown(),"terminal state clears tooltip and arrow")
for _,row in ipairs(F.ui.rows) do check(not row:IsShown() and row.step==nil,"terminal state clears rows") end
-- Saved route selection must survive addon loading before character identity is ready.
ForLevelCharDB={routeVersion="BoostedXP-1.0.6",guide="alliance-15-20"}
logged=false; event.scripts.OnEvent(event,"ADDON_LOADED","ForLevel")
check(F.guide==nil and F.db.guide=="alliance-15-20","saved route retained while identity unknown")
logged=true; event.scripts.OnEvent(event,"PLAYER_LOGIN")
check(F.guide.id=="alliance-15-20","login restores saved compatible chapter")
for _,q in ipairs({0,-1,1.5,SECRET}) do event.scripts.OnEvent(event,"QUEST_TURNED_IN",q) end
check(not F.db.turned[0] and not F.db.turned[-1] and not F.db.turned[1.5] and not F.db.turned[SECRET],"invalid event quest IDs never create confirmed history")
for _,step in ipairs(F.guide.steps) do F:MarkTable(F.guide)[step.index]="manual" end
local nextGuide=F.guide.next; F.guide.next="missing-test-route"; F:Render()
check(F.ui.current.text=="Route unavailable" and F.ui.window.fullDetail:find("Missing next chapter",1,true),"broken next link never displays chapter complete")
check(not F.ui.arrow:IsShown(),"broken route hides navigation")
F.guide.next=nextGuide; F:Select("alliance-human-1-10"); F:Render()
check(F.routeError==nil and F.ui.current.text~="Route unavailable","valid selection restores UI after broken link")
print("PASS: "..count.." UI/event/save assertions (mock frames; not rendered)")

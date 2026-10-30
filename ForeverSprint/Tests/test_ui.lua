-- Load the shipped UI against minimal frames and exercise actual event handlers.
local root=assert(arg[1],"Pass addon folder")
local F,frames={},{}
local count=0
local function check(v,msg) assert(v,msg); count=count+1 end
local Object={}
Object.__index=function(t,k)
    if Object[k] then return Object[k] end
    return function() end
end
local function obj() return setmetatable({scripts={},events={},shown=true},Object) end
function Object:SetScript(k,fn) self.scripts[k]=fn end
function Object:RegisterEvent(k) self.events[k]=true end
function Object:CreateFontString() return obj() end
function Object:CreateTexture() return obj() end
function Object:SetText(t) self.text=t end
function Object:SetSize(width,height) self.size={width,height} end
function Object:SetPoint(...) self.point={...} end
function Object:AddLine(text) self.lastLine=text end
function Object:Show() self.shown=true end
function Object:Hide() self.shown=false end
function Object:IsShown() return self.shown end
function Object:GetPoint() return "CENTER",UIParent,"CENTER",10,20 end
CreateFrame=function() local o=obj(); frames[#frames+1]=o; return o end
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
for line in assert(io.open(root.."ForeverSprint.toc")):lines() do
 if line~="" and line:sub(1,1)~="#" then assert(loadfile(root..line:gsub("\\","/")))("ForeverSprint",F) end
end
local event
for _,frame in ipairs(frames) do if frame.events.PLAYER_LOGIN then event=frame end end
check(event~=nil,"UI event frame created")
event.scripts.OnEvent(event,"ADDON_LOADED","ForeverSprint")
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
SlashCmdList.FOREVERSPRINT("hide")
check(F.db.hidden==true and not frames[1]:IsShown(),"hide saved")
SlashCmdList.FOREVERSPRINT("show")
check(F.db.hidden==false and frames[1]:IsShown(),"show restored")
frames[1].scripts.OnDragStop(frames[1])
check(F.db.position[3]==10 and F.db.position[4]==20,"position saved")
SlashCmdList.FOREVERSPRINT("skip")
local undo=#F.db.undo
SlashCmdList.FOREVERSPRINT("undo")
check(#F.db.undo==undo-1,"UI undo invokes engine")
-- Saved state round-trip uses the actual same persisted table on a simulated reload.
F:Init()
check(F.db==ForeverSprintCharDB and F.db.turned[783],"saved character state reused")
ForeverSprintCharDB={marks="invalid",undo=false,turned="invalid",position={}}
F:Init(); check(type(F.db.marks)=="table" and type(F.db.undo)=="table","invalid saved fields repaired")
local old=C_QuestLog.IsComplete; C_QuestLog.IsComplete=nil
F:Init(); check(F.missingAPI=="C_QuestLog.IsComplete" and F:Current()==nil,"missing API suspends route")
C_QuestLog.IsComplete=old
F:Init(); check(F.missingAPI==nil and F:Current()~=nil,"restored API recovers")
print("PASS: "..count.." UI/event/save assertions (mock frames; not rendered)")

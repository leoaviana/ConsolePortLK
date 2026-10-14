unpack=unpack or table.unpack;tinsert=table.insert;tremove=table.remove
local native=assert(io.tmpfile())
local methods={Show=function()end,Hide=function()end,GetSize=function()return 1920,1080 end,HookScript=function()end,
 GetName=function(self)return self.name end,IsVisible=function()return true end,GetPoint=function()return 'CENTER' end}
UIParent=setmetatable({[0]=native},{__index=methods});UISpecialFrames={}
ConsolePort={};hooksecurefunc=function()end
local db={CPAPI={TimerAfter=function(_,fn)fn()end},table={unravel=function(t)local r={};for k in pairs(t)do r[#r+1]=k end;return unpack(r)end},KEY={UP='up',DOWN='down',LEFT='left',RIGHT='right'}}
assert(loadfile('ConsolePort/Drivers/UITracker.lua'))('ConsolePort',db)
assert(loadfile('ConsolePort/Drivers/UIStack.lua'))('ConsolePort',db)
assert(not ConsolePort:AddFrame(nil))
assert(not ConsolePort:AddFrame({}))
ConsolePort:AddFrameTracker(nil);ConsolePort:AddFrameTracker({})
assert(not ConsolePort:AddFrame('LaterWindow'))
LaterWindow=setmetatable({[0]=native,name='LaterWindow'},{__index=methods})
ConsolePort:UpdateFrameTracker();assert(ConsolePort:IsFrameVisibleToCursor(LaterWindow))
ConsolePort:ForbidFrame(LaterWindow);assert(not ConsolePort:IsFrameVisibleToCursor(LaterWindow))
ConsolePort:UnforbidFrame(LaterWindow);assert(ConsolePort:IsFrameVisibleToCursor(LaterWindow))
print('PASS: invalid frame inputs, deferred frame discovery, forbid/unforbid restores cursor tracking')
ConsolePortUI={};assert(loadfile('ConsolePort/Drivers/UINode.lua'))('ConsolePort',db)
local driver=ConsolePortUI:GetNodeDriver()
local missing={GetCenter=function()end,hasPriority=true}
local good={GetCenter=function()return 30,40 end}
local hidden={node=missing};local drawn={node=good}
driver.cache={hidden,drawn}
local c=driver:GetCandidatesForVector({x=0,y=0},function()return true end,{})
assert(c[drawn] and not c[hidden]);assert(not next(driver:GetCandidatesForVector({},function()error('must not compare')end,{})))
assert(driver:GetPriorityCandidate(0,0)==drawn)
assert(driver:GetBestCandidate(hidden,'up')==hidden)
assert(driver:GetClosestCandidate(hidden,'up')==hidden)
print('PASS: nil origin/destination coordinates and lost frame geometry safely skipped')
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end,Hide=function()end}end
assert(loadfile('ConsolePort/Init/Wrapper.lua'))('ConsolePort',db)
MAX_TALENT_TABS=3;NONE='None';GetActiveTalentGroup=function()return 1 end
GetTalentTabInfo=function(i)return 'Spec'..i,'Icon'..i,i*10 end
local sentinel1,sentinel2={},{};_G._=sentinel1;_G.specName=sentinel2
local id,name=db.CPAPI.GetSpecializationInfo(4)
assert(id==4 and name=='Spec3' and _G._==sentinel1 and _G.specName==sentinel2)
print('PASS: talent specialization lookup does not overwrite global variables')
native:close()

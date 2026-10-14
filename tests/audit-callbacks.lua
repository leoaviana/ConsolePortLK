unpack=table.unpack;tinsert=table.insert;tremove=table.remove
local hooks={};ConsolePort={OnNewBindings=function()end}
hooksecurefunc=function(_,method,fn)hooks[method]=fn end
assert(loadfile('ConsolePort/Core/Callback.lua'))()
local order,ownersSeen={},{}
local first=function(self)order[#order+1]='first';ownersSeen.first=self end
local second=function(self)order[#order+1]='second';ownersSeen.second=self end
ConsolePort:RegisterCallback('OnNewBindings',first)
local owner={}
ConsolePort:RegisterCallback('OnNewBindings',second,owner,1)
hooks.OnNewBindings(ConsolePort)
assert(table.concat(order,',')=='second,first' and ownersSeen.second==owner and ownersSeen.first==ConsolePort)
assert(ConsolePort:UnregisterCallback('OnNewBindings',second))
order={};hooks.OnNewBindings(ConsolePort);assert(#order==1 and order[1]=='first')
print('PASS: ordered callback registration, later owner resolution, and unregister')

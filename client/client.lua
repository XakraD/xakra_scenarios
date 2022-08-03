MenuData = {}


TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)


-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----------------- 		                	DATAVIEW FUNCTIONS				                  	-------------
-----------------									                                        	-------------
----------------- 		    BIG THNKS to gottfriedleibniz for this DataView in LUA.	          	-------------
----------------- https://gist.github.com/gottfriedleibniz/8ff6e4f38f97dd43354a60f8494eedff 	-------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

local _strblob = string.blob or function(length)
    return string.rep("\0", math.max(40 + 1, length))
end

DataView = {
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1", size = 1 },
        Uint8 = { code = "I1", size = 1 },
        Int16 = { code = "i2", size = 2 },
        Uint16 = { code = "I2", size = 2 },
        Int32 = { code = "i4", size = 4 },
        Uint32 = { code = "I4", size = 4 },
        Int64 = { code = "i8", size = 8 },
        Uint64 = { code = "I8", size = 8 },

        LuaInt = { code = "j", size = 8 }, 
        UluaInt = { code = "J", size = 8 }, 
        LuaNum = { code = "n", size = 8}, 
        Float32 = { code = "f", size = 4 },
        Float64 = { code = "d", size = 8 }, 
        String = { code = "z", size = -1, }, 
    },

    FixedTypes = {
        String = { code = "c", size = -1, },
        Int = { code = "i", size = -1, },
        Uint = { code = "I", size = -1, },
    },
}
DataView.__index = DataView
local function _ib(o, l, t) return ((t.size < 0 and true) or (o + (t.size - 1) <= l)) end
local function _ef(big) return (big and DataView.EndBig) or DataView.EndLittle end
local SetFixed = nil
function DataView.ArrayBuffer(length)
    return setmetatable({
        offset = 1, length = length, blob = _strblob(length)
    }, DataView)
end
function DataView.Wrap(blob)
    return setmetatable({
        offset = 1, blob = blob, length = blob:len(),
    }, DataView)
end
function DataView:Buffer() return self.blob end
function DataView:ByteLength() return self.length end
function DataView:ByteOffset() return self.offset end
function DataView:SubView(offset)
    return setmetatable({
        offset = offset, blob = self.blob, length = self.length,
    }, DataView)
end
for label,datatype in pairs(DataView.Types) do
    DataView["Get" .. label] = function(self, offset, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            local v,_ = string.unpack(_ef(endian) .. datatype.code, self.blob, o)
            return v
        end
        return nil
    end

    DataView["Set" .. label] = function(self, offset, value, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            return SetFixed(self, o, value, _ef(endian) .. datatype.code)
        end
        return self
    end
    if datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(fmt[#fmt]), datatype.size))
        return nil
    end
end
for label,datatype in pairs(DataView.FixedTypes) do
    DataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            local v,_ = string.unpack(code, self.blob, o)
            return v
        end
        return nil
    end
    DataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            return SetFixed(self, o, value, code)
        end
        return self
    end
end

SetFixed = function(self, offset, value, code)
    local fmt = { }
    local values = { }
    if self.offset < offset then
        local size = offset - self.offset
        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(self.offset, size)
    end
    fmt[#fmt + 1] = code
    values[#values + 1] = value
    local ps = string.packsize(fmt[#fmt])
    if (offset + ps) <= self.length then
        local newoff = offset + ps
        local size = self.length - newoff + 1

        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(newoff, self.length)
    end
    self.blob = string.pack(table.concat(fmt, ""), table.unpack(values))
    self.length = self.blob:len()
    return self
end

DataStream = { }
DataStream.__index = DataStream

function DataStream.New(view)
    return setmetatable({ view = view, offset = 0, }, DataStream)
end

for label,datatype in pairs(DataView.Types) do
    DataStream[label] = function(self, endian, align)
        local o = self.offset + self.view.offset
        if not _ib(o, self.view.length, datatype) then
            return nil
        end
        local v,no = string.unpack(_ef(endian) .. datatype.code, self.view:Buffer(), o)
        if align then
            self.offset = self.offset + math.max(no - o, align)
        else
            self.offset = no - self.view.offset
        end
        return v
    end
end
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
----------------- 									                                            ------------
-----------------		END OF DATAVIEW FUNCTIONS				                               	------------
----------------- 										                                        ------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

local VORPcore = {}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

RegisterNetEvent('xakra_scenarios:open_menu')
AddEventHandler('xakra_scenarios:open_menu', function()
    MenuData.CloseAll()
    local scenario_elements = {}
    local player = PlayerPedId()

    local DataStruct = DataView.ArrayBuffer(256 * 4)
    local is_data_exists = Citizen.InvokeNative(0x345EC3B7EBDE1CB5, GetEntityCoords(PlayerPedId()), 2.0, DataStruct:Buffer(), 10)
    if is_data_exists ~= false then
        for i = 1, is_data_exists, 1 do
            local scenario = DataStruct:GetInt32(8 * i)
            local scenario_hash = GetScenarioPointType(scenario)
            for _, v in pairs(Config.Scenarios) do
                if GetHashKey(v[1]) == scenario_hash then
                    scenario_elements[i] = {label = v[1], hash = scenario}
                end
            end
        end
        Citizen.Wait(200)


        MenuData.Open('default', GetCurrentResourceName(), 'menuapi', {
            title = Config.Texts["titleMenu"],
            subtext = Config.Texts["subtitleMenu"],
            align = "top-left",
            elements = scenario_elements,
    
        }, function(data, menu)
            ClearPedTasks(PlayerPedId())
            TaskUseScenarioPoint(PlayerPedId(), data.current.hash , "" , -1.0, true, false, 0, false, -1.0, true)
        end, function(data, menu)
            menu.close()
            ClearPedTasks(PlayerPedId())
            -- ClearPedTasksImmediately(PlayerPedId())

        end)
    else
        VORPcore.NotifyLeft(Config.Texts["NotifyTitle"],Config.Texts["NotifySubtitle"],"menu_textures", "cross",3000,"COLOR_PURE_WHITE")
    end

end)

function TaskStartScenarioInPlaceHash(ped, hash, p1, p2, p3, p4, p5)
    return Citizen.InvokeNative(0x524B54361229154F,ped, hash, p1, p2, p3, p4, p5)
end

function GetScenarioPointCoords(id, p1)
    return Citizen.InvokeNative(0xA8452DD321607029, id, p1)
end

function GetScenarioPointType(id)
    return Citizen.InvokeNative(0xA92450B5AE687AAF, id)
end

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
	end
    MenuData.CloseAll()
    if IsPedActiveInScenario(PlayerPedId()) then
        ClearPedTasksImmediately(PlayerPedId())
    end
end)

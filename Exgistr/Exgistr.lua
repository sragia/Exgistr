local db = {}
-- Defaults
local CHAR_ROW_DEFAULT = {
	key = "char",
	values = {
		name = "",
		realm = "",
		class = "",
		ledger = {},
		current = 0,
		startData = {},
	}
}
local LEDGER_ROW_DEFAULT = {
	key = "ledger",
	values = {
		amount = 0,
		type = "",
		date = 0,	
	},
}

local function AddMissingTableEntries(data,DEFAULT)
   if not data or not DEFAULT then return data end
   local rv = data
   for k,v in pairs(DEFAULT) do
      if rv[k] == nil then
         rv[k] = v
      elseif type(v) == "table" then
         rv[k] = AddMissingTableEntries(rv[k],v)
      end
   end
   return rv
end

-- DB Functions

local function ValidateRow(t,default)
	for key,v in pairs(default.values) do
		if not t[key] or not type(v) == type(t[key]) then
			Exgistr.debug.print("Row Validation false. For key",default.key)
			return false
		end
	end
	Exgistr.debug.print("Row Validation Successful. For key",default.key)
	return true
end

local function FindCharacter(name,realm)
	name = name or UnitName('player')
	realm = realm or GetRealmName()
	for id,char in pairs(db) do
		if char.name == name and char.realm == realm then
			return id
		end
	end
	return
end
Exgistr.FindCharacter = FindCharacter

local function AddCharacter(t)
	local id = #db+1
	if ValidateRow(t,CHAR_ROW_DEFAULT) then -- validate
		db[id] = t
		return id
	end
end

function Exgistr.SetupCharacter()
	local realm = GetRealmName()
	local name = UnitName("player")
	local _,class = UnitClass("player")
	local id = FindCharacter(name,realm)
	if not id then
		-- first time seeing this character
		return AddCharacter({
			name = name,
			realm = realm,
			class = class,
			ledger = {},
			current = Exgistr.CurrentMoney,
			startData = {
				gold = Exgistr.CurrentMoney,
				date = time()
			},
		})
	elseif db[id].current ~= Exgistr.CurrentMoney then
		Exgistr.AddTransaction({
				amount = Exgistr.CurrentMoney-db[id].current,
				type = "Unknown",
				date = time(),--date("*t", time()),
			})
		db[id].current = Exgistr.CurrentMoney
	end
end

local function compare(current,target,operator)
	if not current or not target then return false end
	operator = operator or "<"
	local ret = loadstring(string.format("return %f %s %f", current,operator,target))
	return ret()
end

function Exgistr.SelectLedgerData(charId,filter)
	-- filter = {
	--	key = "", value = "", compare = ">",
	-- }
	local ret = {}
	if charId == "all" then
		for id,char in pairs(db) do
			for i,data in ipairs(char.ledger) do
				if data[filter.key] then
          if compare(data[filter.key],filter.value,filter.compare) then
						table.insert(ret,data)
					end
				end
			end 
		end
	else
		for i,data in ipairs(db[charId].ledger) do
			if data[filter.key] then
				if compare(data[filter.key],filter.value,filter.compare) then
					table.insert(ret,data)
				end
			end
		end 
	end
	return ret
end

function Exgistr.GetCharacterInfo(charId) 
	if not db[charId] then return end
	local char = db[charId]
	local t = {
		name = char.name,
		realm = char.realm,
		class = char.class,
		current = char.current,
		startData = char.startData,
	}
	return t
end


-- LEDGER
function Exgistr.AddTransaction(t,name,realm)
	local id = FindCharacter(name,realm)
	if not id then
		id = Exgistr.SetupCharacter()
	end
	if ValidateRow(t,LEDGER_ROW_DEFAULT) then
		local tId = #db[id].ledger+1
		db[id].ledger[tId] = t
		db[id].current = db[id].current + t.amount
		Exgistr.debug.print("Adding row| Id:",tId," | Source:",t.type)
		Exgistr.CurrentMoney = db[id].current
		return tId
	end
	Exgistr.debug.print('failed Add')
end

function Exgistr.ModifyTransaction(id,key,newValue)
	local charId = FindCharacter()
	db[charId].ledger[id][key] = newValue
	Exgistr.debug.print("Modifing",id,"row:",key,"=",newValue)
end

function Exgistr.GetLedgerData(id)
	return db[id].ledger
end
function Exgistr.GetCharacterLedgers(filter)
	local ret = {}
	for id,char in pairs(db) do
		ret[char.realm] = ret[char.realm] or {}
		for i,l in ipairs(char.ledger) do
			if filter and l[filter.key] then
				if compare(l[filter.key],filter.value,filter.compare) then
					table.insert(ret[char.realm],l)
				end
			else
				table.insert(ret[char.realm],l)
			end
		end
	end
	return ret
end
-- GUI
function Exgistr.GetCharacters(realm)
	local t = {}
	for id,char in pairs(db) do
		if not realm or realm == char.realm then
			table.insert(t,{name = char.name,class= char.class, gold = char.current, id = id, realm = char.realm})
		end
	end
	return t
end

function Exgistr.GetRealms()
	local t = {}
	for id,char in pairs(db) do
		t[char.realm] = t[char.realm] and t[char.realm] + 1 or 1
	end
	return t
end
function Exgistr.GetCharacter(id)
	if not id or not db[id] then return end
	return db[id]
end

function Exgistr.GetInitTime()
	return Exgistr.config.initTime
end
-- DB SETUP
local function CheckDB()
	-- validates DB
	local t = db
	for id,char in pairs(db) do
		if type(char) ~= 'table' then 
			t[id] = nil
		else
			t[id] = AddMissingTableEntries(char,CHAR_ROW_DEFAULT.values)
			-- ledger
			for i,ledge in ipairs(char.ledger) do
				if not ValidateRow(ledge,LEDGER_ROW_DEFAULT) then
					t[id].ledger[i] = AddMissingTableEntries(t[id].ledger[i],LEDGER_ROW_DEFAULT.values)
				end
			end
		end
	end
	db = t
end

local function ModernizeDB()
  local t = db
  for id,char in pairs(db) do
    if type(char.startData.date) == "table" then
      t[id].startData.date = time(char.startData.date)
    end
    for i,l in ipairs(char.ledger) do
      if type(l.date) == "table" then
        t[id].ledger[i].date = time(l.date)
      end
    end
  end
  db = t
end

function Exgistr.InitDB()
  db = Exgistr.db
  ModernizeDB()
	CheckDB()
end

function Exgistr.GetDB()
  return db
end

function Exgistr.ClearDB()
	Exgistr.db = {}
	db = Exgistr.db
	Exgistr.SetupCharacter()
end

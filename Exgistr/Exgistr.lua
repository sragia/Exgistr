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
	}
}
local LEDGER_ROW_DEFAULT = {
	key = "ledger",
	values = {
		amount = 0,
		type = "",
		date = {},	
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
	local class = UnitClass("player")
	local id = FindCharacter(name,realm)
	if not id then
		-- first time seeing this character
		return AddCharacter({
			name = name,
			realm = realm,
			class = class,
			ledger = {},
			current = Exgistr.CurrentMoney
		})
	end
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
		Exgistr.debug.print("Adding",tId,"row | Type",t.type)
		Exgistr.CurrentMoney = db[id].current
		return tId
	end
end

function Exgistr.ModifyTransaction(id,key,newValue)
	local charId = FindCharacter()
	db[charId].ledger[id][key] = newValue
	Exgistr.debug.print("Modifing",id,"row:",key,"=",newValue)
end

function Exgistr.GetLedgerData(id)
	return db[id].ledger
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

function Exgistr.InitDB()
	db = Exgistr.db
	CheckDB()
end

function Exgistr.ClearDB()
	Exgistr.db = {}
	db = Exgistr.db
	Exgistr.SetupCharacter()
end

local name = ...
local function Init()
	-- setups start values
	Exgistr.InitDB()
	local money = GetMoney()
	Exgistr.CurrentMoney = money -- Current
	Exgistr.SessionStart = money -- Session Start
	Exgistr.SetupCharacter()
	Exgistr.name = UnitName("player")
	Exgistr.realm = GetRealmName()
	Exgistr.CreateTestGUI()
end

local f = CreateFrame("frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("MERCHANT_UPDATE")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")

local eventFunc = {}
local lastTransactionId
local transactionType
local function ClearTransactionVars()
	lastTransactionId = nil
	transactionType = nil
end

function f:OnEvent(event,...)
	if eventFunc[event] then
		eventFunc[event]()
		C_Timer.After(0.1,function() ClearTransactionVars() end)
	end
	if event == "ADDON_LOADED" and ... == name then
		Exgistr.db = ExgistrDB
		C_Timer.After(0.4,function() Init() end) -- delay a bit
		f:UnregisterEvent("ADDON_LOADED")
	end
	if event == "PLAYER_LOGOUT" then
		ExgistrDB = Exgistr.db
	end
end

f:SetScript("OnEvent", f.OnEvent)

function eventFunc.PLAYER_MONEY()
	local current = GetMoney()
	local diff = current - Exgistr.CurrentMoney
	if diff ~= 0 then
		local transType = transactionType or "Unknown"
		lastTransactionId = Exgistr.AddTransaction({
			amount = diff,
			type = transType,
			date = date("*t", time()),
		})
	end
	Exgistr.CurrentMoney = current
end

-- vendoring
function eventFunc.MERCHANT_UPDATE()
	-- PLAYER_MONEY Before
	if lastTransactionId then
		Exgistr.ModifyTransaction(lastTransactionId,"type","Vendor")
	else
		transactionType = "Vendor"
	end
end

-- repair
function eventFunc.UPDATE_INVENTORY_DURABILITY()
	if lastTransactionId then
		Exgistr.ModifyTransaction(lastTransactionId,"type","Repair")
	else
		transactionType = "Repair"
	end
end

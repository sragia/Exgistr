local name = ...
local LDBI = LibStub("LibDBIcon-1.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local function Init()
	-- setups start values
	Exgistr.InitDB()
	local money = GetMoney()
	Exgistr.CurrentMoney = money -- Current
	Exgistr.SessionStart = money -- Session Start
	Exgistr.SetupCharacter()
	Exgistr.name = UnitName("player")
	Exgistr.realm = GetRealmName()
	Exgistr.InitUI()
	--Exgistr.CreateTestGUI()
end

local f = CreateFrame("frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("MERCHANT_UPDATE")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
f:RegisterEvent("LOOT_SLOT_CLEARED")
f:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
f:RegisterEvent("QUEST_FINISHED")
f:RegisterEvent("QUEST_REMOVED")
f:RegisterEvent("MAIL_SEND_SUCCESS")
f:RegisterEvent("MAIL_SUCCESS")
local eventFunc = {}
local lastTransaction
local transactionType = {}
local unknownTransactions = {}
local function ClearTransactionVars()
	lastTransaction = nil
	transactionType = nil
end

local function GetTransactionType(diff)
	for key,trans in pairs(transactionType) do
		if GetTime() - trans.time <= (trans.delay or 1.5) then
			if trans.expense and diff < 0 then
				return trans.type
			elseif trans.income and diff > 0 then
				return trans.type
			end
		end
	end
	return diff > 0 and "Looted" or "Unknown"
end

local eventBucket = {}
local function Bucket(event,func)
	if not event then return end
	if eventBucket[event] then
		if GetTime() - eventBucket[event].time >= 0.5 then
			eventBucket[event].func()
			eventBucket[event] = nil
		end 
	elseif func then
		eventBucket[event] = {
			time = GetTime(),
			func = func
		}
		C_Timer.After(0.51,function() Bucket(event) end)
	end
end


local function PLAYER_MONEY()
	local current = GetMoney()
	local diff = current - Exgistr.CurrentMoney
	if diff ~= 0 then
		local transType = GetTransactionType(diff)
		local tId = Exgistr.AddTransaction({
			amount = diff,
			type = transType,
			date = date("*t", time()),
		})
		lastTransaction = {id = tId, time = GetTime()}
	end
	Exgistr.CurrentMoney = current
end


function f:OnEvent(event,...)
	if eventFunc[event] then
		Exgistr.debug.print(event,'happened')
		eventFunc[event]()
	end
	if event == "PLAYER_MONEY" then
		Bucket(event,PLAYER_MONEY)
	end
	if event == "ADDON_LOADED" and ... == name then
		Exgistr.db = ExgistrDB.db or {}
		Exgistr.config = ExgistrDB.config or {}
		Exgistr.config.minimap = Exgistr.config.minimap or {}
		Exgistr.config.initTime = Exgistr.config.initTime or time()
		C_Timer.After(0.4,function() Init() end) -- delay a bit
		LDBI:Register("Exgistr",{
		  type = "data source",
		  text = "Exgistr",
		  icon = "Interface\\AddOns\\Exgistr\\Media\\logo",
		  OnClick = function() Exgistr.ShowUI() end,
		},Exgistr.config.minimap)
		f:UnregisterEvent("ADDON_LOADED")
	end
	if event == "PLAYER_LOGOUT" then
		ExgistrDB.db = Exgistr.db
		ExgistrDB.config = Exgistr.config
	end
end

f:SetScript("OnEvent", f.OnEvent)

-- vendoring
function eventFunc.MERCHANT_UPDATE()
	local key = "MERCHANT_UPDATE"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type","Vendor")
	else
		transactionType[key] = {type = "Vendor", time = GetTime(), income = true}
	end
end

-- repair
function eventFunc.UPDATE_INVENTORY_DURABILITY()
	local key = "UPDATE_INVENTORY_DURABILITY"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type","Repair")
	else
		transactionType[key] = {type = "Repair", time = GetTime(), expense = true}
	end
end

function eventFunc.LOOT_SLOT_CLEARED()
	local key = "LOOT_SLOT_CLEARED"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type","Looted")
	else
		transactionType[key] = {type = "Looted", time = GetTime(), income = true}
	end
end

function eventFunc.GARRISON_MISSION_COMPLETE_RESPONSE()
	local key = "GARRISON_MISSION_COMPLETE_RESPONSE"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type","Mission")
	else
		transactionType[key] = {type = "Mission", time = GetTime(), income = true, delay = 2.5}
	end
end

function eventFunc.AUCTION_ITEM_LIST_UPDATE()
	local key = "AUCTION_ITEM_LIST_UPDATE"
	local type = "Auction"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type",type)
	else
		transactionType[key] = {type = type, time = GetTime(), expense = true, delay = 2.5}
	end
end
function eventFunc.QUEST_FINISHED()
	local key = "QUEST_FINISHED"
	local type = "Quest"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type",type)
	else
		transactionType[key] = {type = type, time = GetTime(), income = true}
	end
end

function  eventFunc.QUEST_REMOVED()
	local key = "QUEST_REMOVED"
	local type = "Quest"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type",type)
	else
		transactionType[key] = {type = type, time = GetTime(), income = true}
	end
end

function  eventFunc.MAIL_SEND_SUCCESS()
	local key = "MAIL_SEND_SUCCESS"
	local type = "Mail"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type",type)
	else
		transactionType[key] = {type = type, time = GetTime(), expense = true}
	end
end

function  eventFunc.MAIL_SUCCESS()
	local key = "MAIL_SUCCESS"
	local type = "Mail"
	if lastTransaction and GetTime() - lastTransaction.time <= 0.1 then
		Exgistr.ModifyTransaction(lastTransaction.id,"type",type)
	else
		transactionType[key] = {type = type, time = GetTime(), income = true}
	end
end
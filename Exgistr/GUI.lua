local addon = ...

local AceGUI = LibStub("AceGUI-3.0")

function Exgistr.CreateTestGUI()
	-- Create a container frame
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("AceGUI-3.0 Example")
	f:SetStatusText("Status Bar")
	f:SetLayout("Flow")
	-- Create a button
	local charId = Exgistr.FindCharacter("Exality","Silvermoon") -- test
	if charId then
		local ledgerData = Exgistr.GetLedgerData(charId)
		for tId,data in ipairs(ledgerData) do
			local label = AceGUI:Create("Label")
			label:SetFullWidth(true)
			local d = data.date
			local sign = data.amount > 0 and "+" or "-"
			local str = string.format("%i/%i/%i %02d:%02d   Type: %s  Amount: %s%s",d.day,d.month,d.year,d.hour,d.min,data.type,sign,GetMoneyString(math.abs(data.amount)))
			label:SetText(str)
			f:AddChild(label)
		end
	end
end
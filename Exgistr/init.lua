ExgistrDB = {}
Exgistr = {
	db = {}
}
-- debug
Exgistr.debug = {
	enabled = false,
	label = "|cffeef441[Exgistr]|r",
	print = function(...)
		if Exgistr.debug.enabled then
			print(Exgistr.debug.label,...)
		end
	end,
}

Exgistr.defaultSources = {
	{text = "All", value = "All"},
	{text = "Unknown", value = "Unknown"},
	{text = "Vendor", value = "Vendor"}, -- implemented
	{text = "Mission", value = "Mission"}, -- implemented
	{text = "Repair", value = "Repair"}, -- implemented
	{text = "Auction", value = "Auction"},
	{text = "Trade", value = "Trade"},
	{text = "Looted", value = "Looted"}, -- kinda implemented
	{text = "Quest", value = "Quest"},
	{text = "Mail", value = "Mail"},
}

SLASH_CHAREXG1, SLASH_CHAREXG2 = '/EXG', '/Exgistr'; -- 3.
function SlashCmdList.CHAREXG(msg, editbox) -- 4.
  local args = {strsplit(" ",msg)}
  if args[1] == "" then
  Exgistr.ShowUI()
  elseif args[1] == "debug" then
  	Exgistr.debug.enabled = not Exgistr.debug.enabled
  end
end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

Exgistr.LDB_Exgistr = LDB:NewDataObject("Exgistr",{
  type = "data source",
  text = "Exgistr",
  icon = "Interface\\AddOns\\Exgistr\\Media\\logo",
  OnClick = function() Exgistr.ShowUI() end,
})

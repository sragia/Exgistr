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
Exgistr.CheckData = function()
	ViragDevTool_AddData(Exgistr.db)
end
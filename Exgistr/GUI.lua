local addon = ...

local function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a, b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

local ShortenNumber = function(number)
    if type(number) ~= "number" then
        number = tonumber(number)
    end
    if not number then
        return
    end
    local affixes = {
        "",
        "k",
        "m",
        "b",
        "t",
    }
    local affix = 1
    local dec = 0
    local num1 = math.abs(number)
    while num1 >= 1000 and affix < #affixes do
        num1 = num1 / 1000
        affix = affix + 1
    end
    if affix > 1 then
        dec = 3
        local num2 = num1
        while num2 >= 10 and dec > 0 do
            num2 = num2 / 10
            dec = dec - 1
        end
    end
    if number < 0 then
        num1 = -num1
    end
    
    return string.format("%."..dec.."f"..affixes[affix], num1)
end

local timeKeys = {
	hour = {"hour",":","min"},
	day = {"hour",":", "min"},
	week = {"day","/", "month"},
	month = {"day","/", "month"},
	year = {"month","/","year"}
}
local timeLimits = {
	["min"] = 60,
	["hour"] = 3600,
	["day"] = 86400,
	["week"] = 604800,
	["month"] = 18144000,
}
local function IsDateInLimit(dateCheck,limit)
	local timeNow = time()
	local dateTime = time(dateCheck)
	if timeLimits[limit] then
		return (timeNow - timeLimits[limit]) <= dateTime
	end
	return false
end

local function TimeAgo(timePast)
	local timeNow = time()
	local ret = {
		min = math.floor((timeNow - timePast)/ 60),
		hours = math.floor((timeNow - timePast)/ 3600),
		days = math.floor((timeNow - timePast)/ 86400),
		months = math.floor((timeNow - timePast)/ 18144000),
	}
	return ret
end

local StdUi = LibStub('StdUi'):NewInstance()
StdUi.config = {
    font      = {
		familly       = [[Interface\AddOns\Exgistr\Media\font.ttf]], -- Font used across your addon
		size          = 12, -- Font size
		titleSize     = 12, 
		effect        = 'OUTLINE', -- Font effects
		strata        = 'OVERLAY', -- Font strata
		color         = { r = 1, g = 1, b = 1, a = 1 }, -- Font text color
		colorDisabled = { r = 0.55, g = 0.55, b = 0.55, a = 1 }, -- Font color when widget is disabled
	},
	backdrop  = {
		texture        = [[Interface\Buttons\WHITE8X8]], -- Backdrop texture
		panel          = { r = 0, g = 0, b = 0, a = .7 }, -- Color of panels
		slider         = { r = 0, g =0, b = 0, a = .7 }, -- Color of sliders

		button         = { r = 0.25, g = 0.25, b = 0.25, a = .7 }, -- Button color
		buttonDisabled = { r = 0.15, g = 0.15, b = 0.15, a = .7 }, -- Button color when disabled
		line           = { r = 1,    g = 1, b = 1, a = .4},
		lineBorder	   = { r = 1, g  = 1, b = 1, a = .4 },
		graphBg = { r = 1, g = 1, b = 1, a = .05	},
		graphBgBorder = { r = 1, g = 1, b = 1, a = 0},
		border         = { r = 0.16, g = 0.16, b = 0.16, a = 1 }, -- Border color
		borderDisabled = { r = 0.16, g = 0.16, b = 0.16, a = 1 } -- Border color when disabled
	},

	highlight = {
		color = { r = 1, g = 0.9, b = 0, a = 0.4 }, -- Highlight color
		blank = { r = 0, g = 0, b = 0, a = 0 } -- Highlight 'off' color
	},

	dialog    = { -- Dialog settings
		width  = 400, -- Dialogs default width
		height = 100, -- Dialogs default height
		button = {
			width  = 100, -- Dialog button width
			height = 20, -- Dialog button height
			margin = 5 -- Dialog margin between buttons
		}
	},

	tooltip   = {
		padding = 10 -- Frame tooltip padding
	}
}

local function SetMoneyString(self,money)
	local sign = ""
	if money < 0 then
		sign = "-"
	end
		self:SetText(sign..StdUi.Util.formatMoney(math.abs(money)))
end

local function CreateMoneyText(parent,label,textSize)
	local textLabel = StdUi:FontString(parent,label)
	textLabel:SetFontSize(textSize)
	local text = StdUi:FontString(parent,"")
	text.SetMoneyString = SetMoneyString
	text:SetFontSize(textSize)
	return textLabel,text
end

local function CreateLine(parent)
	local line = parent:CreateTexture(nil, "OVERLAY")
	line:SetTexture([[Interface\AddOns\Exgistr\Media\line]])
	line:SetVertexColor(1,1,1,1)
  return line
end

-- From TSM
local function ExgDrawLine(line,parent,xFrom, yFrom, xTo, yTo, thickness,startAnchor)
	local textureHeight = thickness * 16
	local xDiff = xTo - xFrom
	local yDiff = yTo - yFrom
	local length = math.sqrt(xDiff * xDiff + yDiff * yDiff)
	local sinValue = -yDiff / length
	local cosValue = xDiff / length
	local aspectRatio = length / textureHeight
	local invAspectRatio = textureHeight / length

	-- calculate and set tex coords
	local LLx, LLy, ULx, ULy, URx, URy, LRx, LRy
	if yDiff >= 0 then
		ULx = sinValue * sinValue
		ULy = 1 - aspectRatio * sinValue * cosValue
		LLx = invAspectRatio * sinValue * cosValue
		LLy = sinValue * sinValue
		URx = 1 - invAspectRatio * sinValue * cosValue
		URy = 1 - sinValue * sinValue
		LRx = 1 - sinValue * sinValue
		LRy = aspectRatio * sinValue * cosValue
	else
		LLx = sinValue * sinValue
		LLy = -aspectRatio * sinValue * cosValue
		LRx = 1 + invAspectRatio * sinValue * cosValue
		LRy = LLx
		ULx = 1 - LRx
		ULy = 1 - LLx
		URy = 1 - LLy
		URx = ULy
	end
	line:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)

	-- calculate and set texture anchors
	local xCenter = (xFrom + xTo) / 2
	local yCenter = (yFrom + yTo) / 2
	local halfWidth = (xDiff + invAspectRatio * math.abs(yDiff) + thickness) / 2
	local halfHeight = (math.abs(yDiff) + invAspectRatio * xDiff + thickness) / 2
	line:SetPoint("BOTTOMLEFT", parent, startAnchor, xCenter - halfWidth, yCenter - halfHeight)
	line:SetPoint("TOPRIGHT", parent, startAnchor, xCenter + halfWidth, yCenter + halfHeight)

	return line
end



local UI = StdUi:Window(nil, 'Exgistr', 700, 500)
UI.titlePanel:ClearAllPoints()
UI.titlePanel:SetPoint("BOTTOMLEFT", UI, "TOPLEFT", 0, -1)
UI.titlePanel:SetPoint("BOTTOMRIGHT", UI, "TOPRIGHT", 0, -1)

-- char frame
function UI:InitCharUI()
	self.charWindow = self.charWindow or StdUi:PanelWithTitle(UI, 260, 500,'Characters',100,20)
	local charWindow = self.charWindow
	charWindow.titlePanel:ClearAllPoints()
	charWindow.titlePanel:SetPoint("BOTTOMLEFT", charWindow, "TOPLEFT", 0, -1)
  charWindow.titlePanel:SetPoint("BOTTOMRIGHT", charWindow, "TOPRIGHT", 0, -1)
	StdUi:GlueBefore(charWindow,self,1,0,1,0)
	function charWindow:RefreshData()
		local allData = Exgistr.GetCharacters()
		local realmData = {}
		local totalGold,realmGold = 0,0
		local topChar = {id = 0, value = 0,realRow = 0}
		for i,char in ipairs(allData) do
			totalGold = totalGold + char.gold
			if char.realm == self.selectedRealm then
				realmGold = realmGold + char.gold
				local row = #realmData + 1
				topChar = topChar.value > char.gold and topChar or {id = char.id, value = char.gold, realRow = row}
				realmData[row] = char
			end
		end
		if not UI.charId then
			UI.charId = topChar.id
			self.charTable:SetSelection(topChar.realRow)
		end
		UI.realmGold = realmGold
		UI.totalGold = totalGold
		self.realmGold:SetText(string.format("Realm: %s", StdUi.Util.formatMoney(realmGold)))
		self.totalGold:SetText(string.format("Total: %s", StdUi.Util.formatMoney(totalGold)))
		self.charTable:SetData(realmData)
		self.charTable:SortData(2) -- sort by gold
	end

	-- char table
	local charTable = charWindow.charTable or StdUi:ScrollTable(charWindow, {{
			name = 'Character', 
			width = 100, 
			align = 'CENTER', 
			index = 'name', 
			format = 'text', 
			sortable = false, 
			events = {
				OnMouseDown = function(tableFrame, cellFrame,rowFrame, data, colOption, row, button )
					self.charId = data.id
					self:RefreshData()
				end, 
			},
		},
		{
			name = 'Gold', -- Header text
			width = 100, -- Width of a column
			align = 'CENTER', -- Align of text in cell (it does NOT affect header text alignment)
			index = 'gold', -- Data index of cell
			format = 'money', -- Defines how ScrollTable should display cells in this column - explained below 
			sortable = false, -- If this is set to false, column will not be sortable
			events = {
				OnMouseDown = function(tableFrame, cellFrame,rowFrame, data, colOption, row, button )
					self.charId = data.id
					self:RefreshData()
				end, 
			},
		}}, 13, 20)
	charTable.scrollFrame:SetClampedToScreen(false)
	charTable:EnableSelection(true)
	StdUi:GlueAcross(charTable, charWindow, 10, -60, -10, 45)
	charWindow.charTable = charTable

	-- realm dropdown
	local realms = Exgistr.GetRealms()
	local selectedRealm
	local options = {}
	for realm,count in spairs(realms,function(t,a,b) return t[a] > t[b] end) do
		if not selectedRealm then selectedRealm = realm end
		table.insert(options,{text = realm, value = realm})
	end
	self.realmSelect = self.realmSelect or StdUi:Dropdown(charWindow,240,20,options,selectedRealm)
	local realmSelect = self.realmSelect
	StdUi:GlueTop(realmSelect,charWindow,10,-15,"LEFT")
	charWindow.selectedRealm = selectedRealm
	realmSelect.OnValueChanged = function(dropdown, value, text)
		charWindow.selectedRealm = value
		self.charId = nil
		charWindow:RefreshData()
		self:RefreshData()
	end

	-- Realm Gold
	local realmString = charWindow.realmGold or StdUi:FontString(charWindow,"Realm:")
	charWindow.realmGold = realmString
	realmString:SetFontSize(13)
	StdUi:GlueBottom(realmString,charWindow,10,25,'LEFT')

	-- Total account gold
	local totalString = charWindow.totalGold or StdUi:FontString(charWindow,"Total:")
	charWindow.totalGold = totalString
	totalString:SetFontSize(13)
	StdUi:GlueBottom(totalString,charWindow,10,10,'LEFT')

	-- refresh Data
	charWindow:RefreshData()
end

-- Character Panel
function UI:DrawCharacterPanel()
	self.charPanel = self.charPanel or StdUi:Panel(self,330,100)
	local charPanel = self.charPanel
	StdUi:GlueTop(charPanel,self,10,-20,'LEFT')
	-- Char Name
	local charName = charPanel.charName or StdUi:FontString(charPanel,"Name")
	charPanel.charName = charName
	charName:SetFontSize(25)
	StdUi:GlueTop(charName,charPanel,10,-10,'LEFT')
	-- Current Gold
	local currGoldLabel,currGold = CreateMoneyText(charPanel,"Current Gold:",13)
	charPanel.currGold = currGold
	StdUi:GlueTop(currGoldLabel,charName,0,-30,'LEFT')
	StdUi:GlueAfter(currGold,currGoldLabel,5,0,5,0)
	-- Made Last Week
	local goldLastWeekLabel,goldLastWeek = CreateMoneyText(charPanel,"Gold This Week:",13)
	charPanel.goldLastWeek = goldLastWeek
	StdUi:GlueTop(goldLastWeekLabel,currGoldLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldLastWeek,goldLastWeekLabel,5,0,5,0)
	-- Made Last Month
	local goldLastMonthLabel,goldLastMonth = CreateMoneyText(charPanel,"Gold This Month:",13)
	charPanel.goldLastMonth = goldLastMonth
	StdUi:GlueTop(goldLastMonthLabel,goldLastWeekLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldLastMonth,goldLastMonthLabel,5,0,5,0)
	-- TEST
	currGold:SetMoneyString(123456)
	goldLastWeek:SetMoneyString(123456)
	goldLastMonth:SetMoneyString(123456)
end

-- Totals for character
function UI:DrawCharTotalPanel()
	self.totalPanel = self.totalPanel or StdUi:Panel(self,330,100)
	local totalPanel = self.totalPanel
	StdUi:GlueBelow(totalPanel,self.charPanel,0,-5,'LEFT')
	-- TOTALS
	local totalsString = StdUi:FontString(totalPanel,"Character Totals")
	totalsString:SetFontSize(25)
	StdUi:GlueTop(totalsString,totalPanel,10,-10,'LEFT')
	-- Expense Total
	local expenseTotalLabel,expenseTotal = CreateMoneyText(totalPanel,"Expense:",13)
	totalPanel.expenseTotal = expenseTotal
	StdUi:GlueTop(expenseTotalLabel,totalsString,0,-30,'LEFT')
	StdUi:GlueAfter(expenseTotal,expenseTotalLabel,5,0,5,0)
	-- Income Total
	local incomeTotalLabel,incomeTotal = CreateMoneyText(totalPanel,"Income:",13)
	totalPanel.incomeTotal = incomeTotal
	StdUi:GlueTop(incomeTotalLabel,expenseTotalLabel,0,-18,'LEFT')
	StdUi:GlueAfter(incomeTotal,incomeTotalLabel,5,0,5,0)
	-- Profit Total
	local profitTotalLabel,profitTotal = CreateMoneyText(totalPanel,"Profit:",13)
	totalPanel.profitTotal = profitTotal
	StdUi:GlueTop(profitTotalLabel,incomeTotalLabel,0,-18,'LEFT')
	StdUi:GlueAfter(profitTotal,profitTotalLabel,5,0,5,0)
end

-- Totals for Account
function UI:DrawAccountTotalPanel()
	self.acctotalPanel = self.acctotalPanel or StdUi:Panel(self,335,100)
	local acctotalPanel = self.acctotalPanel
	StdUi:GlueAfter(acctotalPanel,self.charPanel,5,0)
	-- TOTALS
	local acctotalsString = StdUi:FontString(acctotalPanel,"Account Totals")
	acctotalsString:SetFontSize(25)
	StdUi:GlueTop(acctotalsString,acctotalPanel,10,-10,'LEFT')
	-- Current Gold
	local currGoldLabel,currGold = CreateMoneyText(acctotalPanel,"Current Gold:",13)
	acctotalPanel.currGold = currGold
	StdUi:GlueTop(currGoldLabel,acctotalsString,0,-30,'LEFT')
	StdUi:GlueAfter(currGold,currGoldLabel,5,0,5,0)
	-- Made Last Week
	local goldLastWeekLabel,goldLastWeek = CreateMoneyText(acctotalPanel,"Gold This Week:",13)
	acctotalPanel.goldLastWeek = goldLastWeek
	StdUi:GlueTop(goldLastWeekLabel,currGoldLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldLastWeek,goldLastWeekLabel,5,0,5,0)
	-- Made Last Month
	local goldAvgLabel,goldAvg = CreateMoneyText(acctotalPanel,"Average per Day :",13)
	acctotalPanel.goldAvg = goldAvg
	StdUi:GlueTop(goldAvgLabel,goldLastWeekLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldAvg,goldAvgLabel,5,0,5,0)
end

-- Totals for Realm
function UI:DrawRealmTotalPanel()
	self.realmtotalPanel = self.realmtotalPanel or StdUi:Panel(self,335,100)
	local realmtotalPanel = self.realmtotalPanel
	StdUi:GlueBelow(realmtotalPanel,self.acctotalPanel,0,-5,'LEFT')
	-- TOTALS
	local realmtotalsString = StdUi:FontString(realmtotalPanel,"Realm Totals")
	realmtotalsString:SetFontSize(25)
	StdUi:GlueTop(realmtotalsString,realmtotalPanel,10,-10,'LEFT')
	-- Current Gold
	local currGoldLabel,currGold = CreateMoneyText(realmtotalPanel,"Current Gold:",13)
	realmtotalPanel.currGold = currGold
	StdUi:GlueTop(currGoldLabel,realmtotalsString,0,-30,'LEFT')
	StdUi:GlueAfter(currGold,currGoldLabel,5,0,5,0)
	-- Made Last Week
	local goldLastWeekLabel,goldLastWeek = CreateMoneyText(realmtotalPanel,"Gold Last Week:",13)
	realmtotalPanel.goldLastWeek = goldLastWeek
	StdUi:GlueTop(goldLastWeekLabel,currGoldLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldLastWeek,goldLastWeekLabel,5,0,5,0)
	-- Made Last Month
	local goldAvgLabel,goldAvg = CreateMoneyText(realmtotalPanel,"Average per Day :",13)
	realmtotalPanel.goldAvg = goldAvg
	StdUi:GlueTop(goldAvgLabel,goldLastWeekLabel,0,-18,'LEFT')
	StdUi:GlueAfter(goldAvg,goldAvgLabel,5,0,5,0)
end

-- GRAPH 
function UI:DrawGraph()
	self.graph = self.graph or StdUi:Panel(self,330,100)
	local graph = self.graph
	graph:SetPoint("TOPLEFT",self.realmtotalPanel,"BOTTOMLEFT",0,-40)
	graph:SetPoint("BOTTOMRIGHT",self.table,"BOTTOMRIGHT",340,0)
	graph.warning = StdUi:Label(graph,"",30)
	graph.warning:SetPoint("CENTER",graph,0,0)
	local lineCount = 20
	local verticalLines = 7
	local graphHeight = 180 -- shouldnt change
	local graphWidth = 315  -- shouldnt change
	local lineWidth = graphWidth/lineCount
	-- Background
	graph.bg = {}
	local bgCount = math.floor(lineCount/2)
	for i=1,bgCount do
		local f = StdUi:Frame(graph,31,40)
		graph.bg[i] = f
		f:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", 10+lineWidth+(i-1)*lineWidth*2,20)--   41.5+(i-1)*63, 20)
		f:SetPoint("TOPRIGHT",graph, "TOPLEFT",10+2*lineWidth+(i-1)*2*lineWidth,-10)-- 73+(i-1)*63, -10)
		StdUi:ApplyBackdrop(f,"graphBg","graphBgBorder")
	end
	-- timeStrings
	graph.timeStrings = {}
	for i=1,bgCount do
		local label = StdUi:Label(graph,"06/02",10)
		label:SetPoint("TOP", graph.bg[i], "BOTTOM", 0, -5)
		graph.timeStrings[i] = label
	end
	-- Seperating Lines
	graph.seplines = {}
	for i=1,verticalLines do
		local line = StdUi:Frame(graph,310,1)
		graph.seplines[i] = line
		line:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", 10,20+((graphHeight/(verticalLines-1))*(i-1)))-- 20+(45*(i-1)))
		line:SetPoint("BOTTOMRIGHT", graph, "BOTTOMRIGHT", -10,20+((graphHeight/(verticalLines-1))*(i-1))) --20+(45*(i-1)))
		StdUi:ApplyBackdrop(line,"line","lineBorder")
		line:SetAlpha(0.7)
		-- label
		local lineLabel = StdUi:Label(line,"123k",10)
		line.label = lineLabel
		lineLabel:SetPoint("BOTTOMLEFT", line, "TOPLEFT", 0, 2)
	end

	-- GraphLines
	graph.lines = {}
	for i=1,lineCount do
		local line = CreateLine(graph,2)
		line:SetVertexColor(1, 242/255, 9/255, 1)
		graph.lines[i] = line
	end

	function graph:Update(data)
		--[[
			data = {
				min = number,
				max = number,
				values = table with lineCount+1 values
				dates = table with lineCount/2 values
			}
		]]
		if not data then 
			self.warning:SetText("NO DATA")
			return 
		end
		self.warning:SetText("")
		local step = (data.max - data.min) / (verticalLines-1)
		for i=1,verticalLines do
			self.seplines[i].label:SetText(ShortenNumber(data.min + (i-1) * step))
		end
		local v = data.values
		local pixelValue = (data.max - data.min) / graphHeight
		local currX = 10
		local currY = 20 + (v[1] - data.min)/pixelValue
		local pixelY = (v[2]-v[1])/pixelValue
		ExgDrawLine(self.lines[1],graph,currX,currY,currX+lineWidth,currY+pixelY,2,"BOTTOMLEFT")
		currX = currX+lineWidth
		currY = currY+pixelY
		for i=2,lineCount do
			local nextValue = v[i+1] or v[i]
			local currValue = v[i] or 0
			pixelY = (nextValue-currValue)/pixelValue
			ExgDrawLine(self.lines[i],graph,currX,currY,currX+lineWidth,currY+pixelY,2,"BOTTOMLEFT")
			currX = currX+lineWidth
			currY = currY+pixelY
		end
		for i=1,bgCount do
			self.timeStrings[i]:SetText(data.dates[i])
		end
	end

	function graph:Clear()
		for i=1,lineCount do
			self.lines[i]:ClearAllPoints()
      self.lines[i]:SetPoint("BOTTOMLEFT", self, 0,0)
      self.lines[i]:SetPoint("TOPRIGHT", self, "BOTTOMLEFT",0 , 0)
		end
		for i=1,verticalLines do
			self.seplines[i].label:SetText("")
		end
		for i=1,bgCount do
			self.timeStrings[i]:SetText("")
		end
		self.warning:SetText("NO DATA")
	end

	function graph:RefreshData()
		self.selectedTimeFrame = self.selectedTimeFrame or "month"
		self.selectedCharacter = self.selectedCharacter or "all"
		local timekeys = timeKeys[self.selectedTimeFrame]
		local unitGold = 0
		local pointCount = lineCount + 1
		if self.selectedCharacter == "all" then
			unitGold = UI.totalGold
		else
			local char = Exgistr.GetCharacter(self.selectedCharacter)
			unitGold = char.current
		end
		local updateTable = {values = {}, dates = {}}
		local dateNow = date("*t", time())
		updateTable.dates[bgCount] = string.format("%02d%s%02d",dateNow[timekeys[1]],timekeys[2],dateNow[timekeys[3]])
		updateTable.max = unitGold / 10000
		updateTable.values[pointCount] = unitGold / 10000
		updateTable.values[pointCount - 1] = unitGold / 10000
		updateTable.min = updateTable.values[pointCount - 1]
		-- Select Data
		local timeLimit = timeLimits[self.selectedTimeFrame]
		local timeMin = time() - timeLimit
		local ledgerData = Exgistr.SelectLedgerData(self.selectedCharacter,{key = "date",value = timeMin, compare = ">"})
		if #ledgerData <= 0 then
			self:Clear()
			return
		end
		table.sort(ledgerData,function(a,b) return time(a.date) > time(b.date) end)
		-- Filter Data
		local idx = 1
		local timeCurr = time()
		local elapsedTime = timeCurr - time(ledgerData[#ledgerData].date)
		local timeStep = elapsedTime / (pointCount - 2)
		for i=1,bgCount-1 do 
			local timeDate = date("*t",timeCurr-timeStep*i*2) 
			updateTable.dates[bgCount-i] = string.format("%02d%s%02d",timeDate[timekeys[1]],timekeys[2],timeDate[timekeys[3]])
		end
		for i,data in ipairs(ledgerData) do
			local ledgeTime = time(data.date)
			if ledgeTime > (timeCurr - timeStep*idx) then
				updateTable.values[pointCount-idx] = updateTable.values[pointCount-idx] - data.amount / 10000
				updateTable.min = updateTable.min > updateTable.values[pointCount-idx] and updateTable.values[pointCount-idx] or updateTable.min
				updateTable.max = updateTable.max < updateTable.values[pointCount-idx] and updateTable.values[pointCount-idx] or updateTable.max
			else
				for b = idx+1,pointCount do
					if ledgeTime > (timeCurr - timeStep*b) then
						idx = b
						updateTable.values[pointCount-idx] = updateTable.values[pointCount - idx + 1] - data.amount / 10000
						updateTable.min = updateTable.min > updateTable.values[pointCount-idx] and updateTable.values[pointCount-idx] or updateTable.min
						updateTable.max = updateTable.max < updateTable.values[pointCount-idx] and updateTable.values[pointCount-idx] or updateTable.max
						break;
					else
						updateTable.values[pointCount-b] = updateTable.values[pointCount - b + 1]
					end
				end
			end
			--if idx >= 10 then break end -- KMS hack
		end
		self:Update(updateTable)
	end

	-- GRAPH: timeframe (dropdown)
	local tfOpt = {
		{text = "Month", value = "month"},
		{text = "Week", value = "week"},
		{text = "Day", value = "day"},
		{text = "Hour", value = "hour"}
	}
	local timeframedd = StdUi:Dropdown(graph,100,20,tfOpt,"month")
	timeframedd:SetPoint("BOTTOMLEFT", graph, "TOPLEFT", 0, 5)
	graph.selectedTimeFrame = "month"
	timeframedd.OnValueChanged = function(dropdown, value, text)
		graph.selectedTimeFrame = value
		graph:RefreshData()
	end
	graph.timeframe = timeframedd
	-- GRAPH: select char (dropdown)
	local characters = Exgistr.GetCharacters()
	local scOpt = {
		{text = "All", value = "all"}
	}
	table.sort(characters,function(a,b) return a.gold > b.gold end)
	for _,char in ipairs(characters) do
		table.insert(scOpt,{text = char.name, value = char.id})
	end
	local selectChardd = StdUi:Dropdown(graph,100,20,scOpt,"all")
	selectChardd:SetPoint("BOTTOMRIGHT", graph, "TOPRIGHT", 0, 5)
	selectChardd.OnValueChanged = function(dropdown, value, text)
		graph.selectedCharacter = value
		graph:RefreshData()
	end
	graph.charSelect = selectChardd
end

-- Ledger table
function UI:DrawLedgerTable()
	self.table = self.table or StdUi:ScrollTable(self, {
			{
				name = 'Source',
				width = 100,
				align = 'LEFT',
				index = 'type',
				format = 'text',
				sortable = false,
			},
			{
				name = 'Date',
				width = 100,
				align = 'LEFT',
				index = 'date',
				format = 'text',
				sortable = false,
				compareSort = function(self,rowA,rowB,sortBy)
					local a = self:GetRow(rowA)
					local b = self:GetRow(rowB)
					local column = self.cols[sortBy]
					local direction = column.sort or column.defaultSort or 'asc';
					if direction:lower() == 'asc' then
						return a.dateTime > b.dateTime
					else
						return a.dateTime < b.dateTime
					end
				end
			},
			{	name = 'Amount',
				width = 100,
				align = 'LEFT',
				index = 'amount',
				format = 'money',
				sortable = false,
			},}, 9, 20);
	local maintable = self.table
	maintable.scrollFrame:SetClampedToScreen(false)
	StdUi:GlueAcross(maintable, self, 10, -290, -360, 10)
	-- BUTTONS
	local expenseBtn,incomeBtn
	-- Button: Income
	incomeBtn = StdUi:Button(maintable,60,20,"Income")
	incomeBtn:SetPoint("BOTTOMLEFT", maintable, "TOPLEFT", 0, 30)
	incomeBtn:SetScript("OnClick", function(self) 
			UI.ledgerTab = "income" 
			self:SetBackdropColor(0.47,0.44,0,1)
			StdUi:ApplyBackdrop(expenseBtn)
			UI:RefreshData()
		end)
	incomeBtn:SetBackdropColor(0.47,0.44,0,1)
	-- Button: Expense
	expenseBtn = StdUi:Button(maintable,60,20,"Expense")
	expenseBtn:SetPoint("BOTTOMLEFT", incomeBtn, "BOTTOMRIGHT", 5, 0)
	expenseBtn:SetScript("OnClick", function(self) 
			UI.ledgerTab = "expense" 
			self:SetBackdropColor(0.47,0.44,0,1)
			StdUi:ApplyBackdrop(incomeBtn)
			UI:RefreshData()
		end)
	self.ledgerTab = "income" -- default
	-- Dropdown: Type Select
	local selectTypedd = StdUi:Dropdown(maintable,100,20,Exgistr.defaultSources ,"All")
	maintable.filterSource = "All"
	selectTypedd:SetPoint("BOTTOMRIGHT", maintable, "TOPRIGHT", 0, 30)
	selectTypedd.OnValueChanged = function(dropdown, value, text)
		maintable.filterSource = value
		UI:RefreshData()
	end
	maintable.selectedtype = selectTypedd
end


function UI:InitMainWindow()
	self:DrawCharacterPanel()
	self:DrawCharTotalPanel()
	self:DrawAccountTotalPanel()
	self:DrawLedgerTable()
	self:DrawAccountTotalPanel()
	self:DrawRealmTotalPanel()
	self:DrawGraph()
end

function UI:RefreshData()
	if self.charId then
		local charData = Exgistr.GetCharacter(self.charId)
		local expenses,income,lastWeek,lastMonth = 0,0,0,0

		-- Ledger Table
		local ledgerData = charData.ledger
		local filterSource = self.table.filterSource
		local data = {}
		for tId,d in ipairs(ledgerData) do
			--
			if d.amount < 0 then
				expenses = expenses + math.abs(d.amount)
				if self.ledgerTab == "expense" and (filterSource == d.type or filterSource == "All") then
					table.insert(data,{type = d.type,dateTime = time(d.date), date = string.format("%i/%i/%i %02d:%02d", d.date.year,d.date.month,d.date.day,d.date.hour,d.date.min),transType =  "Expense", amount = math.abs(d.amount)})
				end
			else
				if self.ledgerTab == "income" and (filterSource == d.type or filterSource == "All") then
					table.insert(data,{type = d.type, dateTime = time(d.date), date = string.format("%i/%i/%i %02d:%02d", d.date.year,d.date.month,d.date.day,d.date.hour,d.date.min),transType =  "Income", amount = d.amount})
				end
				income = income + d.amount
			end
			-- 
			if IsDateInLimit(d.date,"week") then
				lastWeek = lastWeek + d.amount
				lastMonth = lastMonth + d.amount
			elseif IsDateInLimit(d.date,"month") then
				lastMonth = lastMonth + d.amount
			end
		end
		self.table:SetData(data)
		self.table:SortData(2)
		-- Character Panel
		local charPanel = self.charPanel
		local r,g,b = GetClassColor(charData.class)
		charPanel.charName:SetText(charData.name)
		charPanel.charName:SetTextColor(r, g, b, 1)
		charPanel.currGold:SetMoneyString(charData.current)
		charPanel.goldLastWeek:SetMoneyString(lastWeek)
		charPanel.goldLastMonth:SetMoneyString(lastMonth)
		-- TOTALS
		local totalPanel = self.totalPanel
		totalPanel.expenseTotal:SetMoneyString(expenses)
		totalPanel.incomeTotal:SetMoneyString(income)
		totalPanel.profitTotal:SetMoneyString(income-expenses)
	end
	local allData = Exgistr.GetCharacterLedgers()
	local accThisWeek,realmThisWeek = 0,0
	local accTotal,realmTotal = 0,0
	local selectedRealm = self.charWindow.selectedRealm or GetRealmName()
	for realm,ledgers in pairs(allData) do
		for i,l in ipairs(ledgers) do
			if IsDateInLimit(l.date,"week") then
				if realm == selectedRealm then
					realmThisWeek = realmThisWeek + l.amount
				end
				accThisWeek = accThisWeek + l.amount
			end

			if realm == selectedRealm then
				realmTotal = realmTotal + l.amount
			end
			accTotal = accTotal + l.amount
		end
	end

	local initTime = Exgistr.GetInitTime()
	local timeNow = time()
	local days = math.ceil((timeNow - initTime)/86400)
	local avgTotal = accTotal / days
	local avgRealm = realmTotal / days
	self.acctotalPanel.currGold:SetMoneyString(self.totalGold)
	self.acctotalPanel.goldLastWeek:SetMoneyString(accThisWeek)
	self.acctotalPanel.goldAvg:SetMoneyString(avgTotal)
	self.realmtotalPanel.currGold:SetMoneyString(self.realmGold)
	self.realmtotalPanel.goldLastWeek:SetMoneyString(realmThisWeek)
	self.realmtotalPanel.goldAvg:SetMoneyString(avgRealm)
	self.graph:RefreshData()
end

function Exgistr.InitUI()
	UI:SetPoint('CENTER',0,0)
	UI.closeBtn:ClearAllPoints()
	UI.closeBtn:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -2, -2)
	UI:InitCharUI()
	UI:InitMainWindow()
	UI:SetFrameStrata("HIGH")
	UI:Hide()
end

function Exgistr.ShowUI()
	UI.charWindow:RefreshData()
	UI:RefreshData()
	UI:Show()
end

function Exgistr.HideUI()
	UI:Hide()
end


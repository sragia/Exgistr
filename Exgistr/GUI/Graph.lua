local E = Exgistr
local StdUi = E.GUI.StdUi
local UI = E.GUI.UI

-- Graph Config
local lineCount = 42
local verticalLines = 7
local lineSpread = 2 -- every bg line
local graphHeight = 180 -- shouldnt change
local graphWidth = 315  -- shouldnt change

local lineWidth = graphWidth/lineCount
local bgCount = math.floor(lineCount/2)
local timeStringCount = math.ceil(bgCount/lineSpread)

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
  ["month"] = 2592000,
  ["year"] = 31536000,
}

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

local function CreateLine(parent)
  local line = parent:CreateTexture(nil, "OVERLAY")
  line:SetTexture([[Interface\AddOns\Exgistr\Media\line]])
  line:SetVertexColor(1,1,1,1)
  return line
end

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

function UI:DrawGraph()
  self.graph = self.graph or StdUi:Panel(self,330,100)
  local graph = self.graph
  graph:SetPoint("TOPLEFT",self.realmtotalPanel,"BOTTOMLEFT",0,-40)
  graph:SetPoint("BOTTOMRIGHT",self.table,"BOTTOMRIGHT",340,0)
  graph.warning = StdUi:Label(graph,"",30)
  graph.warning:SetPoint("CENTER",graph,0,0)
  -- Background
  graph.bg = {}
  for i=1,bgCount do
    local f = StdUi:Frame(graph,31,40)
    graph.bg[i] = f
    f:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", 10+lineWidth+(i-1)*lineWidth*2,20)--   41.5+(i-1)*63, 20)
    f:SetPoint("TOPRIGHT",graph, "TOPLEFT",10+2*lineWidth+(i-1)*2*lineWidth,-10)-- 73+(i-1)*63, -10)
    StdUi:ApplyBackdrop(f,"graphBg","graphBgBorder")
  end
  -- timeStrings
  graph.timeStrings = {}
  for i=1,timeStringCount do
    local label = StdUi:Label(graph,"06/02",10)
    label:SetPoint("TOP", graph.bg[1+(i-1)*lineSpread], "BOTTOM", 0, -5)
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
end

function UI:DrawGraphDropdowns()
  local tfOpt = {
    {text = "Month", value = "month"},
    {text = "Week", value = "week"},
    {text = "Day", value = "day"},
    {text = "Hour", value = "hour"}
  }
  local timeframedd = StdUi:Dropdown(UI.graph,100,20,tfOpt,"month")
  timeframedd:SetPoint("BOTTOMLEFT", UI.graph, "TOPLEFT", 0, 5)
  UI.graph.selectedTimeFrame = "month"
  timeframedd.OnValueChanged = function(dropdown, value, text)
    if UI.graph.selectedTimeFrame ~= value then
      UI.graph.selectedTimeFrame = value
      UI.graph:RefreshData()
    end
  end
  UI.graph.timeframe = timeframedd
  -- GRAPH: select char (dropdown)
  local characters = Exgistr.GetCharacters()
  local scOpt = {
    {text = "All", value = "all"}
  }
  table.sort(characters,function(a,b) return a.gold > b.gold end)
  for _,char in ipairs(characters) do
    table.insert(scOpt,{text = char.name, value = char.id})
  end
  local selectChardd = StdUi:Dropdown(UI.graph,100,20,scOpt,"all")
  selectChardd:SetPoint("BOTTOMRIGHT", UI.graph, "TOPRIGHT", 0, 5)
  selectChardd.OnValueChanged = function(dropdown, value, text)
    if UI.graph.selectedCharacter ~= value then
      UI.graph.selectedCharacter = value
      UI.graph:RefreshData()
    end
  end
  UI.graph.charSelect = selectChardd
end

local methods = {
  Update = function(self,data)
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
    ExgDrawLine(self.lines[1],self,currX,currY,currX+lineWidth,currY+pixelY,2,"BOTTOMLEFT")
    currX = currX+lineWidth
    currY = currY+pixelY
    for i=2,lineCount do
      local nextValue = v[i+1] or v[i]
      local currValue = v[i] or 0
      pixelY = (nextValue-currValue)/pixelValue
      ExgDrawLine(self.lines[i],self,currX,currY,currX+lineWidth,currY+pixelY,2,"BOTTOMLEFT")
      currX = currX+lineWidth
      currY = currY+pixelY
    end
    for i=1,timeStringCount do
      self.timeStrings[i]:SetText(data.dates[i])
    end
  end,
  
  Clear = function(self)
    for i=1,lineCount do
      self.lines[i]:ClearAllPoints()
      self.lines[i]:SetPoint("BOTTOMLEFT", self, 0,0)
      self.lines[i]:SetPoint("TOPRIGHT", self, "BOTTOMLEFT",0 , 0)
    end
    for i=1,verticalLines do
      self.seplines[i].label:SetText("")
    end
    for i=1,timeStringCount do
      self.timeStrings[i]:SetText("")
    end
    self.warning:SetText("NO DATA")
  end,

  RefreshData = function(self)
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
    updateTable.dates[timeStringCount] = string.format("%02d%s%02d",dateNow[timekeys[1]],timekeys[2],dateNow[timekeys[3]])
    updateTable.values[pointCount] = unitGold / 10000
    updateTable.values[pointCount - 1] = unitGold / 10000
    -- Select Data
    local timeLimit = timeLimits[self.selectedTimeFrame]
    local timeMin = time() - timeLimit
    local ledgerData = Exgistr.SelectLedgerData(self.selectedCharacter,{key = "date",value = timeMin, compare = ">"})
    if #ledgerData <= 0 then
      self:Clear()
      return
    end
    table.sort(ledgerData,function(a,b) return a.date > b.date end)
    -- Filter Data
    local idx = 1
    local timeCurr = time()
    local elapsedTime = timeCurr - ledgerData[#ledgerData].date
    local timeStep = elapsedTime / (pointCount - 2)
    for i=1,timeStringCount-1 do
      local timeDate = date("*t",timeCurr-timeStep*i*2*lineSpread)
      updateTable.dates[timeStringCount-i] = string.format("%02d%s%02d",timeDate[timekeys[1]],timekeys[2],timeDate[timekeys[3]])
    end
    for i,data in ipairs(ledgerData) do
      local ledgeTime = data.date
      if ledgeTime > (timeCurr - timeStep*idx) then
        updateTable.values[pointCount-idx] = updateTable.values[pointCount-idx] - data.amount / 10000
      else
        for b = idx+1,pointCount do
          if ledgeTime > (timeCurr - timeStep*b) then
            idx = b
            updateTable.values[pointCount-idx] = updateTable.values[pointCount - idx + 1] - data.amount / 10000
            break;
          else
            updateTable.values[pointCount-b] = updateTable.values[pointCount - b + 1]
          end
        end
      end
      --if idx >= 10 then break end -- KMS hack
    end
    local min,max = updateTable.values[1],updateTable.values[1]
    for i=2,pointCount do
      min = min > updateTable.values[i] and updateTable.values[i] or min
      max = max < updateTable.values[i] and updateTable.values[i] or max
    end
    updateTable.min = min
    updateTable.max = max
    self:Update(updateTable)
  end
}

function E.GUI.InitGraph()
  UI:DrawGraph()
  UI:DrawGraphDropdowns()
  for name,func in pairs(methods) do
    UI.graph[name] = func
  end
end
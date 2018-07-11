local E = Exgistr
E.GUI = {}
local StdUi = LibStub('StdUi'):NewInstance()
E.GUI.StdUi = StdUi
-- CONFIG --
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

local timeLimits = {
  ["min"] = 60,
  ["hour"] = 3600,
  ["day"] = 86400,
  ["week"] = 604800,
  ["month"] = 18144000,
  ["year"] = 31536000,
}

local filterTimeNames = {
  year = "Year",
  month = "Month",
  week = "Week",
  day = "Day",
  hour = "Hour"
  }

local UI = StdUi:Window(nil, 'Exgistr', 700, 500)
UI.titlePanel:ClearAllPoints()
UI.titlePanel:SetPoint("BOTTOMLEFT", UI, "TOPLEFT", 0, -1)
UI.titlePanel:SetPoint("BOTTOMRIGHT", UI, "TOPRIGHT", 0, -1)
UI.closeBtn:ClearAllPoints()
UI.closeBtn:SetPoint("TOPRIGHT", UI.titlePanel, 0, 0)
UI.closeBtn:SetPoint("BOTTOMRIGHT", UI.titlePanel, 0, 0)
E.GUI.UI = UI

function UI:InitMainWindow()
  local tfOpt = {
    {text = "Year", value = "year"},
    {text = "Month", value = "month"},
    {text = "Week", value = "week"},
    {text = "Day", value = "day"},
    {text = "Hour", value = "hour"}
  }
  local timeframe = StdUi:Dropdown(self, 100, 20, tfOpt, "year")
  timeframe:SetPoint("TOPRIGHT",-25,-3)
  timeframe.OnValueChanged = function(dropdown, value, text)
    if UI.filterTime ~= value then
      UI.filterTime = value
      UI:RefreshCharData()
      UI:RefreshAccData()
    end
  end
  local label = StdUi:Label(timeframe, "Time Frame:")
  label:SetPoint("RIGHT",timeframe,"LEFT",-2,0)
end

function UI:RefreshCharData()
  if self.charId then
    local charData
    if self.charData[self.charId] and self.charData[self.charId][self.filterTime]  then
      charData = self.charData[self.charId][self.filterTime].data
    else
      charData = Exgistr.GetCharacterInfo(self.charId)
      charData.ledger = Exgistr.SelectLedgerData(self.charId,{key = "date", value = time() - timeLimits[self.filterTime],compare = ">"})
      self.charData[self.charId] = self.charData[self.charId] or {}
      self.charData[self.charId][self.filterTime] = {data = charData, filter = {},stats = {}}
    end
    local expenses,income= 0,0
    local mindate
    -- Ledger Table
    local ledgerData = charData.ledger
    local filterSource = self.table.filterSource
    local data = {}
    for tId,d in ipairs(ledgerData) do
        --
        if not mindate then mindate = d.date end
        if d.amount < 0 then
          expenses = expenses + math.abs(d.amount)
          if self.ledgerTab == "expense" and (filterSource == d.type or filterSource == "All") then
            local date = date("*t",d.date)
            table.insert(data,{type = d.type,dateTime = d.date, date = string.format("%i/%i/%i %02d:%02d", date.year,date.month,date.day,date.hour,date.min),transType =  "Expense", amount = math.abs(d.amount)})
          end
        else
          if self.ledgerTab == "income" and (filterSource == d.type or filterSource == "All") then
            local date = date("*t",d.date)
            table.insert(data,{type = d.type, dateTime = d.date, date = string.format("%i/%i/%i %02d:%02d", date.year,date.month,date.day,date.hour,date.min),transType =  "Income", amount = d.amount})
          end
          income = income + d.amount
        end
    end
    self.table:SetData(data)
    self.table:SortData(2)
    -- Character Panel
    mindate = mindate or time()
    local days = math.ceil((time()-mindate)/86400)
    days = days > 0 and days or 1
    local charPanel = self.charPanel
    local r,g,b = GetClassColor(charData.class)
    local profit = income-expenses
    charPanel.charName:SetText(charData.name)
    charPanel.charName:SetTextColor(r, g, b, 1)
    charPanel.currGold:SetMoneyString(charData.current)
    charPanel.goldMade:SetMoneyString(profit)
    charPanel.goldMadeLabel:SetText("Gold Made This ".. filterTimeNames[self.filterTime])
    charPanel.goldAverage:SetMoneyString(profit/days)
    -- TOTALS
    local totalPanel = self.totalPanel
    totalPanel.expenseTotal:SetMoneyString(expenses)
    totalPanel.incomeTotal:SetMoneyString(income)
    totalPanel.profitTotal:SetMoneyString(income-expenses)
  end
end

function UI:RefreshAccData()
  local allData = Exgistr.GetCharacterLedgers({key = "date", value = time() - timeLimits[self.filterTime],compare = ">"})
  local accThisWeek,realmThisWeek = 0,0
  local accTotal,realmTotal = 0,0
  local selectedRealm = self.charWindow.selectedRealm or GetRealmName()
  local mindate
  for realm,ledgers in pairs(allData) do
    for i,l in ipairs(ledgers) do
      mindate = mindate and (mindate < l.date and mindate) or l.date
      if realm == selectedRealm then
        realmThisWeek = realmThisWeek + l.amount
      end
      accThisWeek = accThisWeek + l.amount

      if realm == selectedRealm then
        realmTotal = realmTotal + l.amount
      end
      accTotal = accTotal + l.amount
    end
  end
  mindate = mindate or time()
  local timeNow = time()
  local days = math.ceil((timeNow - mindate)/86400)
  local avgTotal = accTotal > 0 and accTotal / days or 0
  local avgRealm = realmTotal > 0 and realmTotal / days or 0
  self.acctotalPanel.currGold:SetMoneyString(self.totalGold)
  self.acctotalPanel.goldMade:SetMoneyString(accThisWeek)
  self.acctotalPanel.goldMadeLabel:SetText("Gold Made This ".. filterTimeNames[self.filterTime])
  self.acctotalPanel.goldAvg:SetMoneyString(avgTotal)
  self.realmtotalPanel.currGold:SetMoneyString(self.realmGold)
  self.realmtotalPanel.goldMade:SetMoneyString(realmThisWeek)
  self.realmtotalPanel.goldMadeLabel:SetText("Gold Made This ".. filterTimeNames[self.filterTime])
  self.realmtotalPanel.goldAvg:SetMoneyString(avgRealm)
  self.graph:RefreshData()
end


function E.InitUI()
  UI:SetPoint('CENTER',0,0)
  UI:SetFrameStrata("HIGH")
  UI.filterTime = "year"
  UI:InitMainWindow()
  -- modules
  E.GUI.InitCharacters()
  E.GUI.InitPanels()
  E.GUI.InitLedger()
  E.GUI.InitGraph()
  
  UI:Hide()
end

function E.ShowUI()
  UI.charData = {}
  UI.charWindow:RefreshData()
  UI:RefreshCharData()
  UI:RefreshAccData()
  UI:Show()
end

function Exgistr.HideUI()
  UI:Hide()
end
local E = Exgistr
local StdUi = E.GUI.StdUi
local UI = E.GUI.UI

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

function UI:DrawCharUI()
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
          self:RefreshCharData()
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
          self:RefreshCharData()
        end,
      },
    }}, 13, 20)self:RefreshCharData()
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
    if charWindow.selectedRealm ~= value then
      charWindow.selectedRealm = value
      self.charId = nil
      charWindow:RefreshData()
      self:RefreshAccData()
    end
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

function E.GUI.InitCharacters()
  UI:DrawCharUI()
end

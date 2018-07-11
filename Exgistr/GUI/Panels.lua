local E = Exgistr
local StdUi = E.GUI.StdUi
local UI = E.GUI.UI

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

-- Character Panel
function UI:DrawCharacterPanel()
  self.charPanel = self.charPanel or StdUi:Panel(self,330,100)
  local charPanel = self.charPanel
  StdUi:GlueTop(charPanel,self,10,-25,'LEFT')
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
  -- Made timefraem
  local goldMadeLabel,goldMade = CreateMoneyText(charPanel,"Gold This Week:",13)
  charPanel.goldMade = goldMade
  charPanel.goldMadeLabel = goldMadeLabel
  StdUi:GlueTop(goldMadeLabel,currGoldLabel,0,-18,'LEFT')
  StdUi:GlueAfter(goldMade,goldMadeLabel,5,0,5,0)
  -- Made Avg
  local goldAverageLabel,goldAverage = CreateMoneyText(charPanel,"Average per day:",13)
  charPanel.goldAverage = goldAverage
  charPanel.goldAverageLabel = goldAverageLabel
  StdUi:GlueTop(goldAverageLabel,goldMadeLabel,0,-18,'LEFT')
  StdUi:GlueAfter(goldAverage,goldAverageLabel,5,0,5,0)
  -- TEST
  currGold:SetMoneyString(123456)
  goldMade:SetMoneyString(123456)
  goldAverage:SetMoneyString(123456)
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
  local goldMadeLabel,goldMade = CreateMoneyText(acctotalPanel,"Gold This Week:",13)
  acctotalPanel.goldMade = goldMade
  acctotalPanel.goldMadeLabel = goldMadeLabel
  StdUi:GlueTop(goldMadeLabel,currGoldLabel,0,-18,'LEFT')
  StdUi:GlueAfter(goldMade,goldMadeLabel,5,0,5,0)
  -- Made Last Month
  local goldAvgLabel,goldAvg = CreateMoneyText(acctotalPanel,"Average per Day :",13)
  acctotalPanel.goldAvg = goldAvg
  StdUi:GlueTop(goldAvgLabel,goldMadeLabel,0,-18,'LEFT')
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
  local goldMadeLabel,goldMade = CreateMoneyText(realmtotalPanel,"Gold Last Week:",13)
  realmtotalPanel.goldMade = goldMade
  realmtotalPanel.goldMadeLabel = goldMadeLabel
  StdUi:GlueTop(goldMadeLabel,currGoldLabel,0,-18,'LEFT')
  StdUi:GlueAfter(goldMade,goldMadeLabel,5,0,5,0)
  -- Made Last Month
  local goldAvgLabel,goldAvg = CreateMoneyText(realmtotalPanel,"Average per Day :",13)
  realmtotalPanel.goldAvg = goldAvg
  StdUi:GlueTop(goldAvgLabel,goldMadeLabel,0,-18,'LEFT')
  StdUi:GlueAfter(goldAvg,goldAvgLabel,5,0,5,0)
end

function E.GUI.InitPanels()
  UI:DrawCharacterPanel()
  UI:DrawCharTotalPanel()
  UI:DrawAccountTotalPanel()
  UI:DrawRealmTotalPanel()
end

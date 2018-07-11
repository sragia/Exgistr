local E = Exgistr
local StdUi = E.GUI.StdUi
local UI = E.GUI.UI

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
          local column = self.columns[sortBy]
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
  StdUi:GlueAcross(maintable, self, 10, -295, -360, 5)
  -- BUTTONS
  local expenseBtn,incomeBtn
  -- Button: Income
  incomeBtn = StdUi:Button(maintable,60,20,"Income")
  incomeBtn:SetPoint("BOTTOMLEFT", maintable, "TOPLEFT", 0, 30)
  incomeBtn:SetScript("OnClick", function(self)
      UI.ledgerTab = "income"
      self:SetBackdropColor(0.47,0.44,0,1)
      StdUi:ApplyBackdrop(expenseBtn)
      UI:RefreshCharData()
    end)
  incomeBtn:SetBackdropColor(0.47,0.44,0,1)
  -- Button: Expense
  expenseBtn = StdUi:Button(maintable,60,20,"Expense")
  expenseBtn:SetPoint("BOTTOMLEFT", incomeBtn, "BOTTOMRIGHT", 5, 0)
  expenseBtn:SetScript("OnClick", function(self)
      UI.ledgerTab = "expense"
      self:SetBackdropColor(0.47,0.44,0,1)
      StdUi:ApplyBackdrop(incomeBtn)
      UI:RefreshCharData()
    end)
  self.ledgerTab = "income" -- default
  -- Dropdown: Type Select
  local selectTypedd = StdUi:Dropdown(maintable,100,20,Exgistr.defaultSources ,"All")
  maintable.filterSource = "All"
  selectTypedd:SetPoint("BOTTOMRIGHT", maintable, "TOPRIGHT", 0, 30)
  selectTypedd.OnValueChanged = function(dropdown, value, text)
    if maintable.filterSource ~= value then
      maintable.filterSource = value
      UI:RefreshCharData()
    end
  end
  maintable.selectedtype = selectTypedd
end

function E.GUI.InitLedger()
  UI:DrawLedgerTable()
end
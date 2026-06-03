local M = {}

local logo_lines = {}
local logo_path = vim.fn.stdpath("config") .. "/lua/configs/logo.txt"
local f = io.open(logo_path, "r")
if f then
  for line in f:lines() do
    table.insert(logo_lines, line)
  end
  f:close()
end

local timer = nil
local buf = nil
local win = nil
local ns = vim.api.nvim_create_namespace("custom_dashboard")

local state = {
  active_col = 1,
  sel = { 1, 1, 1 },
}
local columns = {}
local click_zones = {}

-- Helper to safely close
local function close_dash()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  buf = nil
  win = nil
end

-- Helpers
local function get_oldfiles()
  local results = {}
  local oldfiles = vim.v.oldfiles
  local count = 0
  for _, file in ipairs(oldfiles) do
    if count >= 10 then break end
    if vim.fn.filereadable(file) == 1 then
      table.insert(results, { 
        label = "  " .. vim.fn.fnamemodify(file, ":t"), 
        action = function() vim.cmd("edit " .. vim.fn.fnameescape(file)) end 
      })
      count = count + 1
    end
  end
  if #results == 0 then table.insert(results, { label = "(No recent files)", action = function() end }) end
  return results
end

local function get_projects()
  local results = {}
  local ok, core = pcall(require, "project_templates.core")
  if ok and core.get_projects then
    local projects = core.get_projects()
    for i, p in ipairs(projects) do
      if i > 10 then break end
      table.insert(results, { 
        label = "  " .. vim.fn.fnamemodify(p.path, ":t"), 
        action = function() vim.cmd("cd " .. vim.fn.fnameescape(p.path)); require("nvim-tree.api").tree.open() end 
      })
    end
  end
  if #results == 0 then table.insert(results, { label = "(No projects found)", action = function() end }) end
  return results
end

local function get_user_greeting()
  local data_dir = vim.fn.stdpath("config") .. "/data"
  local f = io.open(data_dir .. "/user.json", "r")
  local name = "User"
  if f then
    local content = f:read("*a")
    f:close()
    local name_match = string.match(content, '"name"%s*:%s*"([^"]+)"')
    if name_match then name = name_match end
  end
  local hour = tonumber(os.date("%H"))
  if hour < 12 then return "Good Morning, " .. name
  elseif hour < 18 then return "Good Afternoon, " .. name
  else return "Good Evening, " .. name end
end

local function format_date_english()
  local days = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
  local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
  local t = os.date("*t")
  return string.format("%s, %02d %s %04d", days[t.wday], t.day, months[t.month], t.year)
end

local function pad_string(str, target_width)
  local width = vim.fn.strdisplaywidth(str)
  if width < target_width then
    return str .. string.rep(" ", target_width - width)
  end
  return str
end

local function open_nui_menu(title, items, callback)
  local Menu = require("nui.menu")
  local menu_items = {}
  for _, v in ipairs(items) do
    table.insert(menu_items, Menu.item(" " .. v.label .. " ", { cmd = v.cmd }))
  end

  local menu = Menu({
    position = "50%",
    size = {
      width = 40,
      height = #menu_items + 2,
    },
    border = {
      style = "rounded",
      text = {
        top = " " .. title .. " ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:CursorLine",
    },
  }, {
    lines = menu_items,
    max_width = 40,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "q" },
      submit = { "<CR>" },
    },
    on_submit = function(item)
      if callback then callback(item.cmd) end
    end,
  })
  menu:mount()
end

local function draw()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  
  local win_width = vim.api.nvim_win_get_width(win or 0)
  local win_height = vim.api.nvim_win_get_height(win or 0)
  
  local content = {}
  
  -- Center calculations
  local logo_width = 54
  local col1_w = 30
  local col2_w = 40
  local col3_w = 40
  local gap = "   "
  local total_w = col1_w + col2_w + col3_w + 6
  
  local left_pad = math.max(0, math.floor((win_width - total_w) / 2))
  local logo_pad = math.max(0, math.floor((win_width - logo_width) / 2))
  
  local function add_centered(text)
    local w = vim.fn.strdisplaywidth(text)
    local p = math.max(0, math.floor((win_width - w) / 2))
    table.insert(content, string.rep(" ", p) .. text)
  end
  
  -- Vertical padding
  for _ = 1, math.max(1, math.floor(win_height / 2) - 15) do
    table.insert(content, "")
  end
  
  -- Add Logo
  for _, line in ipairs(logo_lines) do
    table.insert(content, string.rep(" ", logo_pad) .. line)
  end
  
  table.insert(content, "")
  add_centered(get_user_greeting())
  add_centered(format_date_english())
  add_centered(os.date("%H:%M:%S"))
  table.insert(content, "")
  table.insert(content, "")
  
  -- Add Columns Header
  local function make_top_border(col_idx)
    local t = " " .. columns[col_idx].title .. " "
    local col_w = col_idx == 1 and col1_w or col_idx == 2 and col2_w or col3_w
    local t_len = vim.fn.strdisplaywidth(t)
    local dashes = math.max(0, col_w - t_len)
    local left_d = math.floor(dashes / 2)
    local right_d = dashes - left_d
    return string.rep("─", left_d) .. t .. string.rep("─", right_d)
  end
  
  local title_row = string.rep(" ", left_pad) .. make_top_border(1) .. gap .. make_top_border(2) .. gap .. make_top_border(3)
  table.insert(content, title_row)
  
  -- Add Column Items
  local max_items = math.max(#columns[1].items, #columns[2].items, #columns[3].items)
  
  local hl_data = {}
  click_zones = {}
  
  for i = 1, max_items do
    local function render_item(col_idx)
      local item = columns[col_idx].items[i]
      if not item then return "" end
      local is_selected = (state.active_col == col_idx) and (state.sel[col_idx] == i)
      local prefix = is_selected and "  " or "   "
      return prefix .. item.label
    end
    
    local c1 = render_item(1)
    local c2 = render_item(2)
    local c3 = render_item(3)
    
    for col_idx = 1, 3 do
      local is_selected = (state.active_col == col_idx) and (state.sel[col_idx] == i)
      local text = (col_idx == 1 and c1) or (col_idx == 2 and c2) or c3
      
      local item = columns[col_idx].items[i]
      if item then
        local offset = left_pad
        if col_idx == 2 then offset = offset + string.len(pad_string(c1, col1_w)) + 3 end
        if col_idx == 3 then offset = offset + string.len(pad_string(c1, col1_w)) + 3 + string.len(pad_string(c2, col2_w)) + 3 end
        table.insert(click_zones, {
          line = #content + 1,
          col_start = offset,
          col_end = offset + string.len(text),
          col_idx = col_idx,
          item_idx = i
        })
      end
      
      if is_selected then
        table.insert(hl_data, { line = #content + 1, col = col_idx, c1 = c1, c2 = c2, c3 = c3, text = text })
      end
    end
    
    local c1_pad = pad_string(c1, col1_w)
    local c2_pad = pad_string(c2, col2_w)
    local c3_pad = pad_string(c3, col3_w)
    
    table.insert(content, string.rep(" ", left_pad) .. c1_pad .. gap .. c2_pad .. gap .. c3_pad)
  end
  
  -- Add Columns Footer
  local function make_bottom_border(col_w)
    return string.rep("─", col_w)
  end
  local footer_row = string.rep(" ", left_pad) .. make_bottom_border(col1_w) .. gap .. make_bottom_border(col2_w) .. gap .. make_bottom_border(col3_w)
  table.insert(content, footer_row)
  
  -- Safely update buffer lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  
  local start_logo_line = math.max(1, math.floor(win_height / 2) - 15)
  for i = 0, 5 do
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Function", start_logo_line + i - 1, 0, -1)
  end
  
  pcall(vim.api.nvim_buf_add_highlight, buf, ns, "String", start_logo_line + 7, 0, -1)
  pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Type", start_logo_line + 8, 0, -1)
  
  pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Comment", start_logo_line + 11, 0, -1)
  
  for _, h in ipairs(hl_data) do
    local offset = left_pad
    if h.col == 2 then offset = offset + string.len(pad_string(h.c1, col1_w)) + 3 end
    if h.col == 3 then offset = offset + string.len(pad_string(h.c1, col1_w)) + 3 + string.len(pad_string(h.c2, col2_w)) + 3 end
    
    -- Highlight prefix '  '
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Keyword", h.line - 1, offset, offset + 5)
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Function", h.line - 1, offset + 5, offset + string.len(h.text))
  end
  
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function map(key, fn)
  vim.keymap.set("n", key, fn, { buffer = buf, silent = true, nowait = true })
end

local function init_data()
  columns = {
    { 
      title = "Actions", 
      items = {
        { label = "  Project Manager", action = function() vim.cmd("ProjectManager") end },
        { label = "  New File", action = function() vim.cmd("NewFile") end },
        { label = "  Search", action = function() 
            open_nui_menu("Search", {
              { label = "  Find File", cmd = "Telescope find_files" },
              { label = "  Find Word", cmd = "Telescope live_grep" }
            }, function(cmd) vim.cmd(cmd) end)
          end 
        },
        { label = "  System", action = function() 
            open_nui_menu("System", {
              { label = "  Mason", cmd = "Mason" },
              { label = "󰒲  Lazy", cmd = "Lazy" },
              { label = "  Dotfiles", cmd = "dotfiles" }
            }, function(cmd) 
              if cmd == "dotfiles" then
                vim.cmd("cd " .. vim.fn.stdpath("config"))
                require("oil").open()
              else
                vim.cmd(cmd)
              end
            end)
          end 
        },
        { label = "󰆍  Open Terminal", action = function() vim.cmd("terminal") end },
        { label = "  Themes", action = function() vim.cmd("Telescope themes") end },
        { label = "  Quit", action = function() vim.cmd("qa") end },
      }
    },
    { title = "Recent Projects", items = get_projects() },
    { title = "Recent Files", items = get_oldfiles() }
  }
end

M.open = function()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_buf(buf)
    return
  end
  
  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "dashboard", { buf = buf })
  
  vim.api.nvim_set_current_buf(buf)
  win = vim.api.nvim_get_current_win()
  vim.cmd("setlocal nonumber norelativenumber signcolumn=no foldcolumn=0 statusline=\\ ")
  
  init_data()
  state.active_col = 1
  state.sel = { 1, 1, 1 }
  
  draw()
  
  map("<Tab>", function()
    state.active_col = state.active_col + 1
    if state.active_col > 3 then state.active_col = 1 end
    draw()
  end)
  map("<S-Tab>", function()
    state.active_col = state.active_col - 1
    if state.active_col < 1 then state.active_col = 3 end
    draw()
  end)
  map("<Down>", function()
    local col = state.active_col
    if #columns[col].items > 0 then
      state.sel[col] = state.sel[col] + 1
      if state.sel[col] > #columns[col].items then state.sel[col] = 1 end
    end
    draw()
  end)
  map("j", function()
    local col = state.active_col
    if #columns[col].items > 0 then
      state.sel[col] = state.sel[col] + 1
      if state.sel[col] > #columns[col].items then state.sel[col] = 1 end
    end
    draw()
  end)
  map("<Up>", function()
    local col = state.active_col
    if #columns[col].items > 0 then
      state.sel[col] = state.sel[col] - 1
      if state.sel[col] < 1 then state.sel[col] = #columns[col].items end
    end
    draw()
  end)
  map("k", function()
    local col = state.active_col
    if #columns[col].items > 0 then
      state.sel[col] = state.sel[col] - 1
      if state.sel[col] < 1 then state.sel[col] = #columns[col].items end
    end
    draw()
  end)
  map("<Right>", function()
    state.active_col = state.active_col + 1
    if state.active_col > 3 then state.active_col = 1 end
    draw()
  end)
  map("l", function()
    state.active_col = state.active_col + 1
    if state.active_col > 3 then state.active_col = 1 end
    draw()
  end)
  map("<Left>", function()
    state.active_col = state.active_col - 1
    if state.active_col < 1 then state.active_col = 3 end
    draw()
  end)
  map("h", function()
    state.active_col = state.active_col - 1
    if state.active_col < 1 then state.active_col = 3 end
    draw()
  end)
  map("<CR>", function()
    local item = columns[state.active_col].items[state.sel[state.active_col]]
    if item and item.action then
      close_dash()
      item.action()
    end
  end)
  
  map("<LeftMouse>", function()
    local mousepos = vim.fn.getmousepos()
    if mousepos.winid == win then
      for _, z in ipairs(click_zones) do
        if mousepos.line == z.line and mousepos.column >= z.col_start and mousepos.column <= z.col_end then
          state.active_col = z.col_idx
          state.sel[z.col_idx] = z.item_idx
          draw()
          local item = columns[state.active_col].items[state.sel[state.active_col]]
          if item and item.action then
            close_dash()
            item.action()
          end
          break
        end
      end
    end
  end)
  
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function() draw() end,
  })
  
  timer = vim.uv.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(function()
    draw()
  end))
end

return M

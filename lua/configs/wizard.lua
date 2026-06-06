local M = {}

local buf = nil
local win = nil
local selected_btn = 1
local buttons = {}
local finish_cb = nil

local function close_wizard()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function draw_screen(lines, btns, selected)
  local max_w = vim.o.columns
  for i, l in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(l)
    if len < max_w then
      lines[i] = l .. string.rep(" ", max_w - len)
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, 0, 0, -1)
  if btns then
    for i, btn in ipairs(btns) do
      local hl = (i == selected) and "Search" or "Comment"
      local ns = vim.api.nvim_create_namespace("wizard_hl")
      
      local sr = math.max(0, btn.row - 1)
      local er = btn.row + 1
      local sc = 0
      local ec = 0
      if btn.text and lines[btn.row + 1] then
        local line_str = lines[btn.row + 1]
        local s, e = string.find(line_str, btn.text, 1, true)
        if s and e then
          sc = math.max(0, s - 2)
          ec = e + 1
        else
          sc = math.max(0, btn.col_start - 2)
          ec = btn.col_end + 2
        end
      else
        sc = math.max(0, btn.col_start - 2)
        ec = btn.col_end + 2
      end
      
      for r = sr, er do
        if r < #lines then
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, r, sc, {
            end_col = ec,
            hl_group = hl,
          })
        end
      end
    end
  end
end

local function move_selection(dir)
  if #buttons == 0 then return end
  selected_btn = selected_btn + dir
  if selected_btn < 1 then selected_btn = #buttons end
  if selected_btn > #buttons then selected_btn = 1 end
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  draw_screen(lines, buttons, selected_btn)
end

local function execute_selection()
  if buttons[selected_btn] and buttons[selected_btn].action then
    vim.schedule(function()
      buttons[selected_btn].action()
    end)
  end
end

local function setup_menu_keys()
  vim.keymap.set("n", "<Right>", function() move_selection(1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "l", function() move_selection(1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Left>", function() move_selection(-1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "h", function() move_selection(-1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<CR>", execute_selection, { buffer = buf, nowait = true })
end

local function save_state(step)
  local data_dir = vim.fn.stdpath("config") .. "/data"
  if vim.fn.isdirectory(data_dir) == 0 then vim.fn.mkdir(data_dir, "p") end
  local file = io.open(data_dir .. "/wizard_state.json", "w")
  if file then file:write('{"step": ' .. step .. '}') file:close() end
end

local function get_state()
  local file = io.open(vim.fn.stdpath("config") .. "/data/wizard_state.json", "r")
  if file then
    local content = file:read("*a")
    file:close()
    local step = string.match(content, '"step"%s*:%s*(%d+)')
    if step then return tonumber(step) end
  end
  return 0
end

local function screen4()
  close_wizard()
  
  -- Create Cover Screen
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })
  
  local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local frame = 1
  local status_text = "Installing Lazy Plugins (this may take a minute)..."
  local is_done = false
  
  local logo = {}
  local logo_path = vim.fn.stdpath("config") .. "/lua/configs/logo.txt"
  local f = io.open(logo_path, "r")
  if f then
    for line in f:lines() do table.insert(logo, line) end
    f:close()
  end
  
  local function draw_s4()
    local lines = {}
    for i=1, math.floor(vim.o.lines / 2) - 10 do table.insert(lines, "") end
    for _, l in ipairs(logo) do table.insert(lines, "    " .. l) end
    table.insert(lines, "")
    table.insert(lines, "        " .. frames[frame] .. " " .. status_text)
    table.insert(lines, "")
    table.insert(lines, "            Close Loading Window  ")
    
    buttons = { { text = "Close Loading Window", row = #lines - 1, col_start = 12, col_end = 31, action = function() 
      close_wizard()
      vim.g.wizard_active = false
      if is_done and vim.fn.argc() == 0 then
        local ok, dash = pcall(require, "configs.custom_dash")
        if ok and dash.open then dash.open() end
      end
    end } }
    
    selected_btn = 1
    draw_screen(lines, buttons, selected_btn)
  end

  local timer = vim.uv.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(buf) then timer:close() return end
    frame = (frame % #frames) + 1
    if is_done then frames[frame] = "✓" end
    draw_s4()
  end))

  vim.keymap.set("n", "<CR>", execute_selection, { buffer = buf, nowait = true })

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
      status_text = "Installing Mason LSPs..."
      vim.schedule(function()
        local ok, mason = pcall(require, "nvchad.mason")
        if ok and mason.install_all then mason.install_all() end
        vim.defer_fn(function() 
          status_text = "Setup Complete! Opening Dashboard..."
          is_done = true
          vim.defer_fn(function()
            if vim.g.wizard_active then
              close_wizard()
              vim.g.wizard_active = false
              if vim.fn.argc() == 0 then
                local ok, dash = pcall(require, "configs.custom_dash")
                if ok and dash.open then dash.open() end
              end
            end
          end, 2000)
        end, 8000)
      end)
    end
  })
  
  if finish_cb then finish_cb() end
end

local function screen3()
  close_wizard()
  
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })

  local user_name = ""
  
  local function draw_s3()
    local max_width = math.max(20, vim.o.columns - 20)
    local disp_text = user_name .. "_"
    
    if vim.fn.strdisplaywidth(disp_text) < 20 then
      disp_text = disp_text .. string.rep(" ", 20 - vim.fn.strdisplaywidth(disp_text))
    end
    
    local wrapped_lines = {}
    while string.len(disp_text) > max_width do
      table.insert(wrapped_lines, string.sub(disp_text, 1, max_width))
      disp_text = string.sub(disp_text, max_width + 1)
    end
    table.insert(wrapped_lines, disp_text)

    local lines = {}
    for i=1, math.floor(vim.o.lines / 2) - 5 do table.insert(lines, "") end
    table.insert(lines, "        What is your name?")
    table.insert(lines, "")
    
    local input_start_row = #lines
    for _, wl in ipairs(wrapped_lines) do
      table.insert(lines, "        " .. wl)
    end
    
    table.insert(lines, "")
    table.insert(lines, "        Press <Enter> to confirm")
    
    draw_screen(lines, nil, nil)
    
    local ns = vim.api.nvim_create_namespace("wizard_hl")
    local sr = input_start_row - 1
    local er = input_start_row + #wrapped_lines
    local sc = 7
    local ec = 8 + math.max(20, vim.fn.strdisplaywidth(wrapped_lines[1])) + 1
    
    for r = sr, er do
      if r < #lines then
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, r, sc, {
          end_col = ec,
          hl_group = "Search",
        })
      end
    end
  end

  draw_s3()

  for i = 32, 126 do
    local char = string.char(i)
    local key = char
    if char == " " then key = "<Space>" end
    if char == "|" then key = "<Bar>" end
    if char == "\\" then key = "<Bslash>" end
    vim.keymap.set("n", key, function()
      user_name = user_name .. char
      draw_s3()
    end, { buffer = buf, nowait = true })
  end

  vim.keymap.set("n", "<BS>", function()
    user_name = string.sub(user_name, 1, -2)
    draw_s3()
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local data_dir = vim.fn.stdpath("config") .. "/data"
    if vim.fn.isdirectory(data_dir) == 0 then vim.fn.mkdir(data_dir, "p") end
    if user_name == "" then user_name = "User" end
    local file = io.open(data_dir .. "/user.json", "w")
    if file then file:write('{"name": "' .. user_name .. '"}') file:close() end
    os.remove(data_dir .. "/wizard_state.json")
    vim.schedule(function()
      screen4()
    end)
  end, { buffer = buf, nowait = true })
end

local function run_install_cmd(cmds)
  save_state(3)
  local full_cmd = table.concat(cmds, " && ")
  os.execute('start cmd /c "' .. full_cmd .. ' & echo. & echo Installation Complete! Please close this window and reopen Neovim. & pause"')
  vim.cmd("qa!")
end

local function screen2_5_win(missing)
  close_wizard()
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })

  local pms = {}
  if vim.fn.executable("winget") == 1 then table.insert(pms, "Winget") end
  if vim.fn.executable("scoop") == 1 then table.insert(pms, "Scoop") end
  if vim.fn.executable("choco") == 1 then table.insert(pms, "Choco") end

  local recommended = pms[1]
  local lines = {}
  for i=1, math.floor(vim.o.lines / 2) - 8 do table.insert(lines, "") end
  table.insert(lines, "        Choose your Windows Package Manager:")
  table.insert(lines, "")

  buttons = {}
  
  local function get_cmds(pm)
    local cmds = {}
    if pm == "Winget" then
      for _, d in ipairs(missing) do
         local pkg = d
         if d == "rg" then pkg = "BurntSushi.ripgrep.MSVC" end
         if d == "fd" then pkg = "sharkdp.fd" end
         if d == "gcc" then pkg = "BrechtSanders.WinLibs.POSIX.UCRT" end
         if d == "npm" then pkg = "OpenJS.NodeJS" end
         if d == "git" then pkg = "Git.Git" end
         if d == "unzip" then pkg = "GnuWin32.UnZip" end
         if d == "python" then pkg = "Python.Python.3.11" end
         if d == "go" then pkg = "GoLang.Go" end
         if d == "curl" then pkg = "cURL.cURL" end
         table.insert(cmds, "winget install -e --id " .. pkg .. " --source winget --accept-source-agreements --accept-package-agreements")
      end
    elseif pm == "Scoop" then
      for _, d in ipairs(missing) do
         local pkg = d
         if d == "rg" then pkg = "ripgrep" end
         table.insert(cmds, "scoop install " .. pkg)
      end
    elseif pm == "Choco" then
      for _, d in ipairs(missing) do
         local pkg = d
         if d == "rg" then pkg = "ripgrep" end
         table.insert(cmds, "choco install " .. pkg .. " -y")
      end
    end
    return cmds
  end

  if recommended then
    local btn_text = recommended .. " (Recommended)"
    table.insert(lines, "            " .. btn_text .. "  ")
    table.insert(buttons, { text = btn_text, row = #lines - 1, col_start = 10, col_end = 10 + 4 + #btn_text, action = function()
      run_install_cmd(get_cmds(recommended))
    end })
    table.insert(lines, "")
  else
    table.insert(lines, "")
    table.insert(lines, "")
    table.insert(lines, "")
  end

  table.insert(lines, "            Winget           Scoop           Choco  ")
  local row = #lines - 1
  table.insert(buttons, { text = "Winget", row = row, col_start = 10, col_end = 20, action = function() run_install_cmd(get_cmds("Winget")) end })
  table.insert(buttons, { text = "Scoop", row = row, col_start = 27, col_end = 36, action = function() run_install_cmd(get_cmds("Scoop")) end })
  table.insert(buttons, { text = "Choco", row = row, col_start = 43, col_end = 52, action = function() run_install_cmd(get_cmds("Choco")) end })

  selected_btn = 1
  draw_screen(lines, buttons, selected_btn)
  setup_menu_keys()
end

local function run_install_linux(pm_name, pm_cmd, missing)
  local pkgs_list = {}
  for _, d in ipairs(missing) do
    local pkg = d
    if pm_name == "APT" or pm_name == "DNF" then
      if d == "rg" then pkg = "ripgrep" end
      if d == "fd" then pkg = "fd-find" end
      if d == "python" then pkg = "python3" end
      if d == "go" then pkg = "golang" end
    elseif pm_name == "Pacman" then
      if d == "rg" then pkg = "ripgrep" end
    elseif pm_name == "Zypper" then
      if d == "rg" then pkg = "ripgrep" end
      if d == "python" then pkg = "python3" end
    elseif pm_name == "rpm-ostree" then
      if d == "rg" then pkg = "ripgrep" end
      if d == "fd" then pkg = "fd-find" end
      if d == "python" then pkg = "python3" end
      if d == "go" then pkg = "golang" end
    elseif pm_name == "Snap" then
      if d == "rg" then pkg = "ripgrep" end
    end
    table.insert(pkgs_list, pkg)
  end
  local pkgs = table.concat(pkgs_list, " ")
  save_state(3)
  os.execute('x-terminal-emulator -e bash -c "' .. pm_cmd .. " " .. pkgs .. '; echo; echo Installation Complete. Press enter to exit...; read"')
  vim.cmd("qa!")
end

local function screen2_5_linux(missing)
  close_wizard()
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })

  local pms = {
    { name = "APT", cmd = "sudo apt install -y", hint = "Debian/Ubuntu", bin = "apt" },
    { name = "DNF", cmd = "sudo dnf install -y", hint = "Fedora", bin = "dnf" },
    { name = "Pacman", cmd = "sudo pacman -S --noconfirm", hint = "Arch", bin = "pacman" },
    { name = "Zypper", cmd = "sudo zypper in -y", hint = "openSUSE", bin = "zypper" },
    { name = "Snap", cmd = "sudo snap install", hint = "Universal", bin = "snap" },
    { name = "rpm-ostree", cmd = "rpm-ostree install", hint = "Silverblue", bin = "rpm-ostree" }
  }

  local recommended = nil
  for _, pm in ipairs(pms) do
    if vim.fn.executable(pm.bin) == 1 then
      recommended = pm
      break
    end
  end

  local lines = {}
  for i=1, math.floor(vim.o.lines / 2) - 8 do table.insert(lines, "") end
  table.insert(lines, "        Choose your Linux Package Manager:")
  table.insert(lines, "")

  buttons = {}

  if recommended then
    local btn_text = recommended.name .. " (Recommended)"
    table.insert(lines, "            " .. btn_text .. "  ")
    table.insert(buttons, { text = btn_text, row = #lines - 1, col_start = 10, col_end = 10 + 4 + #btn_text, action = function()
      run_install_linux(recommended.name, recommended.cmd, missing)
    end })
    table.insert(lines, "")
  else
    table.insert(lines, "        Warning: We couldn't find your system's package manager.")
    table.insert(lines, "        Please check README.md to check all the dependencies.")
    table.insert(lines, "")
  end

  table.insert(lines, "            APT  Debian/Ubuntu          DNF  Fedora  ")
  local row1 = #lines - 1
  table.insert(buttons, { text = "APT", row = row1, col_start = 10, col_end = 17, action = function() run_install_linux(pms[1].name, pms[1].cmd, missing) end })
  table.insert(buttons, { text = "DNF", row = row1, col_start = 38, col_end = 45, action = function() run_install_linux(pms[2].name, pms[2].cmd, missing) end })

  table.insert(lines, "            Pacman  Arch                Zypper  openSUSE  ")
  local row2 = #lines - 1
  table.insert(buttons, { text = "Pacman", row = row2, col_start = 10, col_end = 20, action = function() run_install_linux(pms[3].name, pms[3].cmd, missing) end })
  table.insert(buttons, { text = "Zypper", row = row2, col_start = 38, col_end = 48, action = function() run_install_linux(pms[4].name, pms[4].cmd, missing) end })

  table.insert(lines, "            Snap  Universal             rpm-ostree  Silverblue  ")
  local row3 = #lines - 1
  table.insert(buttons, { text = "Snap", row = row3, col_start = 10, col_end = 18, action = function() run_install_linux(pms[5].name, pms[5].cmd, missing) end })
  table.insert(buttons, { text = "rpm-ostree", row = row3, col_start = 38, col_end = 52, action = function() run_install_linux(pms[6].name, pms[6].cmd, missing) end })

  selected_btn = 1
  draw_screen(lines, buttons, selected_btn)
  setup_menu_keys()
end

local function do_install(missing)
  local is_win = vim.fn.has("win32") == 1
  if is_win then
    screen2_5_win(missing)
  else
    screen2_5_linux(missing)
  end
end

local function render_screen2(missing)
  local lines = {}
  for i=1, math.floor(vim.o.lines / 2) - 10 do table.insert(lines, "") end
  
  table.insert(lines, "        System Dependency Check")
  table.insert(lines, "")
  if #missing == 0 then
    table.insert(lines, "        All dependencies are installed!")
    table.insert(lines, "")
    table.insert(lines, "            Next  ")
    buttons = { { text = "Next", row = #lines - 1, col_start = 10, col_end = 18, action = function() screen3() end } }
  else
    table.insert(lines, "        The following dependencies are missing:")
    for _, m in ipairs(missing) do table.insert(lines, "        - " .. m) end
    table.insert(lines, "")
    table.insert(lines, "            Install Automatically           Skip  ")
    buttons = {
      { text = "Install Automatically", row = #lines - 1, col_start = 10, col_end = 35, action = function() do_install(missing) end },
      { text = "Skip", row = #lines - 1, col_start = 42, col_end = 50, action = function() screen3() end }
    }
  end
  selected_btn = 1
  draw_screen(lines, buttons, selected_btn)
  setup_menu_keys()
end

local function screen2()
  close_wizard()
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })
  
  local missing = {}
  local is_win = vim.fn.has("win32") == 1
  local deps = {
    { cmd = "git", name = "git" },
    { cmd = "gcc", name = "gcc", alt = "clang" },
    { cmd = "npm", name = "npm" },
    { cmd = "rg", name = "rg" },
    { cmd = "fd", name = "fd", alt = "fdfind" },
    { cmd = "unzip", name = "unzip", alt = "7z" },
    { cmd = "python", name = "python", alt = "python3" },
    { cmd = "go", name = "go" },
    { cmd = "curl", name = "curl" }
  }
  
  for _, dep in ipairs(deps) do
    if vim.fn.executable(dep.cmd) == 0 then
      if dep.alt and vim.fn.executable(dep.alt) == 1 then
        -- alt exists, skip
      else
        table.insert(missing, dep.name)
      end
    end
  end
  render_screen2(missing)
end

local function render_screen1()
  local logo = {}
  local logo_path = vim.fn.stdpath("config") .. "/lua/configs/logo.txt"
  local f = io.open(logo_path, "r")
  if f then
    for line in f:lines() do table.insert(logo, line) end
    f:close()
  end
  
  local lines = {}
  for i=1, math.floor(vim.o.lines / 2) - 10 do table.insert(lines, "") end
  for _, l in ipairs(logo) do table.insert(lines, "    " .. l) end
  table.insert(lines, "")
  table.insert(lines, "        Welcome to Neovim IDE Setup")
  table.insert(lines, "")
  table.insert(lines, "            Begin Setup           Skip Setup  ")
  
  buttons = {
    { text = "Begin Setup", row = #lines - 1, col_start = 10, col_end = 25, action = function() screen2() end },
    { text = "Skip Setup", row = #lines - 1, col_start = 32, col_end = 46, action = function()
      close_wizard()
      vim.g.wizard_active = false
      local data_dir = vim.fn.stdpath("config") .. "/data"
        if vim.fn.isdirectory(data_dir) == 0 then vim.fn.mkdir(data_dir, "p") end
        local file = io.open(data_dir .. "/user.json", "w")
        if file then file:write('{"name": "User"}') file:close() end
        screen4()
    end }
  }
  selected_btn = 1
  draw_screen(lines, buttons, selected_btn)
  setup_menu_keys()
end

M.start = function(on_complete)
  vim.g.wizard_active = true
  finish_cb = on_complete

  -- Force focus back to the wizard after Neovim finishes initializing
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
    end,
    once = true,
  })
  
  local state = get_state()
  if state == 3 then
    return screen3()
  end

  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = vim.o.columns, height = vim.o.lines,
    col = 0, row = 0, style = "minimal", zindex = 250
  })
  
  render_screen1()
end

return M

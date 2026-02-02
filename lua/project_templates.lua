local Layout = require "nui.layout"
local Popup = require "nui.popup"
local Input = require "nui.input"

local M = {}

-- ====================================================
-- 🎨 1. COLORS & HIGHLIGHTS
-- ====================================================
local colors = require("base46").get_theme_tb "base_30"

-- UI Highlight Groups
vim.api.nvim_set_hl(0, "PCreatorMain", { bg = colors.darker_black, fg = colors.white })
vim.api.nvim_set_hl(0, "PCreatorSide", { bg = colors.darker_black, fg = colors.white })
vim.api.nvim_set_hl(0, "PCreatorBorder", { fg = colors.black })
vim.api.nvim_set_hl(0, "PCreatorTitle", { bg = colors.black2, fg = colors.nord_blue, bold = true })

-- Button Highlights
vim.api.nvim_set_hl(0, "PCreatorSBtnBorder", { fg = colors.vibrant_green })
vim.api.nvim_set_hl(0, "PCreatorSBtn", { bg = colors.green, fg = colors.black, bold = true })
vim.api.nvim_set_hl(0, "PCreatorBtn", { bg = colors.black, fg = colors.nord_blue, bold = true })
vim.api.nvim_set_hl(0, "PCreatorBtnBorder", { fg = colors.nord_blue })

-- Input Highlights
vim.api.nvim_set_hl(0, "PCreatorInput", { bg = colors.darker_black, fg = colors.nord_blue })

NewProject = function()
  -- 1. Create a blank buffer
  vim.cmd "enew"
  local new_buf_id = vim.api.nvim_get_current_buf()

  -- 2. Open NvimTree but keep focus here
  require("nvim-tree.api").tree.open()
  vim.cmd "wincmd p"

  -- 3. Open Telescope
  vim.schedule(function()
    require("telescope.builtin").filetypes {
      attach_mappings = function(prompt_bufnr, map)
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"

        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            local lang = selection[1]
            vim.api.nvim_set_option_value("filetype", lang, { buf = new_buf_id })

            -- Call our Nui Form module
            local project_gen = require "project_templates"

            -- Check if we have a custom form for this language
            if project_gen.langs[lang] then
              project_gen.langs[lang]()
            else
              print("No template found for: " .. lang .. ". Just set filetype.")
            end
          end
        end)
        return true
      end,
    }
  end)
end

NewFile = function()
  -- 1. Create a blank buffer (Untitled)
  vim.cmd "enew"

  -- 2. Capture the ID of this new buffer so we don't lose it
  local new_buf_id = vim.api.nvim_get_current_buf()

  -- 3. Open the Tree and restore focus to the editor
  require("nvim-tree.api").tree.open()
  vim.cmd "wincmd p"

  -- 4. Open Telescope with a Custom Action
  vim.schedule(function()
    require("telescope.builtin").filetypes {
      -- This 'attach_mappings' function lets us override what "Enter" does
      attach_mappings = function(prompt_bufnr, map)
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"

        actions.select_default:replace(function()
          -- a. Close Telescope
          actions.close(prompt_bufnr)

          -- b. Get the language you picked (e.g., 'cpp')
          local selection = action_state.get_selected_entry()

          if selection then
            -- c. FORCE the filetype onto our specific buffer
            vim.api.nvim_set_option_value("filetype", selection[1], { buf = new_buf_id })

            -- d. Optional: Print a confirmation message
            print("Language Mode set to: " .. selection[1])
          end
        end)
        return true
      end,
    }
  end)
end

function Spawn_template_project(lang)
  local templates = require "project_templates"
  -- If the language exists in our lua file, run it
  if templates[lang] then
    templates[lang]()
  else
    -- If the language isn't in our lua file, do nothing (as requested)
    print("No template for " .. lang)
  end
end

-- ====================================================
-- ⚙️ HELPER FUNCTIONS
-- ====================================================
local function clean_path(base, name)
  local path = base .. "/" .. name
  return path:gsub("//", "/")
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
  end
end

local function read_file(path)
  local configPath = "/home/vinim/.config/nvim/lua/"

  local file = io.open(configPath .. path, "r")
  if file then
    local content = file:read "*a"
    file:close()
    return content
  end
  return configPath .. path
end

local function set_focus(component)
  if component and component.winid and vim.api.nvim_win_is_valid(component.winid) then
    vim.api.nvim_set_current_win(component.winid)
    if component.is_input then
      vim.cmd "startinsert!"
    end
  end
end

-- ====================================================
-- 🖥️ UI ENGINE
-- ====================================================
local function project_creator(config, on_submit)
  local title_text = config.title or " Project Creator "
  local fields = config.fields
  local preview_lines = config.preview or {}

  -- 1. Ensure Path Field Exists
  local has_path = false
  for _, f in ipairs(fields) do
    if f.id == "path" then
      has_path = true
    end
  end
  if not has_path then
    table.insert(fields, 2, { id = "path", label = "Location", default = vim.fn.getcwd() })
  end

  local input_objects = {}
  local focusable = {}
  local nodes = {}

  -- 2. CREATE TITLE POPUP
  local title_popup = Popup {
    enter = false,
    focusable = false,
    border = { style = "single", text = { top = "NVim Project Creator", top_align = "center" } },
    win_options = { winhighlight = "Normal:PCreatorTitle,FloatBorder:PCreatorBorder" },
  }
  vim.api.nvim_buf_set_lines(title_popup.bufnr, 0, 1, false, { title_text })

  -- 3. CREATE INPUTS (Left Side)
  local inputs_height = 0
  for _, f in ipairs(fields) do
    if f.type == "text" then
      local p = Popup {
        enter = false,
        focusable = false,
        border = { style = "none" },
        win_options = { winhighlight = "Normal:PCreatorMain" },
      }
      vim.api.nvim_buf_set_lines(p.bufnr, 0, -1, false, { " " .. f.label })
      table.insert(nodes, Layout.Box(p, { size = 1 }))
      inputs_height = inputs_height + 1
    else
      local i = Input({
        enter = true,
        border = { style = "rounded", text = { top = " " .. f.label .. " " } },
        win_options = { winhighlight = "Normal:PCreatorInput,FloatBorder:PCreatorBorder" },
      }, { default_value = f.default or "" })

      i.is_input = true
      input_objects[f.id] = i
      table.insert(focusable, i)
      table.insert(nodes, Layout.Box(i, { size = 3 }))
      inputs_height = inputs_height + 3
    end
  end

  -- 4. CREATE SIDEBAR (Right Side)
  local sidebar = Popup {
    enter = false,
    focusable = false,
    border = { style = "rounded", text = { top = " Info " } },
    win_options = { winhighlight = "Normal:PCreatorSide,FloatBorder:PCreatorBorder" },
  }
  vim.api.nvim_buf_set_lines(sidebar.bufnr, 0, -1, false, preview_lines)
  local sidebar_height = math.max(#preview_lines + 2, inputs_height)

  -- 5. GAP FIX: FILLER
  -- If Sidebar is taller than Inputs, add a filler box to the Left Side
  if sidebar_height > inputs_height then
    local filler = Popup {
      enter = false,
      focusable = false,
      border = { style = "none" },
      win_options = { winhighlight = "Normal:PCreatorMain" }, -- Matches Input background
    }
    table.insert(nodes, Layout.Box(filler, { size = sidebar_height - inputs_height }))
  end

  -- 6. CREATE BUTTONS
  local Sbtn = Popup {
    enter = true,
    focusable = true,
    border = { style = "double" },
    win_options = { winhighlight = "Normal:PCreatorSBtn,FloatBorder:PCreatorSBtnBorder" },
    buf_options = { modifiable = false, readonly = true },
  }
  vim.api.nvim_buf_set_lines(Sbtn.bufnr, 0, 1, false, { " [ 󰣪 BUILD PROJECT ] " })

  local Cbtn = Popup {
    enter = true,
    focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
    buf_options = { modifiable = false, readonly = true },
  }
  vim.api.nvim_buf_set_lines(Cbtn.bufnr, 0, 1, false, { " [ CHANGE LANGUAGE ] " })

  table.insert(focusable, Sbtn)
  table.insert(focusable, Cbtn)

  -- 7. LAYOUT ASSEMBLY (Calculated Integer Heights)
  local title_h = 3
  local btn_h = 3
  local body_h = sidebar_height
  local total_h = title_h + body_h + btn_h

  local layout = Layout(
    {
      relative = "editor",
      position = "50%",
      size = { width = 80, height = total_h },
    },
    Layout.Box({
      -- Top: Title
      Layout.Box(title_popup, { size = title_h }),

      -- Middle: Body
      Layout.Box({
        Layout.Box(nodes, { dir = "col", size = "60%" }),
        Layout.Box(sidebar, { size = "40%" }),
      }, { dir = "row", size = body_h }),

      -- Bottom: Buttons
      Layout.Box({
        Layout.Box(Sbtn, { size = "60%" }),
        Layout.Box(Cbtn, { size = "40%" }),
      }, { dir = "row", size = btn_h }),
    }, { dir = "col" })
  )

  layout:mount()

  -- 8. EVENT HANDLING
  local function trigger_submit()
    local final_data = {}
    for id, ui_obj in pairs(input_objects) do
      local lines = vim.api.nvim_buf_get_lines(ui_obj.bufnr, 0, -1, false)
      final_data[id] = vim.trim(table.concat(lines, ""))
    end
    layout:unmount()

    if not final_data.name or final_data.name == "" then
      print " Project name cannot be empty!"
      return
    end
    if final_data.path then
      final_data.path = final_data.path:gsub("/$", "")
    end
    on_submit(final_data)
  end

  for i, comp in ipairs(focusable) do
    for _, mode in ipairs { "n", "i" } do
      -- Tab Navigation
      comp:map(mode, "<Tab>", function()
        local next_idx = (i % #focusable) + 1
        set_focus(focusable[next_idx])
      end, { noremap = true })

      comp:map(mode, "<S-Tab>", function()
        local prev_idx = (i - 1)
        if prev_idx == 0 then
          prev_idx = #focusable
        end
        set_focus(focusable[prev_idx])
      end, { noremap = true })

      -- Esc to Close
      comp:map(mode, "<Esc>", function()
        layout:unmount()
      end, { noremap = true })
    end

    -- Enter Key Logic
    if comp == Sbtn then
      comp:map("n", "<CR>", trigger_submit, { noremap = true })
    elseif comp == Cbtn then
      comp:map("n", "<CR>", function()
        vim.cmd "AdvancedNewProject"
        layout:unmount()
      end, { noremap = true })
    else
      for _, mode in ipairs { "n", "i" } do
        comp:map(mode, "<CR>", function()
          if focusable[i + 1] then
            set_focus(focusable[i + 1])
          else
            set_focus(Sbtn)
          end
        end, { noremap = true })
      end
    end
  end

  -- Initial Focus
  vim.schedule(function()
    if focusable[1] then
      set_focus(focusable[1])
    end
  end)
end

-- ==========================================
-- 🚀 TEMPLATES
-- ==========================================

M.langs = {
c = function()
    project_creator({
      title = " New  C Project ",
      preview = {
        "",
        "   C Project",
        "",
        " Types:",
        " - 1: Exe ",
        " - 2: Lib ",
        "",
        " Standards:",
        "   C++17, 20, 23, 26",
        "",
        " Generates:",
        "  - main.cpp",
        "  - CMakeLists.txt",
        "  - build/",
        "",
        " 󰄉 Ready to code.",
      },
      fields = {
        { id = "name", label = "Project Name" },
        { type = "text", label = "Type: 1=Exe, 2=Lib" },
        { id = "type", label = "Project Type", default = "1" },
        { id = "ver", label = "Standard", default = "23" },
      },
    }, function(data)
      local full_path = clean_path(data.path, data.name)
      vim.fn.mkdir(full_path, "p")

      local main = read_file "templates/c/main.c"
      local cmake
      local target = data.type

      if target == "1" then
        cmake = read_file "templates/c/exe.txt"
      else
        cmake = read_file "templates/c/lib.txt"
      end

      cmake = string.format(cmake, data.name, data.ver, data.name)

      write_file(full_path .. "/main.c", main)
      write_file(full_path .. "/CMakeLists.txt", cmake)

      local makefile_template = read_file "templates/cpp/Makefile"
      local makefile = string.format(makefile_template, data.name)
      write_file(full_path .. "/Makefile", makefile)

      vim.api.nvim_set_current_dir(full_path)

      -- Open using ABSOLUTE path
      vim.cmd("edit " .. full_path .. "/main.c")

      vim.fn.system "make generate"
    end)
  end,

  cpp = function()
    project_creator({
      title = " New  C++ Project ",
      preview = {
        "",
        "   C++ Project",
        "",
        " Types:",
        " - 1: Exe ",
        " - 2: Lib ",
        "",
        " Standards:",
        "   C++17, 20, 23, 26",
        "",
        " Generates:",
        "  - main.cpp",
        "  - CMakeLists.txt",
        "  - build/",
        "",
        " 󰄉 Ready to code.",
      },
      fields = {
        { id = "name", label = "Project Name" },
        { type = "text", label = "Type: 1=Exe, 2=Lib" },
        { id = "type", label = "Project Type", default = "1" },
        { id = "ver", label = "Standard", default = "23" },
      },
    }, function(data)
      local full_path = clean_path(data.path, data.name)
      vim.fn.mkdir(full_path, "p")

      local main = read_file "templates/cpp/main.cpp"
      local cmake
      local target = data.type

      if target == "1" then
        cmake = read_file "templates/cpp/exe.txt"
      else
        cmake = read_file "templates/cpp/lib.txt"
      end

      cmake = string.format(cmake, data.name, data.ver, data.name)

      write_file(full_path .. "/main.cpp", main)
      write_file(full_path .. "/CMakeLists.txt", cmake)

      local makefile_template = read_file "templates/cpp/Makefile"
      local makefile = string.format(makefile_template, data.name)
      write_file(full_path .. "/Makefile", makefile)

      vim.api.nvim_set_current_dir(full_path)

      -- Open using ABSOLUTE path
      vim.cmd("edit " .. full_path .. "/main.cpp")

      vim.fn.system "make generate"
    end)
  end,

  python = function()
    project_creator({
      title = " New  Python Project ",
      preview = {
        "",
        "   Python Project",
        "",
        " Generates:",
        "  - Virtual Env (venv)",
        "  - main.py",
        "",
        " ⚡ Auto-activates",
        "    local interpreter",
      },
      fields = { { id = "name", label = "Project Name" } },
    }, function(data)
      local full_path = clean_path(data.path, data.name)
      vim.fn.mkdir(full_path, "p")
      local cmd_prefix = "cd " .. full_path .. " && "
      print "Creating venv..."
      vim.fn.system(cmd_prefix .. "python3 -m venv venv")
      write_file(
        full_path .. "/main.py",
        "def main():\n    print('Hello Python!')\n\nif __name__ == '__main__':\n    main()"
      )

      vim.api.nvim_set_current_dir(full_path)
      vim.cmd("edit " .. full_path .. "/main.py")
    end)
  end,

  web = function()
    project_creator({
      title = " New 󰖟 Web Project ",
      preview = { "", " 󰖟  Web Bundle", "", " Generates:", "  - index.html", "  - style.css", "  - script.js" },
      fields = { { id = "name", label = "Project Name" } },
    }, function(data)
      local full_path = clean_path(data.path, data.name)
      vim.fn.mkdir(full_path, "p")
      write_file(
        full_path .. "/index.html",
        "<!DOCTYPE html>\n<html lang='en'>\n<head>\n  <meta charset='UTF-8'>\n  <meta name='viewport' content='width=device-width, initial-scale=1.0'>\n  <link rel='stylesheet' href='style.css'>\n  <title>"
          .. data.name
          .. "</title>\n</head>\n<body>\n  <h1>Welcome to "
          .. data.name
          .. "</h1>\n  <script src='script.js'></script>\n</body>\n</html>"
      )
      write_file(
        full_path .. "/style.css",
        "body {\n  font-family: sans-serif;\n  background: #222;\n  color: #fff;\n  display: flex;\n  justify-content: center;\n  align-items: center;\n  height: 100vh;\n  margin: 0;\n}"
      )
      write_file(full_path .. "/script.js", "console.log('Project Loaded');")

      vim.api.nvim_set_current_dir(full_path)
      vim.cmd("edit " .. full_path .. "/index.html")
    end)
  end,

  go = function()
    project_creator({
      title = " New   Go Project ",
      preview = { "", "  Go Module", "", " Generates:", "  - go.mod", "  - main.go", "", "Go Mod Init" },
      fields = { { id = "name", label = "Project Name" }, { id = "mod", label = "Module Path (opt)", default = "" } },
    }, function(data)
      local full_path = clean_path(data.path, data.name)
      vim.fn.mkdir(full_path, "p")
      local mod_name = (data.mod ~= "") and data.mod or data.name
      local cmd_prefix = "cd " .. full_path .. " && "
      vim.fn.system(cmd_prefix .. "go mod init " .. mod_name)
      write_file(full_path .. "/main.go", read_file "templates/go/main.go")

      local makefile_template = read_file "templates/go/Makefile"
      local makefile = string.format(makefile_template, data.name)
      write_file(full_path .. "/Makefile", makefile)

      vim.api.nvim_set_current_dir(full_path)
      vim.cmd("edit " .. full_path .. "/main.go")
    end)
  end,

  rust = function()
    project_creator({
      title = " New  Rust Creator ",
      preview = { "", "   Cargo Project", "", " Generates:", "  - Cargo.toml", "  - src/main.rs" },
      fields = { { id = "name", label = "Project Name" } },
    }, function(data)
      local cmd = "cd " .. data.path .. " && cargo new " .. data.name
      vim.fn.system(cmd)
      local full_path = clean_path(data.path, data.name)
      vim.api.nvim_set_current_dir(full_path)

      local makefile_template = read_file "templates/rust/Makefile"
      local makefile = string.format(makefile_template, data.name)
      write_file(full_path .. "/Makefile", makefile)

      vim.cmd("edit " .. full_path .. "/src/main.rs")
    end)
  end,

  cs = function()
    project_creator({
      title = " New  C-Sharp Creator ",
      preview = { "", "   C-Sharp Project", "", " Generates:", "  - Program.cs" },
      fields = { { id = "name", label = "Project Name" } },
    }, function(data)
      local cmd = "cd " .. data.path .. " && dotnet new console -n " .. data.name
      vim.fn.system(cmd)
      local full_path = clean_path(data.path, data.name)
      vim.api.nvim_set_current_dir(full_path)
      vim.cmd("edit " .. full_path .. "/Program.cs")
    end)
  end,
}

local Debug = function()
  vim.fn.system "make build -B"
  require("dap").continue()
end

local Run = function()
  require("nvchad.term").toggle { pos = "float", id = "runner", cmd = "clear && make run" }
end

vim.api.nvim_create_user_command("NewProject", function()
  NewProject()
end, {})

vim.api.nvim_create_user_command("Debug", function()
  Debug()
end, {})

vim.api.nvim_create_user_command("Run", function()
  Run()
end, {})

return M

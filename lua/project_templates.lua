local Layout = require "nui.layout"
local Popup = require "nui.popup"
local Input = require "nui.input"

local M = {}

local colors = require("base46").get_theme_tb "base_30"

vim.api.nvim_set_hl(0, "PCreatorMain", { bg = colors.darker_black, fg = colors.white })
vim.api.nvim_set_hl(0, "PCreatorSide", { bg = colors.darker_black, fg = colors.white })
vim.api.nvim_set_hl(0, "PCreatorBorder", { fg = colors.black })
vim.api.nvim_set_hl(0, "PCreatorTitle", { bg = colors.black2, fg = colors.nord_blue, bold = true })

vim.api.nvim_set_hl(0, "PCreatorSBtnBorder", { fg = colors.vibrant_green })
vim.api.nvim_set_hl(0, "PCreatorSBtn", { bg = colors.green, fg = colors.black, bold = true })
vim.api.nvim_set_hl(0, "PCreatorBtn", { bg = colors.black, fg = colors.nord_blue, bold = true })
vim.api.nvim_set_hl(0, "PCreatorBtnBorder", { fg = colors.nord_blue })

vim.api.nvim_set_hl(0, "PCreatorInput", { bg = colors.darker_black, fg = colors.nord_blue })

NewProject = function()
  vim.cmd "enew"
  local new_buf_id = vim.api.nvim_get_current_buf()

  require("nvim-tree.api").tree.open()
  vim.cmd "wincmd p"

  vim.schedule(function()
    require("telescope.builtin").filetypes {
      attach_mappings = function(prompt_bufnr, _)
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"

        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            local lang = selection[1]
            vim.api.nvim_set_option_value("filetype", lang, { buf = new_buf_id })

            if M.langs[lang] then
              vim.schedule(function()
                M.langs[lang](function(json_new_project)
                  if not json_new_project then
                    return
                  end

                  local path = vim.fn.stdpath "config" .. "/projects.json"
                  local file = io.open(path, "r")
                  local content = ""

                  if file then
                    content = file:read "*a"
                    file:close()
                  end

                  local ok, lista_projetos = pcall(vim.json.decode, content)
                  if not ok or type(lista_projetos) ~= "table" then
                    lista_projetos = {}
                  end

                  table.insert(lista_projetos, json_new_project)

                  local file_save = io.open(path, "w")
                  if file_save then
                    local json_string = vim.json.encode(lista_projetos)
                    file_save:write(json_string)
                    file_save:close()
                  end
                end)
              end)
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
  vim.cmd "enew"

  local new_buf_id = vim.api.nvim_get_current_buf()

  require("nvim-tree.api").tree.open()
  vim.cmd "wincmd p"

  vim.schedule(function()
    require("telescope.builtin").filetypes {
      attach_mappings = function(prompt_bufnr, map)
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"

        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = action_state.get_selected_entry()

          if selection then
            vim.api.nvim_set_option_value("filetype", selection[1], { buf = new_buf_id })

            print("Language Mode set to: " .. selection[1])
          end
        end)
        return true
      end,
    }
  end)
end

local function get_projects()
  local path = vim.fn.stdpath "config" .. "/projects.json"
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local content = file:read "*a"
  file:close()
  local ok, parsed = pcall(vim.json.decode, content)
  return (ok and type(parsed) == "table") and parsed or {}
end

local function save_projects(projects)
  local path = vim.fn.stdpath "config" .. "/projects.json"
  local file = io.open(path, "w")
  if file then
    file:write(vim.json.encode(projects))
    file:close()
  end
end

local function ProjectManager()
  local projects = get_projects()
  local current_idx = 1

  local btn_new_proj = Popup {
    enter = true,
    focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
  }
  vim.api.nvim_buf_set_lines(btn_new_proj.bufnr, 0, -1, false, { "  [  NEW PROJECT ]  " })

  local btn_new_file = Popup {
    enter = false,
    focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
  }
  vim.api.nvim_buf_set_lines(btn_new_file.bufnr, 0, -1, false, { "   [ 󰈔 NEW FILE ]   " })

  local list_popup = Popup {
    enter = false,
    focusable = true,
    border = { style = "rounded", text = { top = " Projects " } },
    win_options = { cursorline = true, winhighlight = "Normal:PCreatorMain,FloatBorder:PCreatorBorder" },
  }

  local details_popup = Popup {
    enter = false,
    focusable = false,
    border = { style = "rounded", text = { top = " Details " } },
    win_options = { winhighlight = "Normal:PCreatorSide,FloatBorder:PCreatorBorder" },
  }

  local btn_open = Popup {
    enter = false,
    focusable = true,
    border = { style = "double" },
    win_options = { winhighlight = "Normal:PCreatorSBtn,FloatBorder:PCreatorSBtnBorder" },
  }
  vim.api.nvim_buf_set_lines(btn_open.bufnr, 0, -1, false, { "    [ 󰝰 OPEN ]    " })

  local btn_del = Popup {
    enter = false,
    focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorTitle,FloatBorder:PCreatorBorder" },
  }
  vim.api.nvim_buf_set_lines(btn_del.bufnr, 0, -1, false, { "   [ 󰆴 DELETE ]   " })

  local function draw_list()
    local lines = {}
    if #projects == 0 then
      table.insert(lines, "  No projects found.")
    else
      for _, p in ipairs(projects) do
        table.insert(lines, string.format(" %s  %s", p.lang or "󰅩", p.name or "Unknown"))
      end
    end
    vim.api.nvim_set_option_value("modifiable", true, { buf = list_popup.bufnr })
    vim.api.nvim_buf_set_lines(list_popup.bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = list_popup.bufnr })
  end

  local function update_details(idx)
    local p = projects[idx]
    local lines = {}
    if p then
      lines = {
        "",
        " 󰏗 Name:  " .. (p.name or "N/A"),
        " 󰌧 Lang:  " .. (p.lang or "N/A"),
        " 󰃰 Date:  " .. (p.date or "N/A"),
        "",
        "  Path: ",
        "   " .. (p.path or "N/A"),
      }
    else
      lines = { "", "  Select a project to view details." }
    end
    vim.api.nvim_set_option_value("modifiable", true, { buf = details_popup.bufnr })
    vim.api.nvim_buf_set_lines(details_popup.bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = details_popup.bufnr })
  end

  draw_list()
  update_details(1)

  local layout = Layout(
    { relative = "editor", position = "50%", size = { width = 80, height = 24 } },
    Layout.Box({
      Layout.Box({
        Layout.Box(btn_new_proj, { size = "50%" }),
        Layout.Box(btn_new_file, { size = "50%" }),
      }, { dir = "row", size = 3 }),

      Layout.Box({
        Layout.Box(list_popup, { size = "40%" }),

        Layout.Box({
          Layout.Box(details_popup, { size = "80%" }),
          Layout.Box({
            Layout.Box(btn_open, { size = "50%" }),
            Layout.Box(btn_del, { size = "50%" }),
          }, { dir = "row", size = 3 }),
        }, { dir = "col", size = "60%" }),
      }, { dir = "row", size = 21 }),
    }, { dir = "col" })
  )
  layout:mount()

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = list_popup.bufnr,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(list_popup.winid)[1]
      if row > 0 and row <= #projects then
        current_idx = row
        update_details(current_idx)
      end
    end,
  })

  local focusable = { btn_new_proj, btn_new_file, list_popup, btn_open, btn_del }

  for i, comp in ipairs(focusable) do
    for _, mode in ipairs { "n", "i" } do
      comp:map(mode, "<Tab>", function()
        local next_idx = (i % #focusable) + 1
        vim.api.nvim_set_current_win(focusable[next_idx].winid)
      end, { noremap = true })

      comp:map(mode, "<S-Tab>", function()
        local prev_idx = (i - 1 == 0) and #focusable or (i - 1)
        vim.api.nvim_set_current_win(focusable[prev_idx].winid)
      end, { noremap = true })

      comp:map(mode, "<Esc>", function()
        layout:unmount()
      end, { noremap = true })
      comp:map(mode, "q", function()
        layout:unmount()
      end, { noremap = true })
    end

    comp:map("n", "<CR>", function()
      if comp == btn_new_proj then
        layout:unmount()
        NewProject()
      elseif comp == btn_new_file then
        layout:unmount()
        NewFile()
      elseif comp == btn_open or comp == list_popup then
        local target = projects[current_idx]
        if target and target.path then
          layout:unmount()
          vim.cmd("cd " .. vim.fn.fnameescape(target.path))
          require("nvim-tree.api").tree.open()
          vim.notify("Opened " .. target.name, vim.log.levels.INFO)
        end
      elseif comp == btn_del then
        if #projects > 0 then
          local removed = table.remove(projects, current_idx)
          save_projects(projects)
          current_idx = math.max(1, current_idx - 1)
          draw_list()
          update_details(current_idx)
          vim.notify("Deleted " .. removed.name, vim.log.levels.WARN)
        end
      end
    end, { noremap = true })
  end

  vim.schedule(function()
    vim.api.nvim_set_current_win(list_popup.winid)
  end)
end

vim.api.nvim_create_user_command("ProjectManager", ProjectManager, {})

function Spawn_template_project(lang)
  local templates = require "project_templates"
  if templates[lang] then
    templates[lang]()
  else
    print("No template for " .. lang)
  end
end

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
  local configPath = vim.fn.stdpath "config" .. "/lua/"

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

local function project_creator(config, on_submit)
  local title_text = config.title or " Project Creator "
  local fields = config.fields
  local preview_lines = config.preview or {}

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

  local title_popup = Popup {
    enter = false,
    focusable = false,
    border = { style = "single", text = { top = "NVim Project Creator", top_align = "center" } },
    win_options = { winhighlight = "Normal:PCreatorTitle,FloatBorder:PCreatorBorder" },
  }
  vim.api.nvim_buf_set_lines(title_popup.bufnr, 0, 1, false, { title_text })

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

  local sidebar = Popup {
    enter = false,
    focusable = false,
    border = { style = "rounded", text = { top = " Info " } },
    win_options = { winhighlight = "Normal:PCreatorSide,FloatBorder:PCreatorBorder" },
  }
  vim.api.nvim_buf_set_lines(sidebar.bufnr, 0, -1, false, preview_lines)
  local sidebar_height = math.max(#preview_lines + 2, inputs_height)

  if sidebar_height > inputs_height then
    local filler = Popup {
      enter = false,
      focusable = false,
      border = { style = "none" },
      win_options = { winhighlight = "Normal:PCreatorMain" },
    }
    table.insert(nodes, Layout.Box(filler, { size = sidebar_height - inputs_height }))
  end

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
      Layout.Box(title_popup, { size = title_h }),

      Layout.Box({
        Layout.Box(nodes, { dir = "col", size = "60%" }),
        Layout.Box(sidebar, { size = "40%" }),
      }, { dir = "row", size = body_h }),

      Layout.Box({
        Layout.Box(Sbtn, { size = "60%" }),
        Layout.Box(Cbtn, { size = "40%" }),
      }, { dir = "row", size = btn_h }),
    }, { dir = "col" })
  )

  layout:mount()

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

      comp:map(mode, "<Esc>", function()
        layout:unmount()
      end, { noremap = true })
    end

    if comp == Sbtn then
      comp:map("n", "<CR>", trigger_submit, { noremap = true })
    elseif comp == Cbtn then
      comp:map("n", "<CR>", function()
        vim.cmd "NewProject"
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

  vim.schedule(function()
    if focusable[1] then
      set_focus(focusable[1])
    end
  end)
end

M.langs = {
  c = function(on_complete)
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
        "   C99, C11, C17, C23",
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
      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.c"))

      vim.fn.system "make generate"

      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "",
        }
      end
    end)
  end,

  cpp = function(on_complete)
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

      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.cpp"))

      vim.fn.system "make generate"
      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "",
        }
      end
    end)
  end,

  python = function(on_complete)
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
      local cmd_prefix = "cd " .. vim.fn.shellescape(full_path) .. " && "
      print "Creating venv..."
      vim.fn.system(cmd_prefix .. "python3 -m venv venv")
      write_file(
        full_path .. "/main.py",
        "def main():\n    print('Hello Python!')\n\nif __name__ == '__main__':\n    main()"
      )

      vim.api.nvim_set_current_dir(full_path)
      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.py"))

      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "",
        }
      end
    end)
  end,

  web = function(on_complete)
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
      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/index.html"))
      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "󰖟",
        }
      end
    end)
  end,

  go = function(on_complete)
    return project_creator({
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
      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.go"))

      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "󰟓",
        }
      end
    end)
  end,

  rust = function(on_complete)
    return project_creator({
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

      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/src/main.rs"))

      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "",
        }
      end
    end)
  end,

  cs = function(on_complete)
    return project_creator({
      title = " New  C-Sharp Creator ",
      preview = { "", "   C-Sharp Project", "", " Generates:", "  - Program.cs" },
      fields = {
        { id = "name", label = "Project Name" },
      },
    }, function(data)
      local cmd = "cd " .. data.path .. " && dotnet new console -n " .. data.name
      vim.fn.system(cmd)
      local full_path = clean_path(data.path, data.name)
      vim.api.nvim_set_current_dir(full_path)

      local makefile_template = read_file "templates/cs/Makefile"
      local makefile = string.format(makefile_template, data.name)
      write_file(full_path .. "/Makefile", makefile)

      vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/Program.cs"))

      if on_complete then
        on_complete {
          name = data.name,
          path = full_path,
          date = os.date "%Y/%m/%d",
          lang = "",
        }
      end
    end)
  end,
}

local Debug = function()
  vim.fn.system "make build -B"
  require("dap").continue()
end

local Run = function()
  vim.cmd "terminal make run"
end

vim.api.nvim_create_user_command("NewProject", function()
  NewProject()
end, {})

vim.api.nvim_create_user_command("NewFile", function()
  NewFile()
end, {})

vim.api.nvim_create_user_command("Debug", function()
  Debug()
end, {})

vim.api.nvim_create_user_command("Run", function()
  Run()
end, {})

return M

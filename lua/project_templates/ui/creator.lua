local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Input = require("nui.input")

local M = {}

local function set_focus(component)
  if component and component.winid and vim.api.nvim_win_is_valid(component.winid) then
    vim.api.nvim_set_current_win(component.winid)
    if component.is_input then
      vim.cmd("startinsert!")
    end
  end
end

M.create = function(config, on_submit)
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

  -- Add Git field
  table.insert(fields, { id = "init_git", label = "Init Git (y/n)", default = "y" })

  local input_objects = {}
  local focusable = {}
  local nodes = {}

  local title_popup = Popup({
    enter = false,
    focusable = false,
    border = { style = "single", text = { top = "NVim Project Creator", top_align = "center" } },
    win_options = { winhighlight = "Normal:PCreatorTitle,FloatBorder:PCreatorBorder" },
  })
  vim.api.nvim_buf_set_lines(title_popup.bufnr, 0, 1, false, { title_text })

  local inputs_height = 0
  for _, f in ipairs(fields) do
    if f.type == "text" then
      local p = Popup({
        enter = false,
        focusable = false,
        border = { style = "none" },
        win_options = { winhighlight = "Normal:PCreatorMain" },
      })
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

  local sidebar = Popup({
    enter = false,
    focusable = false,
    border = { style = "rounded", text = { top = " Info " } },
    win_options = { winhighlight = "Normal:PCreatorSide,FloatBorder:PCreatorBorder" },
  })
  vim.api.nvim_buf_set_lines(sidebar.bufnr, 0, -1, false, preview_lines)
  local sidebar_height = math.max(#preview_lines + 2, inputs_height)

  if sidebar_height > inputs_height then
    local filler = Popup({
      enter = false,
      focusable = false,
      border = { style = "none" },
      win_options = { winhighlight = "Normal:PCreatorMain" },
    })
    table.insert(nodes, Layout.Box(filler, { size = sidebar_height - inputs_height }))
  end

  local Sbtn = Popup({
    enter = true,
    focusable = true,
    border = { style = "double" },
    win_options = { winhighlight = "Normal:PCreatorSBtn,FloatBorder:PCreatorSBtnBorder" },
    buf_options = { modifiable = false, readonly = true },
  })
  vim.api.nvim_buf_set_lines(Sbtn.bufnr, 0, 1, false, { " [ 󰣪 BUILD PROJECT ] " })

  local Cbtn = Popup({
    enter = true,
    focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
    buf_options = { modifiable = false, readonly = true },
  })
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
      print("Project name cannot be empty!")
      return
    end
    if final_data.path then
      final_data.path = final_data.path:gsub("/$", "")
    end
    
    -- Transform git string to boolean
    final_data.init_git = (final_data.init_git:lower() == "y")

    on_submit(final_data)
  end

  for i, comp in ipairs(focusable) do
    for _, mode in ipairs({ "n", "i" }) do
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
        vim.cmd("NewProject")
        layout:unmount()
      end, { noremap = true })
    else
      for _, mode in ipairs({ "n", "i" }) do
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

return M

local Layout = require("nui.layout")
local Popup = require("nui.popup")
local core = require("project_templates.core")

local M = {}

local function open_in_telescope(projects)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Projects",
    finder = finders.new_table({
      results = projects,
      entry_maker = function(entry)
        return {
          value = entry,
          display = (entry.lang or "") .. " " .. (entry.name or "Unknown"),
          ordinal = entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local target = selection.value
          vim.cmd("cd " .. vim.fn.fnameescape(target.path))
          require("nvim-tree.api").tree.open()
          vim.notify("Opened " .. target.name, vim.log.levels.INFO)
        end
      end)
      return true
    end,
  }):find()
end

M.open = function()
  local projects = core.get_projects()
  local current_idx = 1
  local sort_by_date = false

  local function sort_projects()
    table.sort(projects, function(a, b)
      if sort_by_date then
        return (a.date or "") > (b.date or "")
      else
        return (a.name:lower() or "") < (b.name:lower() or "")
      end
    end)
  end

  sort_projects()

  local btn_new_proj = Popup({
    enter = true, focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
  })
  vim.api.nvim_buf_set_lines(btn_new_proj.bufnr, 0, -1, false, { "  [  NEW PROJECT ]  " })

  local btn_telescope = Popup({
    enter = false, focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorBtn,FloatBorder:PCreatorBtnBorder" },
  })
  vim.api.nvim_buf_set_lines(btn_telescope.bufnr, 0, -1, false, { "  [  TELESCOPE ]  " })

  local list_popup = Popup({
    enter = false, focusable = true,
    border = { style = "rounded", text = { top = " Projects (Press 's' to sort) " } },
    win_options = { cursorline = true, winhighlight = "Normal:PCreatorMain,FloatBorder:PCreatorBorder" },
  })

  local details_popup = Popup({
    enter = false, focusable = false,
    border = { style = "rounded", text = { top = " Details & Stats " } },
    win_options = { winhighlight = "Normal:PCreatorSide,FloatBorder:PCreatorBorder" },
  })

  local btn_open = Popup({
    enter = false, focusable = true,
    border = { style = "double" },
    win_options = { winhighlight = "Normal:PCreatorSBtn,FloatBorder:PCreatorSBtnBorder" },
  })
  vim.api.nvim_buf_set_lines(btn_open.bufnr, 0, -1, false, { "      󰝰 OPEN      " })

  local btn_opt = Popup({
    enter = false, focusable = true,
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:PCreatorTitle,FloatBorder:PCreatorBorder" },
  })
  vim.api.nvim_buf_set_lines(btn_opt.bufnr, 0, -1, false, { "      OPTIONS     " })

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

  local function get_dir_size(path)
    -- Rough estimation or default if not implemented fully across OS
    return "Unknown"
  end

  local function update_details(idx)
    local p = projects[idx]
    local lines = {}
    if p then
      local stat = vim.uv.fs_stat(p.path)
      local modified = stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "Unknown"

      lines = {
        "",
        " 󰏗 Name:  " .. (p.name or "N/A"),
        " 󰌧 Lang:  " .. (p.lang or "N/A"),
        " 󰃰 Created: " .. (p.date or "N/A"),
        " 󰚰 Modified: " .. modified,
        "",
        "  Path: ",
        "   " .. (p.path or "N/A"),
        "",
        "  Size/Lines: " .. get_dir_size(p.path)
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
    { relative = "editor", position = "50%", size = { width = 90, height = 26 } },
    Layout.Box({
      Layout.Box({
        Layout.Box(btn_new_proj, { size = "50%" }),
        Layout.Box(btn_telescope, { size = "50%" }),
      }, { dir = "row", size = 3 }),

      Layout.Box({
        Layout.Box(list_popup, { size = "40%" }),

        Layout.Box({
          Layout.Box(details_popup, { size = "80%" }),
          Layout.Box({
            Layout.Box(btn_open, { size = "50%" }),
            Layout.Box(btn_opt, { size = "50%" }),
          }, { dir = "row", size = 3 }),
        }, { dir = "col", size = "60%" }),
      }, { dir = "row", size = 23 }),
    }, { dir = "col" })
  )
  layout:mount()

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = list_popup.bufnr,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(list_popup.winid)[1]
      if #projects > 0 and row > 0 and row <= #projects then
        current_idx = row
        update_details(current_idx)
      end
    end,
  })

  local focusable = { btn_new_proj, btn_telescope, list_popup, btn_open, btn_opt }

  for i, comp in ipairs(focusable) do
    for _, mode in ipairs({ "n", "i" }) do
      comp:map(mode, "<Tab>", function()
        local next_idx = (i % #focusable) + 1
        vim.api.nvim_set_current_win(focusable[next_idx].winid)
      end, { noremap = true })

      comp:map(mode, "<S-Tab>", function()
        local prev_idx = (i - 1 == 0) and #focusable or (i - 1)
        vim.api.nvim_set_current_win(focusable[prev_idx].winid)
      end, { noremap = true })

      comp:map(mode, "<Esc>", function() layout:unmount() end, { noremap = true })
      comp:map(mode, "q", function() layout:unmount() end, { noremap = true })
    end

    if comp == list_popup then
      comp:map("n", "s", function()
        sort_by_date = not sort_by_date
        sort_projects()
        draw_list()
        update_details(current_idx)
      end, { noremap = true })
    end

    comp:map("n", "<CR>", function()
      if comp == btn_new_proj then
        layout:unmount()
        vim.cmd("NewProject")
      elseif comp == btn_telescope then
        layout:unmount()
        open_in_telescope(projects)
      elseif comp == btn_open or comp == list_popup then
        local target = projects[current_idx]
        if target and target.path then
          layout:unmount()
          vim.cmd("cd " .. vim.fn.fnameescape(target.path))
          require("nvim-tree.api").tree.open()
          vim.notify("Opened " .. target.name, vim.log.levels.INFO)
        end
      elseif comp == btn_opt then
        if #projects > 0 then
          local target = projects[current_idx]
          -- Simple options menu
          local opt_menu = Popup({
            enter = true, focusable = true,
            border = { style = "rounded", text = { top = " Options " } },
            position = "50%", size = { width = 30, height = 2 },
            win_options = { winhighlight = "Normal:PCreatorMain,FloatBorder:PCreatorBorder" }
          })
          opt_menu:mount()
          vim.api.nvim_buf_set_lines(opt_menu.bufnr, 0, -1, false, { " 1. Rename Project", " 2. Delete Project" })
          
          opt_menu:map("n", "1", function()
            opt_menu:unmount()
            vim.ui.input({ prompt = "New Name: ", default = target.name }, function(input)
              if input and input ~= "" then
                projects[current_idx].name = input
                core.save_projects(projects)
                draw_list()
                update_details(current_idx)
              end
            end)
          end, { noremap = true })

          opt_menu:map("n", "2", function()
            opt_menu:unmount()
            local removed = table.remove(projects, current_idx)
            core.save_projects(projects)
            current_idx = math.max(1, current_idx - 1)
            draw_list()
            update_details(current_idx)
            vim.notify("Deleted " .. removed.name, vim.log.levels.WARN)
          end, { noremap = true })

          opt_menu:map("n", "<Esc>", function() opt_menu:unmount() end, { noremap = true })
          opt_menu:map("n", "q", function() opt_menu:unmount() end, { noremap = true })
        end
      end
    end, { noremap = true })
  end

  vim.schedule(function()
    vim.api.nvim_set_current_win(list_popup.winid)
  end)
end

return M

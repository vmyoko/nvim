local core = require("project_templates.core")

local M = {}
M.langs = {}

local function load_templates()
  local path = vim.fn.stdpath("config") .. "/lua/project_templates/langs/"
  local handle = vim.uv.fs_scandir(path)
  if handle then
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end
      if type == "file" and name:match("%.lua$") then
        local lang = name:gsub("%.lua$", "")
        M.langs[lang] = require("project_templates.langs." .. lang)
      end
    end
  end
end

M.NewProject = function()
  load_templates()
  local langs_list = {}
  for k, _ in pairs(M.langs) do
    table.insert(langs_list, k)
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  vim.cmd("enew")
  require("nvim-tree.api").tree.open()
  vim.cmd("wincmd p")

  pickers.new({}, {
    prompt_title = "Select Template",
    finder = finders.new_table({ results = langs_list }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local lang = selection[1]
          vim.schedule(function()
            M.langs[lang](function(project_data)
              if project_data then
                core.add_project(project_data)
              end
            end)
          end)
        end
      end)
      return true
    end,
  }):find()
end

M.NewFile = function()
  vim.cmd("enew")
  local new_buf_id = vim.api.nvim_get_current_buf()
  require("nvim-tree.api").tree.open()
  vim.cmd("wincmd p")

  require("telescope.builtin").filetypes({
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
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
  })
end

M.ProjectManager = function()
  require("project_templates.ui.manager").open()
end

M.Debug = function()
  vim.fn.system("make build -B")
  require("dap").continue()
end

M.Run = function()
  vim.cmd("terminal make run")
end

-- Global function to spawn template directly
_G.Spawn_template_project = function(lang)
  load_templates()
  if M.langs[lang] then
    M.langs[lang](function(project_data)
      if project_data then
        core.add_project(project_data)
      end
    end)
  else
    print("No template for " .. lang)
  end
end

-- Setup Commands
vim.api.nvim_create_user_command("NewProject", M.NewProject, {})
vim.api.nvim_create_user_command("NewFile", M.NewFile, {})
vim.api.nvim_create_user_command("ProjectManager", M.ProjectManager, {})
vim.api.nvim_create_user_command("Debug", M.Debug, {})
vim.api.nvim_create_user_command("Run", M.Run, {})

return M

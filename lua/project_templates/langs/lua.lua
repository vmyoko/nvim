local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  Lua Project ",
    preview = { "", "   Lua Scripting", "", " Generates:", "  - main.lua" },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")
    core.write_file(full_path .. "/main.lua", "print('Hello Lua!')\n")

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.lua"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end

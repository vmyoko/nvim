local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  React Project ",
    preview = { "", "   React + Vite", "", " Uses vite to scaffold", " a new React project." },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    print("Scaffolding Vite React app...")
    local cmd = "cd " .. vim.fn.shellescape(data.path) .. " && npm create vite@latest " .. data.name .. " -- --template react-ts"
    vim.fn.system(cmd)

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/src/App.tsx"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end

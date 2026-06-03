local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  Python Project ",
    preview = {
      "", "   Python Project", "", " Generates:",
      "  - Virtual Env (venv)", "  - main.py", "", " ⚡ Auto-activates", "    local interpreter",
    },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")
    local cmd_prefix = "cd " .. vim.fn.shellescape(full_path) .. " && "
    print("Creating venv...")
    vim.fn.system(cmd_prefix .. "python3 -m venv venv")
    core.write_file(
      full_path .. "/main.py",
      "def main():\n    print('Hello Python!')\n\nif __name__ == '__main__':\n    main()"
    )

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.py"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end

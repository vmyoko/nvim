local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  Go Project ",
    preview = { "", "  Go Module", "", " Generates:", "  - go.mod", "  - main.go", "  - Makefile" },
    fields = { { id = "name", label = "Project Name" }, { id = "mod", label = "Module Path", default = "" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")
    local mod_name = (data.mod ~= "") and data.mod or data.name
    local cmd_prefix = "cd " .. vim.fn.shellescape(full_path) .. " && "
    vim.fn.system(cmd_prefix .. "go mod init " .. mod_name)
    core.write_file(full_path .. "/main.go", "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello Go!\")\n}\n")

    local makefile = core.read_template("go", "Makefile")
    if makefile:match("^Template file not found") then
      makefile = "build:\n\tgo build\nrun:\n\tgo run main.go\n"
    else
      makefile = string.format(makefile, data.name)
    end
    core.write_file(full_path .. "/Makefile", makefile)

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.go"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "󰟓" })
    end
  end)
end

local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  Rust Creator ",
    preview = { "", "   Cargo Project", "", " Generates:", "  - Cargo.toml", "  - src/main.rs" },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local cmd = "cd " .. vim.fn.shellescape(data.path) .. " && cargo new " .. data.name
    vim.fn.system(cmd)
    local full_path = core.clean_path(data.path, data.name)
    
    local makefile = core.read_template("rust", "Makefile")
    if makefile:match("^Template file not found") then
      makefile = "build:\n\tcargo build\nrun:\n\tcargo run\n"
    else
      makefile = string.format(makefile, data.name)
    end
    core.write_file(full_path .. "/Makefile", makefile)

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/src/main.rs"))

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end

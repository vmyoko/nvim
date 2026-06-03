local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New  C++ Project ",
    preview = {
      "", "   C++ Project", "", " Types:", " - 1: Exe ", " - 2: Lib ",
      "", " Standards:", "   C++17, 20, 23, 26", "", " Generates:",
      "  - main.cpp", "  - CMakeLists.txt", "  - Makefile", "", " 󰄉 Ready to code.",
    },
    fields = {
      { id = "name", label = "Project Name" },
      { type = "text", label = "Type: 1=Exe, 2=Lib" },
      { id = "type", label = "Project Type", default = "1" },
      { id = "ver", label = "Standard", default = "23" },
    },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")

    local main = core.read_template("cpp", "main.cpp")
    local cmake = core.read_template("cpp", data.type == "1" and "exe.txt" or "lib.txt")
    cmake = string.format(cmake, data.name, data.ver, data.name)

    core.write_file(full_path .. "/main.cpp", main)
    core.write_file(full_path .. "/CMakeLists.txt", cmake)

    local makefile_template = core.read_template("cpp", "Makefile")
    local makefile = string.format(makefile_template, data.name)
    core.write_file(full_path .. "/Makefile", makefile)

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/main.cpp"))
    vim.fn.system("make generate")

    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "" })
    end
  end)
end

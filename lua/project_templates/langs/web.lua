local creator = require("project_templates.ui.creator")
local core = require("project_templates.core")

return function(on_complete)
  creator.create({
    title = " New 󰖟 Web Project ",
    preview = { "", " 󰖟  Web Bundle", "", " Generates:", "  - index.html", "  - style.css", "  - script.js" },
    fields = { { id = "name", label = "Project Name" } },
  }, function(data)
    local full_path = core.clean_path(data.path, data.name)
    vim.fn.mkdir(full_path, "p")
    core.write_file(
      full_path .. "/index.html",
      "<!DOCTYPE html>\n<html lang='en'>\n<head>\n  <meta charset='UTF-8'>\n  <meta name='viewport' content='width=device-width, initial-scale=1.0'>\n  <link rel='stylesheet' href='style.css'>\n  <title>"
        .. data.name
        .. "</title>\n</head>\n<body>\n  <h1>Welcome to "
        .. data.name
        .. "</h1>\n  <script src='script.js'></script>\n</body>\n</html>"
    )
    core.write_file(
      full_path .. "/style.css",
      "body {\n  font-family: sans-serif;\n  background: #222;\n  color: #fff;\n  display: flex;\n  justify-content: center;\n  align-items: center;\n  height: 100vh;\n  margin: 0;\n}"
    )
    core.write_file(full_path .. "/script.js", "console.log('Project Loaded');")

    core.setup_git(full_path, data.init_git, data.setup_ci)

    vim.api.nvim_set_current_dir(full_path)
    vim.cmd("edit " .. vim.fn.fnameescape(full_path .. "/index.html"))
    if on_complete then
      on_complete({ name = data.name, path = full_path, date = os.date("%Y/%m/%d"), lang = "󰖟" })
    end
  end)
end

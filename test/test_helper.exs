for dir <- ["full", "initable", "empty", "missing_template_dir", "missing_template"] do
  System.cmd("mix", ["deps.get"], cd: "test/projects/#{dir}")
  System.cmd("mix", ["compile"], cd: "test/projects/#{dir}")
end

ExUnit.start()

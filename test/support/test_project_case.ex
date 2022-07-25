defmodule Eject.TestProjectCase do
  use ExUnit.CaseTemplate

  setup do
    cwd = File.cwd!()

    # set alternative working directory so that Path.wildcard and Path.expand
    # start within the test corral
    File.cd("test/support/test_project")

    # restore working directory
    on_exit(fn -> File.cd(cwd) end)
  end
end

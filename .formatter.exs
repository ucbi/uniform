locals_without_parens = [
  app: 1,
  app_lib: 1,
  cp: 1,
  cp: 2,
  cp_r: 1,
  cp_r: 2,
  eject: 1,
  except: 1,
  file: 1,
  file: 2,
  lib: 1,
  lib: 2,
  lib_deps: 1,
  modify: 2,
  mix: 1,
  mix: 2,
  mix_deps: 1,
  only: 1,
  preserve: 1,
  template: 1,
  template: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

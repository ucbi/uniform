locals_without_parens = [
  app: 1,
  binary: 1,
  cp_r: 1,
  file: 1,
  lib: 2,
  mix: 2,
  preserve: 1,
  template: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]

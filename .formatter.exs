# Used by "mix format"
[
  import_deps: [:phoenix_live_view],
  plugins: [Styler],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [assert_icon: 2, refute_icon: 2],
  export: [
    locals_without_parens: [assert_icon: 2, refute_icon: 2]
  ]
]

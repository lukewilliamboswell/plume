app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import plume.Scatter

main! = \_ -> Ok {}

expect

    _ =
        when Scatter.new { data : []} is
            Ok asdf -> Scatter.to_str asdf
            Err _ -> crash ""

    1 == 2

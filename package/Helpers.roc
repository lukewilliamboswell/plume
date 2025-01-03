module [non_empty_str]

non_empty_str : Str -> Bool
non_empty_str = \s -> !(Str.isEmpty s)

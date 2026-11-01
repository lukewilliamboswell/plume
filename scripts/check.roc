#!/usr/bin/env roc-stable
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	roc: "nightly-2026-10-18-1df370f",
}

import cli.Cmd
import cli.OsStr
import cli.Path
import cli.Stdout

## Run the same source and consumer checks locally and on a pull request.
main! : List(OsStr) => Try({}, _)
main! = |_args| {
	run!({ program: "roc", args: ["version"] })?
	run!({ program: "roc-stable", args: ["version"] })?
	run!({ program: "roc", args: ["fmt", "--check", "Blueprint.roc", "package", "examples", "tests"] })?
	run!({ program: "roc-stable", args: ["fmt", "--check", "scripts"] })?
	run!({ program: "roc", args: ["test", "--opt=dev", "package/main.roc"] })?
	for root in ["examples", "tests"] {
		for path in roc_sources!(Path.utf8(root))? {
			source = path.read_utf8!()?
			if source.contains("app [main!]") {
				if source.contains("roc: \"") {
					return Err(ProductCompilerPin(path.display()))
				}
				run!({ program: "roc", args: ["test", "--opt=dev", path.display()] })?
			}
		}
	}
	run!({ program: "release-package", args: ["test-examples"] })?
	Stdout.line!("PASS formatting, package and consumer expects, and recorded examples")?
	Ok({})
}

roc_sources! : Path => Try(List(Path), _)
roc_sources! = |directory| {
	var $sources = []
	for path in directory.list!()? {
		if path.is_dir!()? {
			$sources = $sources.concat(roc_sources!(path)?)
		} else if path.ext().map_ok(Path.display) == Ok("roc") {
			$sources = $sources.append(path)
		}
	}
	Ok($sources)
}

run! : { program : Str, args : List(Str) } => Try({}, _)
run! = |{ program, args }| {
	Stdout.line!("+ ${program} ${Str.join_with(args, " ")}")?
	Cmd.new(OsStr.from_str(program)).args(args.map(OsStr.from_str)).timeout_ms(300_000).manage_tree(True).exec_cmd!()
}

#!/usr/bin/env roc-stable
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	roc: "nightly-2026-10-18-1df370f",
}

import cli.Cmd
import cli.Env
import cli.OsStr
import cli.Path
import cli.Stdout

## Run the same source and consumer checks locally and on a pull request.
main! : List(OsStr) => Try({}, _)
main! = |_args| {
	run!({ program: "roc", args: ["version"] })?
	run!({ program: "roc-stable", args: ["version"] })?
	run!({ program: "roc", args: ["fmt", "--check", "Blueprint.roc", "package", "examples", "tests", "fuzz"] })?
	run!({ program: "roc-stable", args: ["fmt", "--check", "scripts"] })?
	run!({ program: "roc", args: ["test", "--opt=dev", "package/main.roc"] })?
	check_fuzz!()?
	for root in ["examples", "tests"] {
		for path in roc_sources!(Path.utf8(root))? {
			source = path.read_utf8!()?
			if source.contains("app [main!]") {
				if source.contains("roc: \"") {
					return Err(ProductCompilerPin(path.display()))
				}
				run!({ program: "roc", args: ["test", "--opt=dev", path.display()] })?
				if root == "tests" {
					run!({ program: "roc", args: [path.display()] })?
				}
			}
		}
	}
	run!({ program: "release-package", args: ["test-examples"] })?
	Stdout.line!("PASS formatting, package and consumer expects, bounded fuzz checks, and recorded examples")?
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

## The published fuzz host and committed allocation profile target x64 Linux.
## Other systems still run the source/consumer suite and report this exclusion.
check_fuzz! : () => Try({}, _)
check_fuzz! = || {
	host_platform = Env.platform!()
	match (host_platform.arch, host_platform.os) {
		(X64, LINUX) => {
			# roc-fuzz 0.5 permits unbaselined checks. Require the committed
			# target/profile explicitly so a missing file or profile fails CI.
			baseline : {
				format : Str,
				target : Str,
				entries : List({ host_target : Str, profile : Str, metric_version : Str }),
			}
			baseline = Json.parse(Path.utf8("fuzz/serialization-baseline.json").read_utf8!()?)?
			profiles = baseline.entries.keep_if(|entry| entry.host_target == "x64musl" and entry.profile == "linux-x64-speed" and entry.metric_version == "roc-fuzz-allocations/1")
			if baseline.format != "roc-fuzz-baseline/1" or baseline.target != "plume-serialization" or profiles.len() != 1 {
				return Err(InvalidFuzzBaseline("expected one linux-x64-speed profile for plume-serialization"))
			}
			run!({ program: "roc", args: ["test", "--opt=dev", "fuzz/serialization.roc"] })?
			Path.utf8(".fuzz-out").create_all!()?
			run!({ program: "roc", args: ["build", "--fuzz", "--opt=speed", "--target=x64musl", "--output=.fuzz-out/serialization", "fuzz/serialization.roc"] })?
			# run checks every named example and the allocation baseline before
			# exploring. Missing/stale baselines fail; this never accepts them.
			args = [
				"run",
				".roc-fuzz/corpus",
				"--baseline=fuzz/serialization-baseline.json",
				"--profile=linux-x64-speed",
				"--runs=16",
				"--time=1",
				"--timeout=2",
				"--max-input-size=512",
				"--seed=1",
			]
			Stdout.line!("+ .fuzz-out/serialization ${Str.join_with(args, " ")}")?
			Cmd.new(OsStr.from_str(".fuzz-out/serialization"))
				.args(args.map(OsStr.from_str))
				.timeout_ms(10_000)
				.manage_tree(True)
				.exec_cmd!()?
			Ok({})
		}
		_ => Stdout.line!("SKIP native fuzz: committed allocation baseline supports x64 Linux only")
	}
}

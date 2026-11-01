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

Case : { name : Str, args : List(Str), stdin : Str, stdout : Str, stderr : Str, exit_code : I32 }

Application : { path : Str, cases : List(Case) }

## Build the current examples once, then check or explicitly update their
## README screenshots with the pinned headless browser used by CI.
main! : List(OsStr) => Try({}, _)
main! = |args| {
	text_args = args.map_try(OsStr.to_str_try)?
	match text_args {
		[] => render!(Check)
		["--update"] => render!(Update)
		_ => Err(Usage({ expected: "screenshots [--update]", received: text_args }))
	}
}

ScreenshotMode : [Check, Update]

mode_args : ScreenshotMode -> List(Str)
mode_args = |mode| match mode {
	Check => []
	Update => ["--update"]
}

render! : ScreenshotMode => Try({}, _)
render! = |mode| {
	run!({ program: "roc", args: ["version"] })?
	root = Env.cwd!()?
	output = root.join(".screenshots-out")
	output.join("build").create_all!()?
	output.join("html").create_all!()?
	specification : { apps : List(Application) }
	specification = Json.parse(root.join("tests/spec.json").read_utf8!()?)?
	declared = specification.apps.map(|application| application.path)
	observed = discover_examples!(Path.utf8("examples"))?
	if !is_same_inventory({ declared, observed }) {
		return Err(ScreenshotInventory({ declared, observed }))
	}
	var $examples = []
	for application in specification.apps {
		name = screenshot_name(application.path)?
		selected = application.cases.keep_if(|case| case.exit_code == 0).first() ? |_| NoSuccessfulExampleCase(application.path)
		Stdout.line!("Build screenshot source: ${application.path} (${selected.name})")?
		executable = output.join("build").join(name)
		run!({ program: "roc", args: ["build", "--opt=dev", "--output=${executable.display()}", application.path] })?
		filename = Path.utf8(application.path).filename()?.display()
		parent = Path.utf8(application.path.drop_suffix(filename))
		actual = Cmd.new(executable.to_os_str())
			.args(selected.args.map(OsStr.from_str))
			.cwd(parent)
			.stdin(Bytes(selected.stdin.to_utf8()))
			.timeout_ms(30_000)
			.manage_tree(True)
			.exec_output!()?
		if actual.stdout_utf8 != selected.stdout or actual.stderr_utf8_lossy != selected.stderr {
			return Err(ExampleOutputChanged({ path: application.path, case: selected.name }))
		}
		if !actual.stdout_utf8.trim_start().starts_with("<!doctype html>") {
			return Err(ExampleDidNotProduceHtml(application.path))
		}
		output.join("html").join("${name}.html").write_utf8!(actual.stdout_utf8)?
		$examples = $examples.append({ name, source: application.path, case_name: selected.name })
	}
	manifest = Json.to_str({ format: "plume-screenshot-inputs/1", examples: $examples })
	output.join("manifest.json").write_utf8!("${manifest}\n")?
	run!({
		program: "node",
		args: [
			"tools/screenshots/render.mjs",
			"--workspace",
			root.display(),
			"--output",
			output.display(),
			"--baselines",
			root.join("examples/demo-images").display(),
		].concat(mode_args(mode)),
	})?
	Ok({})
}

run! : { program : Str, args : List(Str) } => Try({}, _)
run! = |{ program, args }| {
	Stdout.line!("+ ${program} ${Str.join_with(args, " ")}")?
	Cmd.new(OsStr.from_str(program)).args(args.map(OsStr.from_str)).timeout_ms(600_000).manage_tree(True).exec_cmd!()
}

discover_examples! : Path => Try(List(Str), _)
discover_examples! = |directory| {
	var $apps = []
	for path in directory.list!()? {
		if path.is_dir!()? {
			$apps = $apps.concat(discover_examples!(path)?)
		} else if path.ext().map_ok(Path.display) == Ok("roc") {
			source = path.read_utf8!()?
			if source.split_on("\n").any(|line| line.trim_start().starts_with("app [")) {
				$apps = $apps.append(path.display())
			}
		}
	}
	Ok($apps)
}

screenshot_name : Str -> Try(Str, [InvalidExamplePath(Str)])
screenshot_name = |source| {
	name = match source.split_on("/") {
		["examples", file] if file.ends_with(".roc") => file.drop_suffix(".roc")
		["examples", directory, "main.roc"] => directory
		_ => return Err(InvalidExamplePath(source))
	}
	if name.is_empty() or !name.to_utf8().all(|byte| (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == '-') {
		return Err(InvalidExamplePath(source))
	}
	Ok(name)
}

## File and directory examples use the same public gallery name convention.
expect screenshot_name("examples/chart.roc") == Ok("chart") and screenshot_name("examples/chart/main.roc") == Ok("chart")

## Paths outside examples and ambiguous names never become screenshot filenames.
expect ["../chart.roc", "examples/../chart.roc", "examples/chart.png", "examples/a.b.roc"].all(|path| screenshot_name(path).is_err())

is_same_inventory : { declared : List(Str), observed : List(Str) } -> Bool
is_same_inventory = |{ declared, observed }| !declared.is_empty() and declared.len() == observed.len() and declared.all(|source| observed.contains(source)) and observed.all(|source| declared.contains(source))

## Directory traversal order never changes the screenshot inventory.
expect is_same_inventory({ declared: ["a", "b"], observed: ["b", "a"] })

## Missing, duplicated or empty source inventories cannot reduce visual coverage.
expect !is_same_inventory({ declared: ["a", "a"], observed: ["a", "b"] }) and !is_same_inventory({ declared: ["a"], observed: ["a", "b"] }) and !is_same_inventory({ declared: [], observed: [] })

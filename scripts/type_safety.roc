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

Contract : { id : Str, purpose : Str, module_names : List(Str), positive : Str, negative : Str, diagnostics : List(Str) }

ObservedStatus : [Exited(I32), Signaled(I32), Timeout, OutputLimit, IO]

CheckResult : { id : Str, kind : Str, expected_exit : I32, status : Str, diagnostics_satisfied : Bool, source_unchanged : Bool, passed : Bool }

## Compile paired external consumers with the product compiler. A positive
## control must pass for every rejected program, so broken imports or compiler
## setup cannot make a negative API contract appear to pass.
main! : List(OsStr) => Try({}, _)
main! = |_args| {
	manifest : { format : Str, cases : List(Contract) }
	manifest = Json.parse(Path.utf8("tests/type-safety/cases.json").read_utf8!()?)?
	if manifest.format != "plume-type-safety/1" or manifest.cases.is_empty() {
		return Err(InvalidTypeSafetyManifest("expected plume-type-safety/1 and a nonempty set of contracts"))
	}
	var $ids = Set.empty()
	for contract in manifest.cases {
		is_safe_id = !contract.id.is_empty() and contract.id.to_utf8().all(|byte| (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == '-')
		if !is_safe_id or $ids.contains(contract.id) or contract.positive.is_empty() or contract.negative.is_empty() or contract.diagnostics.is_empty() or contract.diagnostics.any(Str.is_empty) {
			return Err(InvalidTypeSafetyManifest(contract.id))
		}
		$ids = $ids.insert(contract.id)
	}
	roots = match Env.var_str!("RUNNER_TEMP") {
		Ok(temp) if !temp.is_empty() => [Path.utf8(".fuzz-out/type-safety"), Path.utf8(temp).join("release-package").join("type-safety")]
		_ => [Path.utf8(".fuzz-out/type-safety")]
	}
	for root in roots {
		root.create_all!()?
	}
	var $results = []
	for contract in manifest.cases {
		Stdout.line!("type safety: ${contract.id} — ${contract.purpose}")?
		for kind in [Positive, Negative] {
			result = check_contract!({ roots, contract, kind })?
			$results = $results.append(result)
		}
	}
	results = $results
	passed = results.all(|result| result.passed)
	report = Json.to_str({ format: "plume-type-safety-report/1", compiler: "roc", timeout_ms: 60_000.U64, passed, results })
	persist!(roots, { name: "report.json", contents: "${report}\n" })?
	if !passed {
		failed = results.keep_if(|result| !result.passed).map(|result| "${result.id}/${result.kind} (${result.status})")
		return Err(TypeSafetyContractFailed(Str.join_with(failed, ", ")))
	}
	Stdout.line!("PASS ${manifest.cases.len().to_str()} paired type-safety contracts (${results.len().to_str()} compiler checks)")?
	Ok({})
}

check_contract! : { roots : List(Path), contract : Contract, kind : [Positive, Negative] } => Try(CheckResult, _)
check_contract! = |{ roots, contract, kind }| {
	kind_name = match kind {
		Positive => "positive"
		Negative => "negative"
	}
	expected_exit : I32
	expected_exit = match kind {
		Positive => 0
		Negative => 1
	}
	required_diagnostics = match kind {
		Positive => []
		Negative => contract.diagnostics
	}
	module_imports = Str.join_with(contract.module_names.map(|name| "import plume.${name}"), "\n")
	body = match kind {
		Positive => contract.positive
		Negative => contract.negative
	}
	indented = Str.join_with(body.split_on("\n").map(|line| "    ${line}"), "\n")
	source =
		\\app [main!] {
		\\    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
		\\    plume: "../../package/main.roc",
		\\}
		\\import cli.OsStr
		\\${module_imports}
		\\
		\\main! : List(OsStr) => Try({}, _)
		\\main! = |_args| {
		\\${indented}
		\\    Ok({})
		\\}
	base_name = "${contract.id}-${kind_name}"
	source_path = Path.utf8(".fuzz-out/type-safety/${base_name}.roc")
	persist!(roots, { name: "${base_name}.roc", contents: "${source}\n" })?
	output = Cmd.new("roc")
		.args(["check", "--no-cache", source_path.to_os_str()])
		.timeout_ms(60_000)
		.output_limit(2_000_000)
		.manage_tree(True)
		.run!()
	observed = match output {
		Ok(result) => {
			status : ObservedStatus
			status = match result.status {
				Exited(code) => Exited(code)
				Signaled(signal) => Signaled(signal)
			}
			{ status, stdout: Str.from_utf8_lossy(result.stdout_bytes), stderr: Str.from_utf8_lossy(result.stderr_bytes) }
		}
		Err(Timeout(partial)) => { status: Timeout, stdout: Str.from_utf8_lossy(partial.stdout_bytes), stderr: Str.from_utf8_lossy(partial.stderr_bytes) }
		Err(OutputLimit(partial)) => { status: OutputLimit, stdout: Str.from_utf8_lossy(partial.stdout_bytes), stderr: Str.from_utf8_lossy(partial.stderr_bytes) }
		Err(IO(error)) => { status: IO, stdout: "", stderr: Str.inspect(error) }
	}
	combined = "${observed.stdout}\n${observed.stderr}"
	unchanged = source_path.read_utf8!()? == "${source}\n"
	result = {
		id: contract.id,
		kind: kind_name,
		expected_exit,
		status: Str.inspect(observed.status),
		diagnostics_satisfied: required_diagnostics.all(|needle| combined.contains(needle)),
		source_unchanged: unchanged,
		passed: unchanged and is_expected_result({ expected_exit, status: observed.status, required_diagnostics, output: combined }),
	}
	persist!(roots, { name: "${base_name}.stdout.txt", contents: observed.stdout })?
	persist!(roots, { name: "${base_name}.stderr.txt", contents: observed.stderr })?
	persist!(roots, { name: "${base_name}.status.json", contents: "${Json.to_str(result)}\n" })?
	Ok(result)
}

## Only the intended ordinary exit code counts; crashes, warnings, execution
## failures and exhausted budgets never satisfy a compile-fail contract.
is_expected_result : { expected_exit : I32, status : ObservedStatus, required_diagnostics : List(Str), output : Str } -> Bool
is_expected_result = |{ expected_exit, status, required_diagnostics, output }| match status {
	Exited(code) => code == expected_exit and required_diagnostics.all(|needle| output.contains(needle))
	_ => False
}

persist! : List(Path), { name : Str, contents : Str } => Try({}, _)
persist! = |roots, { name, contents }| {
	for root in roots {
		root.join(name).write_utf8!(contents)?
	}
	Ok({})
}

## An intended compiler rejection needs both exit one and its diagnostic.
expect is_expected_result({ expected_exit: 1, status: Exited(1), required_diagnostics: ["opaque", "Coordinate"], output: "Coordinate is an opaque type" })

## A warning-only exit cannot satisfy a negative contract.
expect !is_expected_result({ expected_exit: 1, status: Exited(2), required_diagnostics: ["opaque"], output: "opaque" })

## A generic compiler error cannot satisfy a different intended rejection.
expect !is_expected_result({ expected_exit: 1, status: Exited(1), required_diagnostics: ["opaque"], output: "import not found" })

## Signals and all exhausted execution budgets fail even with matching text.
expect [Signaled(11), Timeout, OutputLimit, IO].all(|status| !is_expected_result({ expected_exit: 1, status, required_diagnostics: ["opaque"], output: "opaque" }))

## Positive controls require a completely successful compiler invocation.
expect is_expected_result({ expected_exit: 0, status: Exited(0), required_diagnostics: [], output: "" }) and !is_expected_result({ expected_exit: 0, status: Exited(1), required_diagnostics: [], output: "" })

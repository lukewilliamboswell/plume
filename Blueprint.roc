# Product checks use the current nightly on PATH. Released automation tools
# and the compiler that runs scripts have independent, reviewed lock entries.
app [config] { pf: platform "https://github.com/lukewilliamboswell/roc-blueprint/releases/download/0.11.0/EuSPs8vc71qJNFg29YzegvVRL1bR9pKqUYDHFiSCPTQ1.tar.zst" }

import pf.Recipes

config = [
	Name("plume"),
	Systems(["x86_64-linux", "aarch64-linux", "aarch64-darwin"]),
	Environment("package", [Programs([Fetch("roc-stable", Recipes.roc_nightly("nightly-2026-10-18-1df370f")), Fetch("release-package", Recipes.file("https://github.com/lukewilliamboswell/roc-automation/releases/download/tools-0.8.0/release-package-{system}"))]), Expect(["roc"])]),
	Environment("release", [Programs([Fetch("release-package", Recipes.file("https://github.com/lukewilliamboswell/roc-automation/releases/download/tools-0.8.0/release-package-{system}"))]), Expect(["roc", "git", "gh", "tar", "unzip", "zip", "chmod", "touch", "env"])]),
	Environment("release-test", [Programs([Fetch("release-package", Recipes.file("https://github.com/lukewilliamboswell/roc-automation/releases/download/tools-0.8.0/release-package-{system}"))]), Expect(["roc"])]),
	Environment("docs", [Programs([Fetch("roc-docs", Recipes.file("https://github.com/lukewilliamboswell/roc-automation/releases/download/tools-0.8.0/roc-docs-{system}"))]), Expect(["sh", "realpath"])]),
	Task("check", [Use("package"), Run(["roc-stable", "scripts/check.roc"])]),
	Task("test", [Use("package"), Run(["roc", "test", "--opt=dev", "package/main.roc"])]),
	Task("type-safety", [Use("package"), Run(["roc-stable", "scripts/type_safety.roc"])]),
	Task("release-package", [Use("release"), Run(["release-package"])]),
	Task("release-test", [Use("release-test"), Run(["release-package"])]),
	Task("docs", [Use("docs"), Run(["roc-docs", "build", "--workspace", ".", "--pdf-filename", "plume.pdf"])]),
	Task("docs-path", [Use("docs"), Run(["sh", "-c", "realpath \"$(command -v roc-docs)\""])]),
]

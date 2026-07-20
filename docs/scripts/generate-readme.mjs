import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const docsRoot = resolve(scriptDir, "..");
const repoRoot = resolve(docsRoot, "..");
const readmePath = resolve(repoRoot, "readme.txt");
const outputPath = resolve(docsRoot, "src", "pages", "readme.md");
const header = /^[1-6]\.\s+.*$/;

const source = readFileSync(readmePath, "utf8").split("\n");
const out = [
	"---",
	"layout: ../layouts/DocsLayout.astro",
	"title: Expanded Village Growth + Economics Readme",
	'description: "Manual and game settings from the bundled readme.txt"',
	"---",
	"",
];

for (const line of source) {
	const normalized = line.replace(/\r$/, "");
	if (header.test(normalized)) {
		out.push(`## ${normalized}`);
	} else {
		out.push(normalized);
	}
}

writeFileSync(outputPath, `${out.join("\n")}\n`);

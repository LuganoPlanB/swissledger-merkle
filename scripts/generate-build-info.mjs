import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const packageJsonPath = path.join(repoRoot, "package.json");
const outputPath = path.join(repoRoot, "src", "generated", "BuildInfo.sol");

const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf8"));
const version = packageJson.version ?? "0.0.0";

const source = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library BuildInfo {
    string internal constant VERSION = "${version}";
}
`;

mkdirSync(path.dirname(outputPath), { recursive: true });
writeFileSync(outputPath, source);

console.log(JSON.stringify({ outputPath, version }, null, 2));

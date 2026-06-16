import { readFileSync } from "node:fs";

export function getPositionalArgs(argv) {
  return argv.slice(2);
}

export function wantsHelp(argv) {
  return argv.includes("--help") || argv.includes("-h");
}

export function readJsonFile(filePath) {
  return JSON.parse(readFileSync(filePath, "utf8"));
}

export function printJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

export function failUsage(message, usage, exitCode = 2) {
  process.stderr.write(`${message}\n\n${usage}\n`);
  process.exit(exitCode);
}

import test from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import path from "node:path";

const runNode = (scriptPath, arg) =>
  execFileSync("node", [scriptPath, arg], {
    cwd: process.cwd(),
    encoding: "utf8",
  });

test("merkle:root help resolves", () => {
  const output = runNode(path.join("clients", "merkle", "merkle-root.mjs"), "--help");
  const parsed = JSON.parse(output);
  assert.equal(parsed.command, "merkle:root");
  assert.equal(parsed.status, "ready");
});

test("merkle:proof help resolves", () => {
  const output = runNode(path.join("clients", "merkle", "merkle-proof.mjs"), "--help");
  const parsed = JSON.parse(output);
  assert.equal(parsed.command, "merkle:proof");
  assert.equal(parsed.status, "ready");
});

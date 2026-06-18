import test from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import path from "node:path";
import { buildCanonicalVectors } from "./lib/canonical-vectors.mjs";

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

test("public merkle CLI help resolves", () => {
  const output = execFileSync("node", [path.join("clients", "merkle", "merkle-cli.mjs"), "--help"], {
    cwd: process.cwd(),
    encoding: "utf8",
  });

  assert.match(output, /create-merkle-root/);
  assert.match(output, /verify-merkle-proof/);
});

test("public merkle CLI prints a root for default felt252 leaves", () => {
  const values = JSON.stringify(["0x01", "0x02", "0x03"]);
  const output = execFileSync(
    "node",
    [path.join("clients", "merkle", "merkle-cli.mjs"), "root", values],
    {
      cwd: process.cwd(),
      encoding: "utf8",
    },
  );

  assert.match(output.trim(), /^0x[0-9a-f]+$/);
});

test("public merkle CLI round-trips proofs for default felt252 leaves", () => {
  const values = JSON.stringify(["0x01", "0x02", "0x03"]);
  const element = JSON.stringify("0x02");
  const cliPath = path.join("clients", "merkle", "merkle-cli.mjs");

  const root = execFileSync("node", [cliPath, "root", values], {
    cwd: process.cwd(),
    encoding: "utf8",
  }).trim();

  const proof = execFileSync("node", [cliPath, "proofs", root, values, element], {
    cwd: process.cwd(),
    encoding: "utf8",
  }).trim();

  const verified = execFileSync("node", [cliPath, "verify", root, element, proof], {
    cwd: process.cwd(),
    encoding: "utf8",
  }).trim();

  assert.equal(verified, "true");
});

test("public merkle CLI supports explicit tuple leaf encodings", () => {
  const fixture = buildCanonicalVectors().scenarios.find(
    scenario => scenario.name === "two-leaf-u128",
  );

  assert.ok(fixture);

  const cliPath = path.join("clients", "merkle", "merkle-cli.mjs");
  const values = JSON.stringify(fixture.values);
  const element = JSON.stringify(fixture.values[1]);
  const leafEncoding = JSON.stringify(fixture.leafEncoding);

  const root = execFileSync(
    "node",
    [cliPath, "root", values, "--leaf-encoding", leafEncoding],
    {
      cwd: process.cwd(),
      encoding: "utf8",
    },
  ).trim();

  assert.equal(root, fixture.root);

  const proof = execFileSync(
    "node",
    [cliPath, "proofs", root, values, element, "--leaf-encoding", leafEncoding],
    {
      cwd: process.cwd(),
      encoding: "utf8",
    },
  ).trim();

  const verified = execFileSync(
    "node",
    [cliPath, "verify", root, element, proof, "--leaf-encoding", leafEncoding],
    {
      cwd: process.cwd(),
      encoding: "utf8",
    },
  ).trim();

  assert.equal(verified, "true");
});

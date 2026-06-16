import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { buildCanonicalVectors } from "./lib/canonical-vectors.mjs";
import { buildRootResponse } from "./lib/root-command.mjs";

test("merkle root generation matches the canonical four-leaf fixture", () => {
  const fixture = buildCanonicalVectors().scenarios.find(
    scenario => scenario.name === "four-leaf-u128",
  );

  assert.ok(fixture);

  const tempDir = mkdtempSync(path.join(os.tmpdir(), "swissledger-root-"));
  const requestPath = path.join(tempDir, "request.json");
  writeFileSync(
    requestPath,
    `${JSON.stringify(
      {
        leafEncoding: fixture.leafEncoding,
        values: fixture.values,
      },
      null,
      2,
    )}\n`,
  );

  const response = buildRootResponse(
    {
      leafEncoding: fixture.leafEncoding,
      values: fixture.values,
    },
    requestPath,
  );

  assert.equal(response.root, fixture.root);
  assert.equal(response.leafCount, fixture.values.length);

  const dump = JSON.parse(readFileSync(response.treePath, "utf8"));
  assert.deepStrictEqual(dump, fixture.dump);
});

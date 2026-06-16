import test from "node:test";
import assert from "node:assert/strict";
import { buildCanonicalVectors } from "./lib/canonical-vectors.mjs";
import { buildProofResponse } from "./lib/proof-command.mjs";

test("merkle proof generation matches the canonical four-leaf fixture", () => {
  const fixture = buildCanonicalVectors().scenarios.find(
    scenario => scenario.name === "four-leaf-u128",
  );

  assert.ok(fixture);

  const leaf = fixture.leaves[2];
  const response = buildProofResponse(
    {
      leafIndex: leaf.index,
    },
    fixture.dump,
  );

  assert.equal(response.root, fixture.root);
  assert.deepStrictEqual(response.value, leaf.value);
  assert.equal(response.leafHash, leaf.leafHash);
  assert.deepStrictEqual(response.proof, leaf.proof);
});

test("merkle proof generation can resolve by exact value", () => {
  const fixture = buildCanonicalVectors().scenarios.find(
    scenario => scenario.name === "two-leaf-u128",
  );

  assert.ok(fixture);

  const leaf = fixture.leaves[1];
  const response = buildProofResponse(
    {
      value: leaf.value,
    },
    fixture.dump,
  );

  assert.deepStrictEqual(response.value, leaf.value);
  assert.equal(response.leafHash, leaf.leafHash);
  assert.deepStrictEqual(response.proof, leaf.proof);
});

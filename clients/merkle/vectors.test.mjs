import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { StandardMerkleTree } from "@ericnordelo/strk-merkle-tree";
import {
  buildCanonicalVectors,
  canonicalVectorsPath,
} from "./lib/canonical-vectors.mjs";

test("generated vectors match the checked-in fixture", () => {
  const expected = JSON.parse(readFileSync(canonicalVectorsPath, "utf8"));
  const actual = buildCanonicalVectors();
  assert.deepStrictEqual(actual, expected);
});

test("all canonical proofs verify with StandardMerkleTree", () => {
  const vectors = buildCanonicalVectors();

  for (const scenario of vectors.scenarios) {
    const tree = StandardMerkleTree.load(scenario.dump);

    for (const leaf of scenario.leaves) {
      assert.equal(tree.leafHash(leaf.value), leaf.leafHash);
      assert.equal(tree.verify(leaf.index, leaf.proof), true);
      assert.equal(
        StandardMerkleTree.verify(scenario.root, scenario.leafEncoding, leaf.value, leaf.proof),
        true,
      );
    }
  }
});

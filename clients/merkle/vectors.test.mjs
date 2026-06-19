import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { StandardMerkleTree } from "./lib/strk-merkle-tree.mjs";
import {
  buildCanonicalVectors,
  canonicalVectorsPath,
} from "./lib/canonical-vectors.mjs";

function verifyMultiProofOrFalse(root, leafEncoding, multiproof) {
  try {
    return StandardMerkleTree.verifyMultiProof(root, leafEncoding, multiproof);
  } catch {
    return false;
  }
}

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

test("all canonical multiproofs verify with StandardMerkleTree", () => {
  const vectors = buildCanonicalVectors();

  for (const scenario of vectors.scenarios) {
    const tree = StandardMerkleTree.load(scenario.dump);

    for (const multiproof of scenario.multiproofs) {
      assert.deepStrictEqual(
        multiproof.values,
        multiproof.leafIndices.map(index => scenario.values[index]),
      );
      assert.deepStrictEqual(
        multiproof.leafHashes,
        multiproof.leafIndices.map(index => tree.leafHash(scenario.values[index])),
      );
      assert.equal(
        tree.verifyMultiProof({
          leaves: multiproof.values,
          proof: multiproof.proof,
          proofFlags: multiproof.proofFlags,
        }),
        true,
      );
      assert.equal(
        StandardMerkleTree.verifyMultiProof(scenario.root, scenario.leafEncoding, {
          leaves: multiproof.values,
          proof: multiproof.proof,
          proofFlags: multiproof.proofFlags,
        }),
        true,
      );

      if (multiproof.proofFlags.length > 0) {
        assert.equal(
          verifyMultiProofOrFalse(scenario.root, scenario.leafEncoding, {
            leaves: multiproof.values,
            proof: multiproof.proof,
            proofFlags: multiproof.proofFlags.map((value, index) => (index === 0 ? !value : value)),
          }),
          false,
        );
      }
    }
  }
});

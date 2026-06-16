import { StandardMerkleTree } from "@ericnordelo/strk-merkle-tree";

export function buildProofResponse(request, dump) {
  const tree = StandardMerkleTree.load(dump);
  const hasLeafIndex = typeof request.leafIndex === "number";
  const hasValue = Object.hasOwn(request, "value");

  if (!hasLeafIndex && !hasValue) {
    throw new Error("Proof request requires leafIndex or value.");
  }

  const lookup = hasLeafIndex ? request.leafIndex : request.value;
  const value = hasLeafIndex ? tree.at(request.leafIndex) : request.value;

  if (typeof value === "undefined") {
    throw new Error("Requested leaf index is out of bounds.");
  }

  const proof = tree.getProof(lookup);

  return {
    root: tree.root,
    leafEncoding: dump.leafEncoding,
    value,
    leafHash: tree.leafHash(value),
    proof,
  };
}

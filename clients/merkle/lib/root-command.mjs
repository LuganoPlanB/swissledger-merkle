import { writeFileSync } from "node:fs";
import path from "node:path";
import { StandardMerkleTree } from "@ericnordelo/strk-merkle-tree";

export function buildRootResponse(request, requestPath) {
  const tree = StandardMerkleTree.of(request.values, request.leafEncoding);
  const defaultTreePath = requestPath.replace(/\.json$/i, ".tree.json");
  const treePath = path.resolve(request.treePath ?? defaultTreePath);

  writeFileSync(treePath, `${JSON.stringify(tree.dump(), null, 2)}\n`);

  return {
    root: tree.root,
    leafEncoding: request.leafEncoding,
    leafCount: request.values.length,
    treePath,
  };
}

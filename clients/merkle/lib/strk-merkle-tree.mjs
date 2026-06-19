import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const vendorModule = require("../../../vendor/strk-merkle-tree/dist/index.js");

/**
 * Re-export the vendored upstream implementation through one local entrypoint.
 */
export const { SimpleMerkleTree, StandardMerkleTree } = vendorModule;

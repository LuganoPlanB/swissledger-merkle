import { mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { StandardMerkleTree } from "@ericnordelo/strk-merkle-tree";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../../..");

export const canonicalVectorsPath = path.join(
  repoRoot,
  "fixtures",
  "merkle",
  "standard-vectors.json",
);
export const generatedParityTestPath = path.join(
  repoRoot,
  "test",
  "generated",
  "GeneratedMerkleParity.t.sol",
);

const BAD_FELT = "0x01";

const canonicalScenarios = [
  {
    name: "one-leaf-u128",
    leafEncoding: ["ContractAddress", "u128"],
    values: [["0x1111111111111111111111111111111111111111", "5000000000000000000"]],
  },
  {
    name: "two-leaf-u128",
    leafEncoding: ["ContractAddress", "u128"],
    values: [
      ["0x1111111111111111111111111111111111111111", "5000000000000000000"],
      ["0x2222222222222222222222222222222222222222", "2500000000000000000"],
    ],
  },
  {
    name: "four-leaf-u128",
    leafEncoding: ["ContractAddress", "u128"],
    values: [
      ["0x1111111111111111111111111111111111111111", "10"],
      ["0x2222222222222222222222222222222222222222", "20"],
      ["0x3333333333333333333333333333333333333333", "30"],
      ["0x4444444444444444444444444444444444444444", "40"],
    ],
    multiproofs: [
      { name: "adjacent-middle", inputIndices: [1, 2] },
      { name: "non-adjacent-edges", inputIndices: [0, 3] },
      { name: "empty-selection", inputIndices: [] },
    ],
  },
  {
    name: "odd-count-u256-bool",
    leafEncoding: ["ContractAddress", "u256", "bool"],
    values: [
      [
        "0x1111111111111111111111111111111111111111",
        "340282366920938463463374607431768211455",
        true,
      ],
      [
        "0x2222222222222222222222222222222222222222",
        "680564733841876926926749214863536422912",
        false,
      ],
      [
        "0x3333333333333333333333333333333333333333",
        "999999999999999999999999999999999999",
        true,
      ],
    ],
    multiproofs: [{ name: "outer-pair", inputIndices: [0, 2] }],
  },
  {
    name: "duplicate-values",
    leafEncoding: ["ContractAddress", "u128"],
    values: [
      ["0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "7"],
      ["0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "7"],
      ["0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "9"],
    ],
    notes: [
      "Duplicate values are allowed and create duplicate leaf hashes.",
      "Membership is about inclusion in the tree, not identifying a unique occurrence.",
    ],
  },
];

function nextHex(hexValue) {
  return `0x${(BigInt(hexValue) + 1n).toString(16)}`;
}

function sortFeltPair(a, b) {
  return BigInt(a) <= BigInt(b) ? [a, b] : [b, a];
}

function buildInvalidProofs(proof) {
  if (proof.length === 0) {
    return {
      appendedBadFelt: [BAD_FELT],
    };
  }

  const mutatedFirst = proof.slice();
  mutatedFirst[0] = proof[0] === BAD_FELT ? "0x02" : BAD_FELT;

  return {
    mutatedFirst,
    truncated: proof.slice(0, -1),
    appendedBadFelt: [...proof, BAD_FELT],
  };
}

function buildMultiproofs(tree, definition) {
  return (definition.multiproofs ?? []).map(({ name, inputIndices }) => {
    const multiproof = tree.getMultiProof(inputIndices);
    const leafIndices = inputIndices
      .slice()
      .sort((left, right) => tree.values[right].treeIndex - tree.values[left].treeIndex);

    return {
      name,
      inputIndices,
      leafIndices,
      values: multiproof.leaves,
      leafHashes: leafIndices.map(index => tree.leafHash(definition.values[index])),
      proof: multiproof.proof,
      proofFlags: multiproof.proofFlags,
      wrongRoot: nextHex(tree.root),
    };
  });
}

function buildScenarioVector(definition) {
  const tree = StandardMerkleTree.of(definition.values, definition.leafEncoding);
  const dump = tree.dump();
  const nodePairs = [];

  for (let index = 0; 2 * index + 2 < dump.tree.length; index += 1) {
    const [left, right] = sortFeltPair(dump.tree[2 * index + 1], dump.tree[2 * index + 2]);
    nodePairs.push({
      left,
      right,
      hash: dump.tree[index],
    });
  }

  const leaves = definition.values.map((value, index) => {
    const proof = tree.getProof(index);
    return {
      index,
      value,
      leafHash: tree.leafHash(value),
      proof,
      invalidProofs: buildInvalidProofs(proof),
      wrongLeafHash: nextHex(tree.leafHash(value)),
      wrongRoot: nextHex(tree.root),
    };
  });
  const multiproofs = buildMultiproofs(tree, definition);

  return {
    name: definition.name,
    leafEncoding: definition.leafEncoding,
    values: definition.values,
    root: tree.root,
    tree: dump.tree,
    dump,
    nodePairs,
    leaves,
    multiproofs,
    ...(definition.notes ? { notes: definition.notes } : {}),
  };
}

export function buildCanonicalVectors() {
  return {
    format: "strk-merkle-tree-standard-v1",
    sourcePackage: "@ericnordelo/strk-merkle-tree",
    sourceVersion: "1.0.1",
    scenarios: canonicalScenarios.map(buildScenarioVector),
  };
}

export function writeCanonicalVectors(outputPath = canonicalVectorsPath) {
  const vectors = buildCanonicalVectors();
  mkdirSync(path.dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${JSON.stringify(vectors, null, 2)}\n`);
  writeGeneratedParityTest(vectors);
  return { outputPath, vectors };
}

function toSolidityUint(hexValue) {
  return `uint256(${hexValue})`;
}

function toSolidityUintArray(values) {
  if (values.length === 0) {
    return [
      "        uint256[] memory proof = new uint256[](0);",
    ];
  }

  return [
    `        uint256[] memory proof = new uint256[](${values.length});`,
    ...values.map((value, index) => `        proof[${index}] = ${toSolidityUint(value)};`),
  ];
}

function toSolidityNamedUintArray(name, values) {
  if (values.length === 0) {
    return [`        uint256[] memory ${name} = new uint256[](0);`];
  }

  return [
    `        uint256[] memory ${name} = new uint256[](${values.length});`,
    ...values.map((value, index) => `        ${name}[${index}] = ${toSolidityUint(value)};`),
  ];
}

function toSolidityNamedBoolArray(name, values) {
  if (values.length === 0) {
    return [`        bool[] memory ${name} = new bool[](0);`];
  }

  return [
    `        bool[] memory ${name} = new bool[](${values.length});`,
    ...values.map((value, index) => `        ${name}[${index}] = ${value ? "true" : "false"};`),
  ];
}

function solidityTestName(input) {
  return input.replace(/[^a-zA-Z0-9]+/g, "_");
}

function buildGeneratedParityTest(vectors) {
  const lines = [
    "// SPDX-License-Identifier: MIT",
    "pragma solidity ^0.8.30;",
    "",
    'import {StrkMerkleProof} from "../../src/StrkMerkleProof.sol";',
    "",
    "contract GeneratedMerkleParityTest {",
  ];

  for (const scenario of vectors.scenarios) {
    for (const leaf of scenario.leaves) {
      lines.push(
        `    function test_${solidityTestName(scenario.name)}_leaf_${leaf.index}() external pure {`,
        `        uint256 root = ${toSolidityUint(scenario.root)};`,
        `        uint256 leafHash = ${toSolidityUint(leaf.leafHash)};`,
        ...toSolidityUintArray(leaf.proof),
        '        require(StrkMerkleProof.verify(root, leafHash, proof), "generated proof failed");',
        "    }",
        "",
      );
    }

    for (const multiproof of scenario.multiproofs) {
      lines.push(
        `    function test_${solidityTestName(scenario.name)}_${solidityTestName(multiproof.name)}_multiproof() external pure {`,
        `        uint256 root = ${toSolidityUint(scenario.root)};`,
        `        uint256 wrongRoot = ${toSolidityUint(multiproof.wrongRoot)};`,
        ...toSolidityNamedUintArray("leaves", multiproof.leafHashes),
        ...toSolidityUintArray(multiproof.proof),
        ...toSolidityNamedBoolArray("proofFlags", multiproof.proofFlags),
        '        require(StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "generated multiproof failed");',
        '        require(!StrkMerkleProof.verifyMultiProof(wrongRoot, leaves, proof, proofFlags), "wrong multiproof root accepted");',
        "    }",
        "",
      );

      if (multiproof.leafHashes.length > 0) {
        const mutatedLeaves = multiproof.leafHashes.slice();
        mutatedLeaves[0] = nextHex(mutatedLeaves[0]);

        lines.push(
          `    function test_${solidityTestName(scenario.name)}_${solidityTestName(multiproof.name)}_rejects_mutated_leaves() external pure {`,
          `        uint256 root = ${toSolidityUint(scenario.root)};`,
          ...toSolidityNamedUintArray("leaves", mutatedLeaves),
          ...toSolidityUintArray(multiproof.proof),
          ...toSolidityNamedBoolArray("proofFlags", multiproof.proofFlags),
          '        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof leaves accepted");',
          "    }",
          "",
        );
      }

      if (multiproof.proofFlags.length > 0) {
        lines.push(
          `    function test_${solidityTestName(scenario.name)}_${solidityTestName(multiproof.name)}_rejects_mutated_flags() external pure {`,
          `        uint256 root = ${toSolidityUint(scenario.root)};`,
          ...toSolidityNamedUintArray("leaves", multiproof.leafHashes),
          ...toSolidityUintArray(multiproof.proof),
          ...toSolidityNamedBoolArray(
            "proofFlags",
            multiproof.proofFlags.map((value, index) => (index === 0 ? !value : value)),
          ),
          '        require(!StrkMerkleProof.verifyMultiProof(root, leaves, proof, proofFlags), "mutated multiproof flags accepted");',
          "    }",
          "",
        );
      }
    }
  }

  lines.push("}");
  return `${lines.join("\n")}\n`;
}

function writeGeneratedParityTest(vectors) {
  mkdirSync(path.dirname(generatedParityTestPath), { recursive: true });
  writeFileSync(generatedParityTestPath, buildGeneratedParityTest(vectors));
}

import { existsSync, readFileSync } from "node:fs";
import { StandardMerkleTree } from "@ericnordelo/strk-merkle-tree";

const DEFAULT_LEAF_ENCODING = ["felt252"];

const usage = `Usage:
  npm run merkle -- --help
  npm run merkle -- root <values-json-or-path> [--leaf-encoding <json-array>]
  npm run merkle -- proofs <root> <values-json-or-path> <element-json-or-path> [--leaf-encoding <json-array>]
  npm run merkle -- verify <root> <element-json-or-path> <proof-json-or-path> [--leaf-encoding <json-array>]

Shortcuts:
  npm run create-merkle-root -- <values-json-or-path> [--leaf-encoding <json-array>]
  npm run create-merkle-proofs -- <root> <values-json-or-path> <element-json-or-path> [--leaf-encoding <json-array>]
  npm run verify-merkle-proof -- <root> <element-json-or-path> <proof-json-or-path> [--leaf-encoding <json-array>]

Examples:
  npm run create-merkle-root -- '["0x01","0x02","0x03"]'
  npm run create-merkle-proofs -- 0x1234 '["0x01","0x02","0x03"]' '"0x02"'
  npm run verify-merkle-proof -- 0x1234 '"0x02"' '["0xabcd","0xef01"]'
  npm run merkle -- root values.json --leaf-encoding '["ContractAddress","u128"]'

Notes:
  - Default leaf encoding is ["felt252"].
  - For single-field leaves, values can be scalar arrays like ["0x01","0x02"].
  - For multi-field leaves, values must be arrays of tuples matching --leaf-encoding.
`;

/**
 * Print help text or a command result.
 */
function writeStdout(value) {
  process.stdout.write(`${value}\n`);
}

/**
 * Exit with a message that the caller can show directly in the shell.
 */
function fail(message, exitCode = 2) {
  process.stderr.write(`${message}\n\n${usage}`);
  process.exit(exitCode);
}

/**
 * Parse a JSON string and point errors at the user-provided argument.
 */
function parseJson(text, label) {
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(`${label} must be valid JSON: ${error.message}`);
  }
}

/**
 * Accept inline JSON for ergonomics and `.json` files for repeatable workflows.
 */
function readJsonArg(argument, label) {
  if (existsSync(argument)) {
    return parseJson(readFileSync(argument, "utf8"), `${label} file`);
  }

  return parseJson(argument, label);
}

/**
 * Convert a simple scalar array into the row shape required by StandardMerkleTree.
 */
function normalizeValues(values, leafEncoding) {
  if (!Array.isArray(values)) {
    throw new Error("Values input must be a JSON array.");
  }

  const arity = leafEncoding.length;
  if (arity === 1) {
    return values.map(value => {
      if (Array.isArray(value)) {
        if (value.length !== 1) {
          throw new Error("Single-field values must contain exactly one item.");
        }

        return value;
      }

      return [value];
    });
  }

  return values.map((value, index) => {
    if (!Array.isArray(value) || value.length !== arity) {
      throw new Error(`Value at index ${index} must be an array with ${arity} items.`);
    }

    return value;
  });
}

/**
 * Normalize a single element to the same row shape used during tree construction.
 */
function normalizeElement(element, leafEncoding) {
  const arity = leafEncoding.length;
  if (arity === 1) {
    if (Array.isArray(element)) {
      if (element.length !== 1) {
        throw new Error("Single-field elements must contain exactly one item.");
      }

      return element;
    }

    return [element];
  }

  if (!Array.isArray(element) || element.length !== arity) {
    throw new Error(`Element input must be an array with ${arity} items.`);
  }

  return element;
}

/**
 * Allow `verify` to accept either the raw proof array or an object that contains it.
 */
function normalizeProof(input) {
  if (Array.isArray(input)) {
    return input;
  }

  if (input && typeof input === "object" && Array.isArray(input.proof)) {
    return input.proof;
  }

  throw new Error("Proof input must be a JSON array or an object with a proof array.");
}

/**
 * Parse `--leaf-encoding` without pulling in an argument parser dependency.
 */
function parseArgs(argv) {
  const args = argv.slice(2);
  const positionals = [];
  let leafEncoding = DEFAULT_LEAF_ENCODING;
  let wantsHelp = false;

  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];

    if (argument === "--help" || argument === "-h") {
      wantsHelp = true;
      continue;
    }

    if (argument === "--leaf-encoding") {
      const nextArgument = args[index + 1];
      if (!nextArgument) {
        throw new Error("--leaf-encoding requires a JSON array.");
      }

      const parsed = readJsonArg(nextArgument, "--leaf-encoding");
      if (!Array.isArray(parsed) || parsed.length === 0) {
        throw new Error("--leaf-encoding must be a non-empty JSON array.");
      }

      leafEncoding = parsed;
      index += 1;
      continue;
    }

    positionals.push(argument);
  }

  return { positionals, leafEncoding, wantsHelp };
}

/**
 * Build a tree from user input using the requested leaf encoding.
 */
function createTree(valuesArgument, leafEncoding) {
  const values = normalizeValues(readJsonArg(valuesArgument, "values"), leafEncoding);
  return StandardMerkleTree.of(values, leafEncoding);
}

/**
 * Keep each command small and make the stdout contract explicit.
 */
function run() {
  const { positionals, leafEncoding, wantsHelp } = parseArgs(process.argv);
  const [command, ...commandArgs] = positionals;

  if (wantsHelp || !command) {
    writeStdout(usage.trimEnd());
    return;
  }

  if (command === "root") {
    const [valuesArgument] = commandArgs;
    if (!valuesArgument) {
      fail("Missing values input for root.");
    }

    writeStdout(createTree(valuesArgument, leafEncoding).root);
    return;
  }

  if (command === "proofs") {
    const [expectedRoot, valuesArgument, elementArgument] = commandArgs;
    if (!expectedRoot || !valuesArgument || !elementArgument) {
      fail("Proofs requires root, values input, and element input.");
    }

    const tree = createTree(valuesArgument, leafEncoding);
    if (tree.root !== expectedRoot) {
      throw new Error(`Provided root does not match computed root: ${tree.root}`);
    }

    const element = normalizeElement(readJsonArg(elementArgument, "element"), leafEncoding);
    writeStdout(JSON.stringify(tree.getProof(element), null, 2));
    return;
  }

  if (command === "verify") {
    const [root, elementArgument, proofArgument] = commandArgs;
    if (!root || !elementArgument || !proofArgument) {
      fail("Verify requires root, element input, and proof input.");
    }

    const element = normalizeElement(readJsonArg(elementArgument, "element"), leafEncoding);
    const proof = normalizeProof(readJsonArg(proofArgument, "proof"));
    writeStdout(String(StandardMerkleTree.verify(root, leafEncoding, element, proof)));
    return;
  }

  fail(`Unknown command: ${command}`);
}

try {
  run();
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

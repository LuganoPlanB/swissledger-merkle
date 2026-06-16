import {
  getPositionalArgs,
  printJson,
  readJsonFile,
  wantsHelp,
  failUsage,
} from "./lib/cli.mjs";
import { buildProofResponse } from "./lib/proof-command.mjs";

const usage = `Usage: npm run merkle:proof -- <request.json>

Request JSON shape:
{
  "treePath": "fixtures/merkle/tree.json",
  "leafIndex": 0
}`;

if (wantsHelp(process.argv)) {
  printJson({
    command: "merkle:proof",
    status: "ready",
    usage,
  });
  process.exit(0);
}

const [requestPath] = getPositionalArgs(process.argv);

if (!requestPath) {
  failUsage("Missing request path.", usage);
}

const request = readJsonFile(requestPath);

if (!request.treePath) {
  failUsage("Proof request requires treePath.", usage);
}

const dump = readJsonFile(request.treePath);
printJson(buildProofResponse(request, dump));

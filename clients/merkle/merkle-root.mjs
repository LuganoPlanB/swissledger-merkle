import {
  getPositionalArgs,
  printJson,
  readJsonFile,
  wantsHelp,
  failUsage,
} from "./lib/cli.mjs";
import { buildRootResponse } from "./lib/root-command.mjs";

const usage = `Usage: npm run merkle:root -- <request.json>

Request JSON shape:
{
  "leafEncoding": ["ContractAddress", "u128"],
  "values": [["0x1111111111111111111111111111111111111111", "5"]]
}`;

if (wantsHelp(process.argv)) {
  printJson({
    command: "merkle:root",
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
printJson(buildRootResponse(request, requestPath));

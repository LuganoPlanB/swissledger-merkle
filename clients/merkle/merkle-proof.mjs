import { getPositionalArgs, printJson, wantsHelp, failUsage } from "./lib/cli.mjs";

const usage = `Usage: npm run merkle:proof -- <request.json>

Request JSON shape:
{
  "dumpPath": "fixtures/merkle/tree.json",
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

failUsage(
  `Proof generation is not implemented yet. Received request path: ${requestPath}`,
  usage,
);

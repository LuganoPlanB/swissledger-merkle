import { writeCanonicalVectors } from "./lib/canonical-vectors.mjs";

const { outputPath, vectors } = writeCanonicalVectors();

console.log(
  JSON.stringify(
    {
      outputPath,
      scenarioCount: vectors.scenarios.length,
    },
    null,
    2,
  ),
);

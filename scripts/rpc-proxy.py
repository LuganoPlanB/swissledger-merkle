#!/usr/bin/env python3
"""
JSON-RPC proxy for ledger.swiss Blockscout API.

The Blockscout /api/eth-rpc endpoint has two quirks that break standard
Ethereum tooling (forge, cast, web3.py, etc.):

1. Every request MUST include "params", even when empty.
   Standard JSON-RPC 2.0 allows omitting it.

2. Error responses use a plain string "error" instead of the standard
   JSON-RPC 2.0 error object {"code": …, "message": …}.

This proxy sits between your tools and the real endpoint, fixing both issues.

Usage:
  python3 scripts/rpc-proxy.py [--port PORT] [--target URL]

  Defaults: port 8545, target https://explorer.ledger.swiss/api/eth-rpc

Then point forge/cast at http://127.0.0.1:8545 (no /api/eth-rpc path).
"""

import http.server
import json
import sys

import requests

TARGET = "https://explorer.ledger.swiss/api/eth-rpc"
PORT = 8545

_SESSION = requests.Session()
_SESSION.headers.update({
    "Content-Type": "application/json",
    "Accept": "application/json",
    "User-Agent": "Mozilla/5.0 (compatible; foundry-rpc-proxy/1.0)",
})


class FixProxy(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body_len = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(body_len)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self._respond(400, _rpc_err(-32700, "Parse error"))
            return

        is_batch = isinstance(data, list)
        entries = data if is_batch else [data]

        fixed_entries = []
        for entry in entries:
            if isinstance(entry, dict):
                if "params" not in entry:
                    entry["params"] = []
            fixed_entries.append(entry)

        fixed_body = json.dumps(fixed_entries if is_batch else fixed_entries[0])

        try:
            resp = _SESSION.post(TARGET, data=fixed_body, timeout=30)
            result_data = _normalize_response(resp.json())
            self.send_response(resp.status_code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result_data).encode())
        except requests.RequestException as e:
            self._respond(502, _rpc_err(-32603, str(e)))

    def _respond(self, status, data):
        body = json.dumps(data).encode() if isinstance(data, dict) else json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        sys.stderr.write("[rpc-proxy] %s\n" % (format % args))


def _rpc_err(code, message):
    return {"jsonrpc": "2.0", "error": {"code": code, "message": message}, "id": 0}


def _normalize_response(data):
    """Fix non-standard error formats in the response."""
    if isinstance(data, dict):
        err = data.get("error")
        if isinstance(err, str):
            data["error"] = {"code": -32000, "message": err}
        return data
    if isinstance(data, list):
        return [_normalize_response(item) for item in data]
    return data


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else PORT

    target = TARGET
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == "--target" and i < len(sys.argv) - 1:
            target = sys.argv[i + 1]
        elif arg == "--port" and i < len(sys.argv) - 1:
            port = int(sys.argv[i + 1])

    server = http.server.HTTPServer(("127.0.0.1", port), FixProxy)
    print(f"RPC proxy listening on http://127.0.0.1:{port}", file=sys.stderr)
    print(f"Forwarding to {target}", file=sys.stderr)
    server.serve_forever()

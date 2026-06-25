#!/usr/bin/env python3
"""JSON-RPC proxy for ledger.swiss Blockscout API.

Fixes two quirks that break standard Ethereum tooling:
1. Injects "params" when missing (chain requires it).
2. Normalises plain-string error responses to JSON-RPC 2.0 format.

Usage:
  python3 scripts/rpc-proxy.py [PORT] [TARGET_URL]
  Defaults: port 8545, target https://explorer.ledger.swiss/api/eth-rpc
"""

import http.server
import json
import sys
import urllib.request


TARGET = "https://explorer.ledger.swiss/api/eth-rpc"
PORT = 8545


def rpc_err(code, message):
    return {"jsonrpc": "2.0", "error": {"code": code, "message": message}, "id": 0}


def normalize_response(data):
    if isinstance(data, dict):
        err = data.get("error")
        if isinstance(err, str):
            data["error"] = {"code": -32000, "message": err}
        return data
    if isinstance(data, list):
        return [normalize_response(item) for item in data]
    return data


class FixProxy(http.server.BaseHTTPRequestHandler):

    def do_POST(self):
        body_len = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(body_len)

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self._respond(400, rpc_err(-32700, "Parse error"))
            return

        is_batch = isinstance(data, list)
        entries = data if is_batch else [data]

        for entry in entries:
            if isinstance(entry, dict) and "params" not in entry:
                entry["params"] = []

        fixed_body = json.dumps(entries if is_batch else entries[0])

        try:
            req = urllib.request.Request(
                self.server.target_url,
                data=fixed_body.encode(),
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                result_data = normalize_response(json.loads(resp.read()))
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(result_data).encode())
        except Exception as e:
            self._respond(502, rpc_err(-32603, str(e)))

    def _respond(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        sys.stderr.write("[rpc-proxy] %s\n" % (fmt % args))


def main():
    args = sys.argv[1:]
    port = int(args[0]) if args else PORT
    target = args[1] if len(args) > 1 else TARGET

    server = http.server.HTTPServer(("127.0.0.1", port), FixProxy)
    server.target_url = target
    print(f"RPC proxy listening on http://127.0.0.1:{port}", file=sys.stderr)
    print(f"Forwarding to {target}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()

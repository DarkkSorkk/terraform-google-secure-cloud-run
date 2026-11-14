"""Example API for Cloud Run. Standard library only: nothing to install and nothing extra to patch."""

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def response_for(path: str, environ: dict) -> tuple[int, dict]:
    """Status and JSON body for a path. Kept apart from the server so it can be tested without a socket."""
    if path == "/health":
        return 200, {"status": "ok"}
    if path == "/":
        return 200, {
            "message": f"{environ.get('GREETING', 'Hello')} from Cloud Run",
            "revision": environ.get("K_REVISION", "local"),
            # Shows that a secret reached the service without ever printing it.
            "secret_loaded": bool(environ.get("API_TOKEN")),
        }
    return 404, {"error": "not found"}


class Handler(BaseHTTPRequestHandler):
    server_version = "hello"
    sys_version = ""

    def do_GET(self) -> None:  # noqa: N802 (name required by BaseHTTPRequestHandler)
        status, body = response_for(self.path.split("?", 1)[0], os.environ)
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        # One JSON line per request: Cloud Logging reads it as structured data. No headers, no query string.
        line = {"severity": "INFO", "path": self.path.split("?", 1)[0], "message": format % args}
        print(json.dumps(line), file=sys.stdout, flush=True)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()

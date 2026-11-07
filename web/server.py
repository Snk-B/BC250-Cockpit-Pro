import http.server
import socketserver
import json
import os
import sys

import topology
import overclock
import telemetry

PORT = int(os.environ.get("BC250_WEB_PORT", 8090))
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class BC250Server(http.server.ThreadingHTTPServer):
    def handle_error(self, request, client_address):
        err = sys.exc_info()[1]
        if isinstance(err, (ConnectionResetError, BrokenPipeError, ConnectionAbortedError)):
            return
        super().handle_error(request, client_address)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_request(self, code='-', size='-'):
        # Only failed requests are logged: an open dashboard polls
        # /api/telemetry every ~700 ms.
        if isinstance(code, int) and code < 400:
            return
        super().log_request(code, size)

    def _send_json(self, payload, status=200, *, allow_nan=True):
        # Serialize BEFORE sending headers: if json.dumps raises (e.g. a
        # non-finite value under allow_nan=False), we must not have already
        # committed a 200 with no body. Sending Content-Length also lets
        # clients detect a truncated response.
        try:
            body = json.dumps(payload, allow_nan=allow_nan).encode()
        except ValueError:
            status = 503
            body = json.dumps({'error': 'telemetry contained non-finite values'}).encode()
        try:
            self.send_response(status)
            self.send_header('Content-type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(body)
        except (ConnectionResetError, BrokenPipeError):
            pass

    def do_GET(self):
        # The daemon owns the complete snapshot, including memory telemetry.
        if self.path == '/api/telemetry':
            snapshot = telemetry.read_telemetry()
            self._send_json(snapshot, 503 if 'error' in snapshot else 200, allow_nan=False)
        elif self.path == '/api/topology':
            self._send_json(topology.read_topology())
        elif self.path == '/api/overclock':
            self._send_json(overclock.read_overclock())
        else:
            # Serve Cockpit Pro static files (index.html, style.css, app.js, etc.)
            super().do_GET()

def main():
    print("=========================================")
    print(f" BC-250 Cockpit Pro Web Server running on port {PORT}")
    print(f" Dashboard URL: http://localhost:{PORT}/")
    print("=========================================")

    # Allow instant server restarts instead of waiting for the kernel to release the port
    socketserver.TCPServer.allow_reuse_address = True
    # Threaded so a slow endpoint (topology/overclock shell out to systemctl)
    # cannot stall the fast /api/telemetry poll for every other client.
    with BC250Server(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")

if __name__ == '__main__':
    main()

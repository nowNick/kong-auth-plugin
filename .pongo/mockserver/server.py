from http.server import BaseHTTPRequestHandler, HTTPServer
import json

hostName = "0.0.0.0"
serverPort = 80

class Handler(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_HEAD(self):
        self.send_response(200)
        self._set_headers()

    def do_POST(self):
        auth_header = self.headers.get("Authorization")
        self.log_message(f'All headers: {self.headers}')
        self.log_message(f'Got Auth header: {auth_header}')
        if auth_header is None or auth_header != 'Bearer secret-header':
            self.send_response(401)
            self._set_headers()
            self.wfile.write(json.dumps({'error': 'unauthorized'}).encode("utf-8"))
        elif auth_header == 'Bearer crash':
            self.send_response(500)
            self._set_headers()
            self.wfile.write(json.dumps({'error': 'internal exception'}).encode("utf-8"))
        elif auth_header == 'Bearer created':
            self.send_response(201)
            self._set_headers()
            self.wfile.write(json.dumps({'result': 'ok'}).encode("utf-8"))
        else:
            self.send_response(200)
            self._set_headers()
            self.wfile.write(json.dumps({'result': 'ok'}).encode("utf-8"))


server = HTTPServer((hostName, serverPort), Handler)

print("Staring http mock server...")
server.serve_forever()

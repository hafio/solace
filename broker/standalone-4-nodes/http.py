from http.server import BaseHTTPRequestHandler, HTTPServer

# Configuration
PORT = 6666  # Change this to any port you want
WELCOME_TEXT = "Hello, welcome to my server!"  # Change this text

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(WELCOME_TEXT.encode())

def run(server_class=HTTPServer, handler_class=SimpleHandler):
    server_address = ('', PORT)
    httpd = server_class(server_address, handler_class)
    print(f"Server running on port {PORT}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run()


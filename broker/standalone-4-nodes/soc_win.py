import socket
import threading
import sys

HOST = '0.0.0.0'
PORT = 61666

def handle_client(conn, addr):
    try:
        request = conn.recv(1024).decode('utf-8', errors='replace')
        if not request:
            return
        request_lines = request.splitlines()
        print(f"[ACCESS] {addr[0]} {request_lines[0]}")
        
        # Default file
        if path == '/':
            path = '/index.html'

        file_path = os.path.join(DOC_ROOT, path.lstrip('/'))
        if os.path.exists(file_path) and os.path.isfile(file_path):
            with open(file_path, 'rb') as f:
                body = f.read()
            header = (
                "HTTP/1.1 200 OK\r\n"
                f"Content-Length: {len(body)}\r\n"
                "Content-Type: text/html\r\n"
                "Connection: close\r\n"
                "\r\n"
            ).encode('utf-8')
            conn.sendall(header + body)
        else:
            body = ("\nBODY:\n" + "\n".join(request_lines)).encode('utf-8')
            header = (
                "HTTP/1.1 200 OK\r\n"
                f"Content-Length: {len(body)}\r\n"
                "Content-Type: text/plain\r\n"
                "Connection: close\r\n"
                "\r\n"
            ).encode('utf-8')
            conn.sendall(header + body)
    except Exception as e:
        print(f"[ERROR] {e}")
    finally:
        conn.close()

def keyboard_listener(stop_event):
    print("Press 'x' then Enter to stop the server.")
    while not stop_event.is_set():
        key = input().strip()
        if key.lower() == 'x':
            stop_event.set()

def run_server():
    stop_event = threading.Event()
    threading.Thread(target=keyboard_listener, args=(stop_event,), daemon=True).start()

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.bind((HOST, PORT))
        server_socket.listen(5)
        server_socket.settimeout(1.0)
        print(f"Echo HTTP Server running on {HOST}:{PORT}...")

        while not stop_event.is_set():
            try:
                conn, addr = server_socket.accept()
                threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
            except socket.timeout:
                continue
            except KeyboardInterrupt:
                stop_event.set()

        print("Shutting down server...")

if __name__ == "__main__":
    run_server()

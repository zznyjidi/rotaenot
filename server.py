#!/usr/bin/env python3
"""
Simple HTTP server for serving Godot HTML5 exports with proper CORS headers
"""

import http.server
import socketserver
import os
import sys
from urllib.parse import urlparse

PORT = 8000

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS headers."""

    def end_headers(self):
        # Add CORS headers
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')

        # Call parent end_headers
        super().end_headers()

    def do_OPTIONS(self):
        """Handle OPTIONS request for CORS preflight."""
        self.send_response(200)
        self.end_headers()

    def guess_type(self, path):
        """Add proper MIME types for Godot files."""
        mimetype = super().guess_type(path)

        # Add Godot-specific MIME types
        if path.endswith('.wasm'):
            return 'application/wasm'
        elif path.endswith('.pck'):
            return 'application/octet-stream'
        elif path.endswith('.side.wasm'):
            return 'application/wasm'

        return mimetype

def run_server():
    """Start the HTTP server."""
    # Change to the export directory if it exists
    export_dir = 'html5_export'
    if os.path.exists(export_dir):
        os.chdir(export_dir)
        print(f"Serving files from {export_dir}/")
    else:
        print("Serving files from current directory")

    with socketserver.TCPServer(("", PORT), CORSHTTPRequestHandler) as httpd:
        print(f"Server running at http://localhost:{PORT}/")
        print("With Cross-Origin Isolation headers enabled")
        print("Press Ctrl+C to stop the server")

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped")
            sys.exit(0)

if __name__ == "__main__":
    run_server()
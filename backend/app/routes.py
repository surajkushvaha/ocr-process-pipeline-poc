# backend/app/routes.py
import os
from flask import jsonify, send_from_directory
from .constants import Constants

def register_routes(app):
    DIST_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../dist/frontend/browser/'))
    AUTH_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../dist/auth/browser/'))  # Fixed typo
    
    # Health check endpoint (no subdomain - for Docker/K8s)
    @app.route('/health')
    def health_check():
        return jsonify({"status": "OK", "service": "ocr-pipeline"}), 200
    
    # API subdomain (api.abc.com)
    @app.route('/health', subdomain='api')
    def health():
        return jsonify({"status": "OK"}), 200

    @app.route('/ocr', methods=['POST'], subdomain='api')
    def ocr():
        return jsonify({"message": "OCR processing not implemented yet."}), 501

    @app.route('/upload', methods=['POST'], subdomain='api')
    def upload():
        return jsonify({"message": "File upload not implemented yet."}), 501

    @app.route('/structure', methods=['POST'], subdomain='api')
    def structure():
        return jsonify({"message": "Document structuring not implemented yet."}), 501

    # Auth API subdomain (auth.abc.com)
    @app.route('/login', methods=['POST'], subdomain='auth')
    def login():
        return jsonify({"message": "Login not implemented yet."}), 501

    @app.route('/signup', methods=['POST'], subdomain='auth')
    def signup():
        return jsonify({"message": "Signup not implemented yet."}), 501

    # Auth UI (auth.abc.com) - serve auth Angular app
    @app.route('/', defaults={'path': ''}, subdomain='auth')
    @app.route('/<path:path>', subdomain='auth')
    def serve_auth(path):
        file_path = os.path.join(AUTH_FOLDER, path)
        if path != "" and os.path.exists(file_path):
            return send_from_directory(AUTH_FOLDER, path)
        else:
            return send_from_directory(AUTH_FOLDER, 'index.html')

    # Main app subdomain (app.abc.com)
    @app.route('/', defaults={'path': ''}, subdomain='app')
    @app.route('/<path:path>', subdomain='app')
    def serve_main_app(path):
        file_path = os.path.join(DIST_FOLDER, path)
        if path != "" and os.path.exists(file_path):
            return send_from_directory(DIST_FOLDER, path)
        else:
            return send_from_directory(DIST_FOLDER, 'index.html')

    # Root domain (abc.com) - landing page
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def serve_landing(path):
        return "Welcome to ABC.com - Landing page"
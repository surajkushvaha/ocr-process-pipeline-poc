from flask import Flask
from flask_socketio import SocketIO

def create_app():
    app = Flask(__name__)
    
    # For local development with subdomains
    app.config['SERVER_NAME'] = 'localhost:5000'  # or 'abc.com:5000'
    
    socketio = SocketIO(app, cors_allowed_origins="*")
    
    from .routes import register_routes
    from .sockets import register_sockets
    
    register_routes(app)
    register_sockets(socketio)
    
    return app, socketio


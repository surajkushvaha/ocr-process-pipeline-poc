def register_sockets(socketio):
    @socketio.on('connect')
    def handle_connect():
        print('Client connected')

    @socketio.on('disconnect')
    def handle_disconnect():
        print('Client disconnected')
        
    @socketio.on('message')
    def handle_message(msg):
        print('Message received:', msg)
from app import create_app, constants

app, socketio = create_app()

if __name__ == "__main__":
    socketio.run(app, debug=True, host="0.0.0.0", port=constants.Constants.PORT)
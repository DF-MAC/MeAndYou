# app/middleware/cors.py
from flask_cors import CORS


def setup_cors(app):
    # Customize this as needed
    CORS(app, resources={r"/api/*": {"origins": "*"}})

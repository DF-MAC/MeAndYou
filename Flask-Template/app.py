from flask import Flask
import os
from app import create_app

# Create an app instance for Gunicorn to find.
app = create_app()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 8000)), debug=True)

from flask import Flask
from .config import Config, DevelopmentConfig, TestingConfig, ProductionConfig
from .middleware import setup_server_middleware
from .database.connections import close_connection
import os
from .routes import create_user_route
from flask_restx import Api


def create_app(config_override=None):
    """Factory to create and configure the Flask app."""
    app = Flask(__name__)
    config_class = Config  # Default to base configuration

    # Select configuration based on the environment
    env = os.getenv('FLASK_ENV', 'development')
    if env == 'development':
        config_class = DevelopmentConfig
    elif env == 'testing':
        config_class = TestingConfig
    elif env == 'production':
        config_class = ProductionConfig

    app.config.from_object(config_class)  # Load default configuration

    # Apply any additional configuration settings provided at runtime
    if config_override:
        app.config.update(config_override)

    api = Api(app)
    create_user_route(api)

    setup_server_middleware(app)  # Setup middleware

    # Clean up DB connections on teardown
    app.teardown_appcontext(close_connection)

    return app

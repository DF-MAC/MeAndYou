### .flaskenv:
FLASK_APP=app.py
# The FLASK_RUN_PORT Value must be identical with what is in the Makefile
FLASK_RUN_PORT=8080
FLASK_ENV=development
### pyproject.toml:
[tool.poetry]
name = "your-flask-app"
version = "0.1.0"
description = ""
authors = ["Matthew McMorries <matthew.mcmorries@gmail.com>"]

[tool.poetry.dependencies]
python = "^3.12"
pathspec = "^0.12.1"
flask = {extras = ["async"], version = "^3.0.2"}
flask-cors = "^4.0.0"
python-dotenv = "^1.0.1"
flask-socketio = "^5.3.6"
flask-restx = "^1.3.0"
gunicorn = "^22.0.0"
flask-talisman = "^1.1.0"
redis = "^5.0.3"
mongoengine = "^0.28.2"
flask-mongoengine = "^1.0.0"
pytest-flask = "^1.3.0"
factory-boy = "^3.3.0"

[tool.poetry.dev-dependencies]
pytest = "^8.1.1"
black = "^24.4.0"
flake8 = "^7.0.0"
pytest-cov = "^5.0.0"
bandit = "^1.7.8"
safety = "^3.1.0"
backoff = "^2.2.1"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=your_flask_app --cov-report=term-missing"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

### app.py:
from flask import Flask
import os
from app import create_app

# Create an app instance for Gunicorn to find.
app = create_app()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 8000)), debug=True)

### app/config.py:
import os
import logging
from logging.handlers import RotatingFileHandler
from flask.logging import default_handler


class Config:
    # Base configuration with secure default for SECRET_KEY
    SECRET_KEY = os.environ.get(
        'SECRET_KEY', 'you_should_replace_this_secret_key')
    REDIS_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
    ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = False
    read_DB1 = os.environ.get('read_DB1')
    write_DB1 = os.environ.get('write_DB1')
    read_DB2 = os.environ.get('read_DB2')
    write_DB2 = os.environ.get('write_DB2')

    @staticmethod
    def log_config(logger):
        # Detailed configuration logs for debugging
        sensitive = ['SECRET_KEY']
        for var in ['SECRET_KEY', 'REDIS_URL', 'read_DB1', 'write_DB1', 'read_DB2', 'write_DB2']:
            value = Config.__dict__.get(var, 'Not Set')
            if var in sensitive:
                value = '****'  # Mask sensitive data
            logger.info(f"{var}: {value}")


class DevelopmentConfig(Config):
    DEBUG = True


class TestingConfig(Config):
    TESTING = True
    DEBUG = True


class ProductionConfig(Config):
    DEBUG = False


def setup_logging(app):
    log_level = logging.DEBUG if app.config['DEBUG'] else logging.INFO

    # Setup handlers
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    stream_handler.setLevel(log_level)
    app.logger.addHandler(stream_handler)

    if app.config['ENV'] == 'production':
        file_handler = RotatingFileHandler(
            'app.log', maxBytes=10000, backupCount=3)
        file_handler.setFormatter(formatter)
        file_handler.setLevel(log_level)
        app.logger.addHandler(file_handler)

    app.logger.setLevel(log_level)
    Config.log_config(app.logger)

### app/__init__.py:
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

### app/routes/user_routes.py:
from flask import request, jsonify
from flask_restx import Resource, Api
from app.database.models.user_model import User
from mongoengine.errors import ValidationError, NotUniqueError


def create_user_route(api):
    @api.route('/user/create')
    class UserCreate(Resource):
        def post(self):
            try:
                # Ensure JSON parsing even if content-type header is not set
                data = request.get_json(force=True)
                user = User(
                    email=data['email'],
                    first_name=data.get('first_name', ''),
                    last_name=data.get('last_name', ''),
                    roles=data.get('roles', [])
                )
                # This uses the setter to hash the password
                user.password = data['password']
                user.save()  # Save the user to the database
                return jsonify({'message': 'User created successfully', 'user_id': str(user.id)}), 201
            except ValidationError as ve:
                # Handle validation errors specifically from MongoEngine
                return jsonify({'error': str(ve)}), 400
            except NotUniqueError:
                # Handle the case where a user with the given email already exists
                return jsonify({'error': 'A user with that email already exists'}), 409
            except Exception as e:
                # General exception handler
                return jsonify({'error': str(e)}), 500

### app/routes/__init__.py:
from .user_routes import create_user_route

__all__ = ['create_user_route']

### tests/conftest.py:
import pytest
from app import create_app
from mongoengine import connect, disconnect
import os


@pytest.fixture(scope='module')
def test_app():
    # Set up configuration overrides for testing
    test_config = {
        'TESTING': True,
        # Set this to your specific test database URI if different
        'write_DB1': os.environ.get('write_DB1')
    }

    # Create an application instance with test configuration
    app = create_app(config_override=test_config)

    # Retrieve the updated connection string from app's config
    connection_string = app.config.get('write_DB1')

    # Establish a connection to the test database
    connect(host=connection_string, uuidRepresentation='standard')

    with app.app_context():
        yield app  # Provides the app context for tests

    # Clean up: Disconnect from the database after the tests are done
    disconnect()

### tests/__init__.py:
<EMPTY>
### tests/factories.py:
import factory
from factory.mongoengine import MongoEngineFactory
from app.database.models.user_model import User
import datetime
from werkzeug.security import generate_password_hash


class UserFactory(MongoEngineFactory):
    class Meta:
        model = User

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    first_name = factory.Faker('first_name')
    last_name = factory.Faker('last_name')
    is_active = True
    is_admin = False
    created_at = factory.LazyFunction(datetime.datetime.now)
    roles = factory.List([])

    # You don't need to define both `password_hash` and `password` as separate attributes
    # The `password` setter already handles setting the `password_hash`
    password = factory.PostGenerationMethodCall(
        'set_password', 'defaultPassword123')

### tests/test_routes.py:
import pytest
import json
from .factories import UserFactory


def test_create_user(test_app):
    client = test_app.test_client()
    # This builds a user but does not save it to the database
    user_data = UserFactory.build()
    response = client.post('/user/create', data=json.dumps({
        'email': user_data.email,
        # This should be handled by the set_password method
        'password': 'securepassword123',
        'first_name': user_data.first_name,
        'last_name': user_data.last_name,
        'roles': []  # Assuming roles is a list
    }), content_type='application/json')

    assert response.status_code == 201
    assert 'User created successfully' in response.get_json()['message']


def test_create_user_with_existing_email(test_app):
    client = test_app.test_client()
    # This creates and saves a user to the database
    existing_user_data = UserFactory.create()
    response = client.post('/user/create', data=json.dumps({
        'email': existing_user_data.email,  # Use an existing email
        'password': 'newPassword123',
        'first_name': 'New',
        'last_name': 'User',
        'roles': []
    }), content_type='application/json')

    assert response.status_code == 409
    assert 'A user with that email already exists' in response.get_json()[
        'error']


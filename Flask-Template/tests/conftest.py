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

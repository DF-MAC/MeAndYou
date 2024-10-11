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

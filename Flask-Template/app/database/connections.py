from mongoengine import connect, disconnect
from pymongo.errors import ConnectionFailure
import backoff
from flask import current_app, has_app_context, g


def handle_backoff(details):
    current_app.logger.warning(f"Backing off {details['wait']:0.1f} seconds after {details['tries']} tries calling function {
                               details['target'].__name__} with args {details['args']} and kwargs {details['kwargs']}")


def giveup_handler(exc):
    return not isinstance(exc, ConnectionFailure)


@backoff.on_exception(backoff.expo, ConnectionFailure, max_tries=5, on_backoff=handle_backoff, giveup=giveup_handler)
def get_db_connection(alias, connection_string):
    """
    Generic function to manage database connections.
    Retries on ConnectionFailure with exponential backoff.
    """
    if not has_app_context():
        raise RuntimeError(
            "This function can only be used within an app context.")

    if alias not in g:
        current_app.logger.info(f"Connecting to DB {alias}")
        g[alias] = connect(host=connection_string, alias=alias)

    return g[alias]


def close_db_connection(alias):
    """
    Closes the database connection cleanly.
    """
    if alias in g:
        try:
            disconnect(alias=alias)
            g.pop(alias, None)
            current_app.logger.info(f"Disconnected from DB {alias}")
        except Exception as e:
            current_app.logger.error(
                f"Failed to disconnect from DB {alias}: {str(e)}")


def read_db1():
    return get_db_connection('read_db1', current_app.config['read_DB1'])


def read_db2():
    return get_db_connection('read_db2', current_app.config['read_DB2'])


def write_db1():
    return get_db_connection('write_db1', current_app.config['write_DB1'])


def write_db2():
    return get_db_connection('write_db2', current_app.config['write_DB2'])


def close_connection(exception=None):
    for db_alias in ['read_db1', 'read_db2', 'write_db1', 'write_db2']:
        close_db_connection(db_alias)

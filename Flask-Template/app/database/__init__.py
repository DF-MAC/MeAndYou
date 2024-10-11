from .connections import read_db1, read_db2, write_db1, write_db2, close_connection

__all__ = ['read_db1', 'read_db2', 'write_db1',
           'write_db2', 'close_connection', 'database_connections']


def database_connections(app):
    app.teardown_appcontext(close_connection)
    app.cli.add_command(read_db1)
    app.cli.add_command(read_db2)
    app.cli.add_command(write_db1)
    app.cli.add_command(write_db2)

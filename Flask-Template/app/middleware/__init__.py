from .security import setup_security
from .cors import setup_cors


def setup_server_middleware(app):
    setup_security(app)
    setup_cors(app)
    # TODO: Add additional middleware setup calls here

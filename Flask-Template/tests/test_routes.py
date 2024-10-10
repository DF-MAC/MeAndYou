import pytest
import json
from .factories import UserFactory


def test_create_user(test_app):
    client = test_app.test_client()
    # This builds a user but does not save it to the database
    user_data = UserFactory.build()
    print("user_data in test_create_user: \n", user_data)
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

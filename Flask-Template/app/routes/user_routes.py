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

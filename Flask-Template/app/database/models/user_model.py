from mongoengine import Document, StringField, BooleanField, DateTimeField, ListField, EmailField, ObjectIdField
from werkzeug.security import generate_password_hash, check_password_hash
import datetime


class User(Document):
    meta = {'collection': 'users'}
    id = ObjectIdField(required=True, primary_key=True, unique=True)
    email = EmailField(required=True, unique=True)
    password_hash = StringField(required=True)
    first_name = StringField(max_length=50)
    last_name = StringField(max_length=50)
    is_active = BooleanField(default=True)
    is_admin = BooleanField(default=False)
    created_at = DateTimeField(default=datetime.datetime.now)
    roles = ListField(StringField(max_length=50))

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @property
    def password(self):
        raise AttributeError('password is not a readable attribute')

    @password.setter
    def password(self, password):
        self.set_password(password)

    def __repr__(self):
        return f'<User {self.email}>'

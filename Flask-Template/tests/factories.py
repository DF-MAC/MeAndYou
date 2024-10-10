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

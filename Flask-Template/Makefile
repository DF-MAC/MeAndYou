.PHONY: start test lint format dev clean security-checks

# The PORT here must be identical to the FLASK_RUN_PORT in the .flaskenv file
start:
	poetry run gunicorn -w 4 --log-file=- --bind 0.0.0.0:8080 "app:create_app()"

test:
	poetry run pytest --cov=app tests/

lint:
	poetry run flake8 app
	poetry run black app --check

format:
	poetry run black app

dev:
	poetry run flask run

clean:
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete
	rm -rf .pytest_cache build dist *.egg-info

security-checks:
	poetry run bandit -r app
	poetry run safety check

install-hooks:
	pre-commit install

hooks: lint test security-checks

docker-build:
	docker build -t your-flask-app .

docker-run:
	docker run -p 8080:8080 your-flask-app

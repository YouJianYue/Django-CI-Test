FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

COPY . .

# REMOVE this line:
# RUN python manage.py collectstatic --noinput

# Keep the CMD or ENTRYPOINT as is, it will be overridden by docker-compose command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "application.wsgi:application"]
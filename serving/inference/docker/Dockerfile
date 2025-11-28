
FROM python:3.11-slim

WORKDIR /app

COPY . /app

RUN pip install -r dev/python/requirements.txt

EXPOSE 50051

CMD ["python", "serving/inference/server.py"]


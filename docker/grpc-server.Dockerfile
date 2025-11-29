FROM python:3.11-slim-bookworm

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY serving /app/serving

ENV PYTHONPATH="/app"

EXPOSE 50051

CMD ["python", "serving/inference/server.py"]


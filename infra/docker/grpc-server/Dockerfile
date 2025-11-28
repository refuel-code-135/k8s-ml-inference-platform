FROM python:3.11-slim-bookworm

WORKDIR /app

# Install only runtime deps
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy entire serving directory exactly as-is
COPY serving /app/serving

# Set pythonpath so "serving" is resolvable
ENV PYTHONPATH="/app"

EXPOSE 50051

CMD ["python", "serving/inference/server.py"]


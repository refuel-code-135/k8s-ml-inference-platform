FROM python:3.11-slim-bookworm

WORKDIR /app

# runtime に必要な依存だけ入れる
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 最低限のコードだけコピー
COPY serving /app/serving

EXPOSE 50051

CMD ["python", "serving/inference/server.py"]


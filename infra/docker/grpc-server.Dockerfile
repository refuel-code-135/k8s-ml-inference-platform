FROM python:3.11-slim

WORKDIR /app

# プロジェクト全体をコピー
COPY . /app

# Python パッケージインストール
RUN pip install --no-cache-dir -r dev/python/requirements.txt

EXPOSE 50051

CMD ["python", "serving/inference/server.py"]

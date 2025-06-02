# Dockerfile
# Use an official Python base image
FROM python:3.11.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app code
COPY . .

# Run the FastAPI app using uvicorn
CMD ["uvicorn", "boiling_point:app", "--host", "0.0.0.0", "--port", "8080"]

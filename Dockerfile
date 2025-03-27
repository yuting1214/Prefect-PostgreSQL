# Use the official Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.9-bookworm-slim

# Install git and other necessary system dependencies
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Set environment variables
ENV UV_SYSTEM_PYTHON=1
ENV PATH="/root/.local/bin:$PATH"

# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .

# Install dependencies without using cache mount
RUN uv pip install -r requirements.txt

# Copy the rest of the application code
COPY . .

# Start the Prefect worker
CMD ["prefect", "worker", "start", "-p", "Process"]
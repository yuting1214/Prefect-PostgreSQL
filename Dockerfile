# Use the official Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:0.6.3-python3.9-bookworm

# Set the working directory
WORKDIR /app

# Set environment variables
ENV UV_SYSTEM_PYTHON=1
ENV PATH="/root/.local/bin:$PATH"

# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    uv pip install -r requirements.txt

# Copy the rest of the application code
COPY server.py .

# Set the entrypoint
ENTRYPOINT ["python", "server.py"]
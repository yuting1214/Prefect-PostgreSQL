# Use the official Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.9-bookworm-slim

# Set the working directory
WORKDIR /app

# Set environment variables
ENV UV_SYSTEM_PYTHON=1
ENV PATH="/root/.local/bin:$PATH"

# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .

# Install dependencies without using cache mount
RUN uv pip install -r requirements.txt

# Set environment variables for the database
# These can be overridden at runtime
ENV PREFECT_API_DATABASE_CONNECTION_URL="postgresql+asyncpg://postgres:postgres@localhost:5432/postgres"
ENV PREFECT_API_URL="http://0.0.0.0:4200/api"

# Start the Prefect server
CMD ["prefect", "server", "start", "--host", "0.0.0.0"]
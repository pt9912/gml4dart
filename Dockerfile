FROM dart:stable AS base

WORKDIR /app

# Copy only pubspec first for dependency caching
COPY ./pubspec.yaml ./pubspec.yaml
WORKDIR /app
RUN dart pub get

# Copy the rest of the package
COPY . .

# Analyze
FROM base AS analyze
RUN dart analyze

# Test
FROM base AS test
RUN dart test

# Doc
FROM base AS doc
RUN dart doc

# Publish dry-run
FROM base AS publish-check
RUN dart pub publish --dry-run

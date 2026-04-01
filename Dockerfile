FROM dart:stable AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    lcov \
    && rm -rf /var/lib/apt/lists/*

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


# Coverage report.
FROM base AS coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --packages=.dart_tool/package_config.json \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info    

# Coverage threshold check.
FROM coverage AS coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Doc — generate API documentation into doc/api/.
#
# Generate + extract:
#   docker build --target doc -t flutter_map_sld:doc .
#   docker run --rm flutter_map_sld:doc | tar -xzf -
FROM base AS doc
RUN dart doc
RUN test -f doc/api/index.html && echo "API docs generated: $(find doc/api -name '*.html' | wc -l) HTML files"
RUN tar -czf /doc-api.tar.gz doc/api
ENTRYPOINT ["cat", "/doc-api.tar.gz"]


# Publish dry-run
FROM base AS publish-check
RUN dart pub publish --dry-run

# gml4dart



## Entwicklung

Kein lokales Dart SDK nötig — alle Befehle laufen via Docker:

```bash
# Analyse
docker build --target analyze -t gml4dart:analyze .

# Tests
docker build --target test -t gml4dart:test .

# Dokumentation generieren
docker build --target doc -t gml4dart:doc .

# Publish Dry-Run
docker build --target publish-check -t gml4dart:publish-check .
```
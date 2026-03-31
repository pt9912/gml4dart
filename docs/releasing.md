# Releasing gml4dart

## Tag-Schema

Releases werden ausschließlich über annotierte Git-Tags im Format
`gml4dart-vX.Y.Z` veröffentlicht.

Beispiele:

- `gml4dart-v0.1.0`
- `gml4dart-v1.2.3`

Nicht vorgesehen:

- bare Tags wie `v0.1.0`
- Package-fremde Präfixe
- Pre-Releases wie `gml4dart-v1.2.3-rc.1`

## Release-Quelle

Release-Tags dürfen nur auf Commits gesetzt werden, die auf `main` oder
`master` liegen. Der Publish-Workflow prüft das vor dem Upload nach `pub.dev`.

## Release-Checkliste

1. `pubspec.yaml` auf die Zielversion setzen
2. `CHANGELOG.md` um `## X.Y.Z` ergänzen
3. lokal verifizieren:

   ```bash
   docker build --target analyze -t gml4dart:analyze .
   docker build --target test -t gml4dart:test .
   docker build --no-cache --target publish-check -t gml4dart:publish-check .
   ```

4. Änderungen committen und in den Release-Branch mergen
5. annotierten Tag anlegen:

   ```bash
   git tag -a gml4dart-vX.Y.Z -m "gml4dart vX.Y.Z"
   ```

6. Release-Branch und Tag pushen:

   ```bash
   git push origin <release-branch>
   git push origin gml4dart-vX.Y.Z
   ```

## Automatisches Publish

Der Workflow `.github/workflows/publish.yml` wird nur für Tags im Schema
`gml4dart-v*.*.*` gestartet und blockiert den Publish, wenn:

- Tag und `pubspec.yaml`-Version nicht übereinstimmen
- der passende Changelog-Eintrag fehlt
- der Tag nicht auf `main` oder `master` zeigt

Der eigentliche Upload läuft danach über den offiziellen
`dart-lang/setup-dart`-Publish-Workflow und das GitHub-Environment `pub.dev`.

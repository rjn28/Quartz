<p align="center">
  <img src="docs/quartz-logo.webp" width="96" height="96" alt="Icône de l’application Quartz">
</p>

<h1 align="center">Quartz</h1>

<p align="center"><strong>Un espace d’écriture privé et local pour macOS.</strong></p>

<p align="center">
  <a href="README.md">English</a>
  <span aria-hidden="true"> · </span>
  <strong>Français</strong>
</p>

<p align="center">
  <a href="https://github.com/rjn28/Quartz/actions/workflows/ci.yml"><img alt="État de la CI" src="https://github.com/rjn28/Quartz/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/rjn28/Quartz/actions/workflows/codeql.yml"><img alt="État de CodeQL" src="https://github.com/rjn28/Quartz/actions/workflows/codeql.yml/badge.svg"></a>
  <img alt="macOS 14 ou ultérieur sur Apple Silicon" src="https://img.shields.io/badge/macOS-14%2B%20Apple%20Silicon-black?logo=apple">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&amp;logoColor=white">
  <a href="LICENSE"><img alt="Licence Apache 2.0" src="https://img.shields.io/badge/licence-Apache--2.0-blue"></a>
</p>

Quartz est un éditeur de notes natif en SwiftUI, conçu pour écrire rapidement et sans distraction. Les notes et dessins restent dans les préférences locales du Mac ; Quartz ne nécessite aucun compte, aucune synchronisation cloud, aucune analyse d’usage et aucune connexion réseau.

## Fonctionnalités

- Éditeur de texte épuré dont les contrôles s’effacent pendant la saisie.
- Aperçu Markdown et vue divisée éditeur/aperçu redimensionnable.
- Zone de dessin propre à chaque note, avec formes, texte, couleurs, annulation et rétablissement.
- Historique persistant des notes enregistrées et fenêtres macOS indépendantes.
- Statistiques de mots, caractères, lignes et temps de lecture.
- Apparences claire et sombre, taille de texte configurable, raccourcis clavier et libellés VoiceOver.
- Export TXT ou PDF paginé, par clic ou glisser-déposer.

## Capture d’écran

<div align="center">
  <img src="docs/screenshot_ui.png" width="100%" alt="Fenêtre de l’éditeur Quartz">
</div>

## Prérequis

- macOS 14 Sonoma ou version ultérieure.
- Mac Apple Silicon. Les Mac Intel ne sont pas pris en charge.
- Xcode Command Line Tools avec Swift 6 pour le développement.

## Installation

Les versions publiées sont disponibles sur la [page Releases](https://github.com/rjn28/Quartz/releases). Les versions antérieures à `v1.3.0` sont d’anciens builds arm64 signés ad hoc et non notarisés ; vérifiez leur provenance avant de les exécuter. Le nouveau workflow de release refuse toute publication tant que l’application n’est pas signée Developer ID, notarisée, agrafée, accompagnée d’un checksum et attestée.

Tant qu’une version `v1.3.0` ou ultérieure notarisée n’est pas disponible, la compilation depuis les sources reste la méthode recommandée.

Pour les futures versions de confiance, téléchargez le `.dmg` et son fichier `.sha256`, puis vérifiez le checksum et la provenance GitHub avant d’ouvrir l’installeur :

```bash
shasum -a 256 -c Quartz-X.Y.Z.dmg.sha256
gh attestation verify Quartz-X.Y.Z.dmg --repo rjn28/Quartz
```

## Compiler depuis les sources

```bash
git clone https://github.com/rjn28/Quartz.git
cd Quartz
swift build
swift run QuartzApp
```

Lancez la validation locale complète :

```bash
./scripts/check.sh
```

Créez un DMG local Apple Silicon :

```bash
./scripts/package_app.sh
```

Le DMG est créé dans `BuildArtifacts/`. Sans `CODE_SIGN_IDENTITY`, le packaging local utilise une signature ad hoc réservée aux tests et impropre à une distribution publique. Consultez le [guide de release](docs/RELEASING.md) pour la signature Developer ID et la notarisation.

## Données et confidentialité

Quartz stocke les métadonnées, le texte et les données encodées du dessin dans le domaine `UserDefaults` `com.rjn28.Quartz` de l’utilisateur macOS courant. Les exports sont créés uniquement à la demande. Quartz ne transmet aucun contenu hors du Mac.

Avant de tester une migration ou une version non publiée avec des notes importantes, sauvegardez les préférences de l’application. Le rapport de santé du projet suit la future migration vers des enregistrements de notes atomiques et indépendants.

## Documentation du projet

- [Architecture](docs/ARCHITECTURE.md)
- [Audit et suivi des améliorations](docs/PROJECT_AUDIT.md)
- [Suivi des tests manuels et de l’acceptation de release](docs/TEST_TRACKER.md)
- [Feuille de route](ROADMAP.md)
- [Historique des changements](CHANGELOG.md)
- [Processus de release](docs/RELEASING.md)
- [Contribution](CONTRIBUTING.md)
- [Politique de sécurité](SECURITY.md)

## Contribuer

Les rapports de bugs et pull requests ciblées sont les bienvenus. Lisez [CONTRIBUTING.md](CONTRIBUTING.md) avant de commencer et signalez les vulnérabilités en privé comme indiqué dans [SECURITY.md](SECURITY.md).

## Licence

Quartz est open source sous la [licence Apache 2.0](LICENSE) approuvée par l’OSI (`Apache-2.0`). Vous pouvez utiliser, modifier, distribuer et exploiter Quartz commercialement dans le respect de ses conditions. La décision ainsi que l’ancienne politique non commerciale restent documentées dans [l’audit du projet](docs/PROJECT_AUDIT.md).

Maintenu par [Roch Junior Nicolas](https://github.com/rjn28).

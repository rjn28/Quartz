# Audit, remise à niveau et suivi du projet Quartz

> Document vivant de pilotage technique et communautaire.
> Audit initial : 10 août 2026.
> Branche de modernisation : `codex/modernize-quartz`.
> Mainteneur : `@rjn28`.

## 1. Objet du document

Ce rapport consolide :

- l'état initial réellement observé localement et sur GitHub ;
- les risques classés par priorité ;
- les décisions techniques prises pendant la remise à niveau ;
- les changements implémentés et leurs preuves de validation ;
- le travail restant, les décisions propriétaire et la cadence d'entretien recommandée.

Il doit rester à jour lors de chaque évolution structurelle, changement de politique de release, migration de données ou décision de licence.

## 2. Résumé exécutif

Quartz partait d'une application SwiftUI compacte et fonctionnelle, sans dépendance externe, dont le build Debug passait. Le dépôt présentait toutefois quatre catégories de risques majeurs :

1. **Durabilité des données** : migration incomplète depuis la release publique `v1.2`, sauvegarde canvas non vidée à la fermeture, fenêtres concurrentes capables de s'écraser, corruption globale non récupérable.
2. **Qualité et architecture** : aucune cible de tests, vues de 300 à 575 lignes, cible SwiftPM pointant sur toute la racine, deux booléens incompatibles pour le mode, erreurs d'export silencieuses.
3. **Distribution** : version bundle bloquée à `1.0 (1)`, binaire public arm64 seulement, signature ad hoc, aucune notarisation, aucun pipeline de release fiable.
4. **Dépôt et communauté** : aucune CI, aucune protection de branche, santé communautaire GitHub à 42 %, documentation obsolète, licence non commerciale présentée à tort comme open source, artefacts `.build` suivis et historique démesuré.

La branche de modernisation transforme le projet en base Swift 6 testable et maintenable : structure SwiftPM standard, 28 tests initiaux, migrations idempotentes, exports sûrs, interface découpée et accessible, packaging universel validé, CI/CodeQL/release fail-closed, documentation et gouvernance minimales.

Trois décisions ne doivent pas être prises implicitement : choix d'une licence OSI ou maintien source-available, financement/configuration Developer ID, et réécriture destructive éventuelle de l'historique Git.

## 3. Tableau de santé

| Domaine | État initial | État sur la branche | Cible durable |
| --- | --- | --- | --- |
| Build | Debug réussi, Swift 5 mode | Debug/Release Swift 6, concurrence stricte | Zéro warning sur toolchain supportée |
| Tests | `swift test` échoue : aucun test | 28 tests, 0 échec | Unitaires + UI + migrations de fixtures |
| Architecture | 6 fichiers à la racine, vues massives | `Sources/Quartz` par responsabilité | Limites de module et services injectables |
| Persistance | Blob global, migration incomplète | migration v2 + quarantaine + flush | fichiers atomiques indépendants |
| Multi-fenêtres | snapshots concurrents d'une même note | route stable et dédupliquée par note | test UI de restauration |
| Export | erreurs avalées, collisions, PDF géant | erreurs visibles, noms uniques, PDF paginé | panneau de sauvegarde optionnel + UI tests |
| Packaging | destructif, version en dur, arm64 | isolé, versionné, universel, vérifié | reproductibilité attestée |
| Release | ad hoc, non notarizée | workflow Developer ID/notary fail-closed | première `v1.3.0` vérifiée sur Mac propre |
| CI/sécurité | aucune Action, protections off | CI + CodeQL + dépendances Actions | checks requis + scans GitHub activés |
| Documentation | obsolète/incomplète | README et corpus mainteneur complets | mise à jour à chaque changement public |
| Licence | custom non commerciale, dite open source | terminologie source-available corrigée | décision explicite et licence revue |
| Git | `.build` suivi, historique ~80 Mio distant | croissance stoppée dans le tip | décision de nettoyage historique |

## 4. Baseline vérifiée

### 4.1 Local

- Branche initiale `main` exactement alignée sur `origin/main` au commit `6d0109c`.
- Aucun changement utilisateur initial avant la baseline.
- Apple Swift 6.3.3, cible locale arm64 macOS.
- `swift build` : succès.
- `swift test` : échec initial `no tests found`.
- Build en mode Swift 6 : succès avec un avertissement de concurrence sur la closure `Timer` de `ContentView`.
- `Package.swift` utilisait Swift tools 5.9, une cible exécutable à la racine et une liste d'exclusions fragile.
- Trois fichiers générés de `.build` restaient suivis malgré `.gitignore`.
- `.git` local pesait environ 123 Mio ; l'historique contenait plus de 2 300 blobs `.build` et plus de 230 Mio bruts avant compression.
- Aucun motif de secret haute confiance trouvé par les recherches locales ; aucun outil spécialisé de type gitleaks n'était installé.

### 4.2 GitHub

- Dépôt public `rjn28/Quartz`, administrable par le mainteneur.
- Une branche `main`, non protégée, aucun ruleset.
- Aucun workflow, run, statut ou check.
- Aucun issue, PR ou milestone.
- Santé communautaire : 42 %.
- Aucun topic, description générique, trois modes de merge autorisés, suppression automatique de branche désactivée.
- Private vulnerability reporting, secret scanning, push protection, Dependabot et CodeQL désactivés.
- Trois releases : `v1.0.0`, `v1.1`, `v1.2`.
- La release `v1.2` était huit commits derrière `main` au début de l'audit.
- Tags légers/non signés et versions historiques non homogènes.
- Le DMG `v1.2` avait un checksum GitHub cohérent mais contenait une app arm64 ad hoc, sans hardened runtime, notarisation ni ticket, avec version bundle `1.0 (1)` et rejet Gatekeeper attendu.

## 5. Registre des constats

### P0 — décisions et chaîne de confiance

| ID | Constat | Risque | Traitement | Statut |
| --- | --- | --- | --- | --- |
| P0-01 | Licence non commerciale incompatible avec l'étiquette « open source » | attentes juridiques et communautaires trompeuses | README corrigé en « source-available » ; choix final mainteneur requis | En attente décision |
| P0-02 | Releases publiques ad hoc/non notarizées | rejet Gatekeeper et faible confiance binaire | workflow Developer ID + hardened runtime + notary + staple + checksum + attestation | Implémenté, credentials requis |
| P0-03 | Version `1.0 (1)` dans toutes les releases | mises à jour et diagnostic impossibles | `VERSION`, injection plist et build number monotone | Implémenté |
| P0-04 | Historique Git dominé par `.build` | clones lourds, chemins machine exposés | retrait du tip ; nettoyage historique nécessite accord explicite | Partiel |
| P0-05 | Aucun garde-fou GitHub | régressions directes sur `main` | CI/CodeQL ajoutés ; protection après premier run réussi | À activer après push |

### P1 — données et correctness

| ID | Constat | Preuve initiale | Correction | Couverture |
| --- | --- | --- | --- | --- |
| P1-01 | Canvas `v1.2` non migré (`Quartz_canvas_shapes`) | migration HEAD connaissait seulement texte et clés window | migration v2, même après migration v1 déjà marquée | 2 tests directs/idempotents |
| P1-02 | Deux fenêtres d'une même note pouvaient s'écraser | `windowID` aléatoire + snapshots complets | route de fenêtre déterministe par `noteID` | test d'identité de route |
| P1-03 | Dernier dessin perdu si fermeture < 500 ms | debounce sans flush lifecycle | `flush()` canvas à la fermeture, disparition et scène inactive | test flush immédiat |
| P1-04 | Route initiale générée dans `body` | Binding optionnel non renseigné | overload `WindowGroup(... defaultValue:)` | build + revue |
| P1-05 | Une corruption pouvait vider puis écraser tout le blob | décodage tableau monolithique | copie de récupération avant nouvelles écritures | test corruption/quarantaine |
| P1-06 | Encre `Color.primary` parfois invisible | thème Quartz différent du thème système | `preferredColorScheme` + palette explicite | revue + tests modèle |
| P1-07 | Sauvegarde texte réencodait tout à chaque frappe | sink immédiat vers UserDefaults | debounce 250 ms + flush explicite | tests view model |

### P2 — robustesse, UX et maintenance

| ID | Constat | Correction actuelle | Suite éventuelle |
| --- | --- | --- | --- |
| P2-01 | Erreurs TXT/PDF silencieuses et force unwrap | APIs `throws`, alertes, URL valide obligatoire | panneau de sauvegarde configurable |
| P2-02 | Collisions de noms d'export | suffixe unique déterministe | nettoyage périodique du temporaire |
| P2-03 | PDF mono-page de taille arbitraire | pagination A4 sans ligne coupée, texte sélectionnable | maintenir la QA visuelle sur les longs documents |
| P2-04 | Split fixe moitié/moitié | `HSplitView` natif | restauration de largeur par fenêtre |
| P2-05 | Moniteur souris global par fenêtre | `onContinuousHover` SwiftUI | test UI multi-fenêtres |
| P2-06 | Timer non isolé Swift 6 | tâche `@MainActor` annulable | aucun |
| P2-07 | Preview/split en deux booléens invalides | `EditorMode` invariant | migrer le schéma stocké lors du futur repository |
| P2-08 | Canvas corrompu impossible à vider | bannière de récupération + reset actif | export de récupération brut |
| P2-09 | Carré mal ancré lors d'un drag négatif | géométrie corrigée | coordonnées normalisées au redimensionnement |
| P2-10 | Toolbar fixe et menu déplaçable hors écran | barre ancrée, scroll horizontal, min window | vraie toolbar native à évaluer |
| P2-11 | Accessibilité et clavier faibles | labels/values, commandes ⌘1/2/3, canvas, undo/redo, Reduce Motion | audit VoiceOver manuel + UI tests |
| P2-12 | Markdown utilisateur traité comme clé localisée | `AttributedString` inline explicite | parseur complet/mise en cache si nécessaire |

## 6. Changements structurels réalisés

### 6.1 Swift et SwiftPM

- Swift tools 6.0.
- Cible `Quartz` sous `Sources/Quartz`.
- Cible `QuartzTests` sous `Tests/QuartzTests`.
- Ressources réellement rattachées à la cible.
- Séparation App / Models / Services / Stores / Support / ViewModels / Views.
- Zéro dépendance tierce : surface supply-chain minimale conservée.

### 6.2 Modèle de données

- `EditorRoute` réduit à l'identité métier `noteID`.
- `EditorMode` garantit un seul des modes editor/preview/split.
- `TextStatistics` devient un modèle pur et testé ; lecture arrondie vers le haut.
- `DrawableShape.squareRect` respecte le point de départ dans les quatre directions.
- Palette canvas nommée, explicite et accessible.

### 6.3 Persistance

- Store `UserDefaults` injectable pour les tests.
- Horloge injectable pour les écritures/migrations déterministes.
- Migration par étapes et marquage uniquement après persistance réussie.
- Migration v2 du canvas global `v1.2` sans suppression de la source legacy.
- Copie de récupération d'un blob moderne illisible.
- Suppression cohérente des notes vraiment vides et conservation des notes canvas-only.

### 6.4 Interface

- Racine `ContentView` recentrée sur la composition et le cycle de fenêtre.
- Sous-vues editor workspace, contrôles, preview Markdown et canvas séparées.
- Split redimensionnable.
- Focus initial stable, champ de texte canvas focalisé, Escape/Return gérés.
- Zen Mode sans pont AppKit ni moniteur applicatif.
- Feedback d'export visible.
- Raccourcis de modes et dessin via `FocusedValue`.

### 6.5 Exports

- Fichiers temporaires/destination uniques.
- Échecs propagés jusqu'à l'utilisateur.
- Drag sans force unwrap.
- PDF standard multipage ; PDF disponible aussi en split.
- Typesetting isolé par ligne, rendu visible déterministe et couche texte sélectionnable.
- Tests ouvrant réellement le PDF avec PDFKit, vérifiant pagination, continuité et unicité du contenu.

### 6.6 Packaging et release

- `bundle_app.sh` conservé comme wrapper compatible.
- Script strict `set -euo pipefail` et staging `mktemp` nettoyé par trap.
- Build universel `arm64 x86_64` vérifié avec `lipo`.
- Info.plist suivi, version centralisée `1.3.0`, build number injecté.
- Iconset complet créé à partir des ressources suivies.
- Copie des futurs bundles de ressources SwiftPM.
- Signature ad hoc clairement limitée au local ; Developer ID active hardened runtime et timestamp.
- Vérifications plist, codesign, architectures, DMG et SHA-256.
- Workflow release avec tag signé, environnement protégé, notarisation, stapling, Gatekeeper, attestation et publication.

### 6.7 GitHub et communauté

- CI avec checks locaux et packaging universel smoke-testé.
- CodeQL Swift hebdomadaire et sur PR/push.
- Actions tierces/first-party épinglées à des SHA exacts.
- Dependabot mensuel pour GitHub Actions.
- Formulaires d'issue, template PR, CODEOWNERS.
- README, contribution, sécurité, support, conduite, mainteneur, roadmap, changelog, architecture et release guide.

## 7. Stratégie de tests

La suite initiale protège les comportements qui exposaient le plus de données ou de confiance :

- statistiques et invariants editor mode ;
- titres/menu et notion de note vide ;
- persistance et rechargement ;
- note canvas-only ;
- quarantaine de blob corrompu ;
- migration texte/canvas directe depuis `v1.2` ;
- réparation v2 après passage préalable de la migration v1 ;
- migration per-window antérieure ;
- unicité/déduplication des routes ;
- géométrie des carrés dans quatre directions ;
- round-trip canvas ;
- flush sans attendre le debounce, à la fermeture et quand la scène devient inactive ;
- undo/redo et reset d'un canvas corrompu ;
- contenu TXT et collisions ;
- copie Desktop unique ;
- PDF lisible, paragraphe long, pagination et présence exacte de chaque ligne/token ;
- flush/restauration du view model.

Tests manquants à planifier : lancement UI, restauration de plusieurs fenêtres, comportement réel `openWindow` sur note déjà ouverte, VoiceOver, Reduce Motion, drag inter-app, installation depuis DMG notarizé, et migration avec une fixture de préférences capturée depuis une vraie `v1.2`.

## 8. Validation de la branche

Matrice à maintenir à chaque changement :

| Vérification | Commande | Résultat actuel |
| --- | --- | --- |
| Description package | `swift package describe` | Réussi |
| Build Debug | `swift build` | Réussi |
| Swift 6 concurrence stricte | `swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors` | Réussi |
| Tests | `swift test` | 28/28 réussis |
| Build Release | `swift build -c release` | Réussi |
| Syntaxe shell | `bash -n bundle_app.sh scripts/*.sh` | Réussi |
| Packaging universel | `./scripts/package_app.sh` | Réussi |
| Architectures | `lipo -archs` | `arm64 x86_64` |
| Plist | `plutil -lint` | Réussi |
| Signature locale | `codesign --verify --deep --strict` | Réussi, ad hoc attendue |
| DMG | `hdiutil verify` | Réussi |
| Whitespace | `git diff --check` | Réussi |
| YAML workflows | parse YAML local | Réussi |
| PDF visuel | `pdftoppm` + inspection indépendante | Réussi : 7 pages A4, lignes 1–180 continues, aucun glyphe tronqué |
| UI smoke test | lancement + contrôle accessibilité | Réussi : editor/preview/split, canvas, undo/redo, raccourcis et labels AX |
| CI distante | GitHub Actions | À renseigner après push |
| CodeQL distant | GitHub Actions | À renseigner après push |

## 9. Backlog priorisé

### Bloquants avant release `v1.3.0`

- [ ] Choisir et valider la licence.
- [ ] Relire/merger la PR avec CI et CodeQL verts.
- [ ] Configurer l'environnement GitHub `release` et les secrets Developer ID.
- [ ] Créer une clé de signature Git pour les tags et documenter sa garde.
- [ ] Activer les protections `main` et tags à partir des noms de checks observés.
- [ ] Tester la migration sur une copie réelle des préférences `v1.2`.
- [ ] Tester le DMG notarizé sur un Mac propre et sur Intel si possible.
- [ ] Mettre le changelog en section datée et créer le tag signé `v1.3.0`.

### P1 après release

- [ ] Repository fichier/record atomique sous Application Support.
- [ ] Schéma persistant explicite avec lecture tolérante entrée par entrée.
- [ ] Coordonnées canvas normalisées avec taille de référence et migration.
- [ ] Tests UI multi-fenêtres et accessibilité.
- [ ] Benchmark de frappe avec bibliothèque/canvas volumineux.
- [ ] Sauvegarde/import d'une note Quartz complète.

### P2 maintenance dépôt

- [ ] Décider puis exécuter ou refuser formellement le nettoyage historique `git-filter-repo`.
- [ ] Publier un canal privé dédié aux signalements de conduite et l'ajouter à `MAINTAINERS.md`/`CODE_OF_CONDUCT.md`.
- [ ] Ajouter une social preview optimisée sur GitHub.
- [ ] Décider documentation anglaise seule ou bilingue.
- [ ] Évaluer Discussions uniquement si le volume communautaire le justifie.
- [ ] Mettre en place un scanner local spécialisé si les dépendances augmentent.

## 10. Décisions enregistrées

| Date | Décision | Motif | Réversible |
| --- | --- | --- | --- |
| 2026-08-10 | Swift tools 6.0 | concurrence stricte et base moderne compatible macOS 14 | Oui, mais non souhaité |
| 2026-08-10 | Aucune dépendance externe | besoin couvert nativement, supply-chain réduite | Oui |
| 2026-08-10 | Une fenêtre typée par note | empêche l'écrasement par snapshots stale | Oui, avec session partagée à concevoir |
| 2026-08-10 | UserDefaults renforcé avant migration de backend | éviter une migration de stockage spéculative dans le même lot | Oui |
| 2026-08-10 | `v1.3.0` comme prochaine version préparée | `v1.2` existe et `main` contient déjà plusieurs fonctionnalités | Oui avant tag |
| 2026-08-10 | Distribution universelle | macOS 14 supporte encore des Macs Intel | Oui |
| 2026-08-10 | Release fail-closed | ne plus demander aux utilisateurs d'affaiblir Gatekeeper | Non négociable pour les binaires publics |
| 2026-08-10 | Terminologie source-available | reflète la licence actuelle sans la modifier implicitement | Oui après décision de licence |

## 11. Cadence d'entretien recommandée

### À chaque pull request

- tests, build strict, release build, `git diff --check` ;
- revue des migrations et du risque de perte de données ;
- documentation publique mise à jour si le comportement change ;
- aucune Action non épinglée, aucun secret et aucun artefact généré suivi.

### Mensuel

- traiter les PR Dependabot Actions ;
- revoir alertes CodeQL, Dependabot et secret scanning ;
- vérifier issues/roadmap et fermer les éléments obsolètes ;
- tester un export TXT/PDF et un rechargement de note sur la version de développement.

### À chaque release

- suivre intégralement `docs/RELEASING.md` ;
- tester install/launch sur machine propre ;
- vérifier signature, ticket, checksum et attestation ;
- archiver la matrice des architectures/macOS testées ;
- déplacer Unreleased dans CHANGELOG et réévaluer versions supportées dans SECURITY.

### Trimestriel

- audit taille du dépôt et des assets ;
- audit dépendances/toolchain/runner GitHub ;
- exercice de restauration d'une sauvegarde de notes ;
- audit manuel VoiceOver, clavier, clair/sombre et Reduce Motion.

## 12. Questions propriétaire ouvertes

1. Quartz doit-il adopter une licence open source reconnue par l'OSI, et laquelle, ou conserver explicitement l'interdiction commerciale/App Store ?
2. Un abonnement Apple Developer et un certificat Developer ID peuvent-ils être financés et configurés pour `v1.3.0` ?
3. La documentation doit-elle rester principalement en anglais, devenir bilingue anglais/français, ou passer en français ?
4. Faut-il autoriser une réécriture destructive de tout l'historique pour supprimer les anciens blobs `.build`, avec force-push coordonné et obligation de re-cloner ?
5. Après la première CI verte, `main` doit-elle exiger systématiquement une PR, ou seulement les checks et l'interdiction des force-push/suppressions pour ce dépôt solo ?
6. La portée thème/police/mode doit-elle rester par note ou devenir une préférence globale/par fenêtre ?
7. Quel canal privé (adresse dédiée ou formulaire externe) faut-il publier pour les signalements de conduite ?

## 13. Règle de mise à jour de ce rapport

Lorsqu'un item est terminé :

1. cocher le backlog ;
2. ajouter la preuve de validation et le lien PR/release ;
3. enregistrer toute décision irréversible ou migration ;
4. mettre à jour le tableau de santé ;
5. déplacer les détails historiques dans le changelog si le rapport devient trop long.

Le dépôt ne doit être considéré « prêt pour release » que lorsque tous les bloquants de la section 9 sont fermés avec preuves, pas seulement parce que le build local réussit.

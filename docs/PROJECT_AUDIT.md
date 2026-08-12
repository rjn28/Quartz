# Audit, remise à niveau et suivi du projet Quartz

> Document vivant de pilotage technique et communautaire.
> Audit initial : 10 août 2026.
> Modernisation fusionnée sur `main` via la pull request [#2](https://github.com/rjn28/Quartz/pull/2).
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

La branche de modernisation transforme le projet en base Swift 6 testable et maintenable : structure SwiftPM standard, 28 tests initiaux, migrations idempotentes, exports sûrs, interface découpée et accessible, packaging Apple Silicon validé, CI/CodeQL/release fail-closed, documentation et gouvernance minimales. Le premier passage distant de CI et CodeQL est vert ; `main`, les tags de release et les fonctions de sécurité natives GitHub sont désormais protégés.

Les décisions propriétaire sont désormais enregistrées : passage à la licence open source OSI Apache-2.0, Apple Developer visé à court terme, support Apple Silicon uniquement, préférences par note, documentation technique en anglais avec un README EN/FR, passage obligatoire par pull request et nettoyage historique autorisé à condition de préserver auteurs, dates, messages et ancienneté.

## 3. Tableau de santé

| Domaine | État initial | État sur la branche | Cible durable |
| --- | --- | --- | --- |
| Build | Debug réussi, Swift 5 mode | Debug/Release Swift 6, concurrence stricte | Zéro warning sur toolchain supportée |
| Tests | `swift test` échoue : aucun test | 28 tests, 0 échec | Unitaires + UI + migrations de fixtures |
| Architecture | 6 fichiers à la racine, vues massives | `Sources/Quartz` par responsabilité | Limites de module et services injectables |
| Persistance | Blob global, migration incomplète | migration v2 + quarantaine + flush | fichiers atomiques indépendants |
| Multi-fenêtres | snapshots concurrents d'une même note | route stable et dédupliquée par note | test UI de restauration |
| Export | erreurs avalées, collisions, PDF géant | erreurs visibles, noms uniques, PDF paginé | panneau de sauvegarde optionnel + UI tests |
| Packaging | destructif, version en dur, arm64 | isolé, versionné, Apple Silicon, vérifié | reproductibilité attestée |
| Release | ad hoc, non notarizée | workflow Developer ID/notary fail-closed | première `v1.3.0` vérifiée sur Mac propre |
| CI/sécurité | aucune Action, protections off | CI + CodeQL verts, checks requis, scans et tags protégés | surveiller alertes et maintenir les SHA Actions |
| Documentation | obsolète/incomplète | README et corpus mainteneur complets | mise à jour à chaque changement public |
| Licence | custom non commerciale, dite open source | Apache-2.0 OSI adoptée et documentation alignée | conserver métadonnées SPDX, attribution et conformité |
| Git | `.build` suivi, historique ~80 Mio distant | `.build` retiré de tout l'historique, chronologie conservée | annoncer les nouveaux hashes et garder la sauvegarde hors remote |

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
| P0-01 | Licence non commerciale incompatible avec l'étiquette « open source » | attentes juridiques et communautaires trompeuses | remplacement explicite par Apache-2.0, licence standard approuvée OSI | Terminé |
| P0-02 | Releases publiques ad hoc/non notarizées | rejet Gatekeeper et faible confiance binaire | workflow Developer ID + hardened runtime + notary + staple + checksum + attestation | Implémenté ; compte Apple prévu à court terme |
| P0-03 | Version `1.0 (1)` dans toutes les releases | mises à jour et diagnostic impossibles | `VERSION`, injection plist et build number monotone | Implémenté |
| P0-04 | Historique Git dominé par `.build` | clones lourds, chemins machine exposés | bundle complet vérifié puis filtre ciblé avec conservation des commits et métadonnées | Terminé |
| P0-05 | Aucun garde-fou GitHub | régressions directes sur `main` | CI/CodeQL requis, historique linéaire, force-push/suppression bloqués, tags `v*` immuables | Terminé |

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

- Scripts de lancement, validation et packaging regroupés dans `scripts/` ; wrapper racine historique supprimé.
- Script strict `set -euo pipefail` et staging `mktemp` nettoyé par trap.
- Build Apple Silicon `arm64` uniquement, vérifié avec `lipo`.
- Info.plist suivi, version centralisée `1.3.0`, build number injecté.
- Iconset complet créé à partir des ressources suivies.
- Copie des futurs bundles de ressources SwiftPM.
- Signature ad hoc clairement limitée au local ; Developer ID active hardened runtime et timestamp.
- Vérifications plist, codesign, architectures, DMG et SHA-256.
- Workflow release avec tag signé, environnement protégé, notarisation, stapling, Gatekeeper, attestation et publication.

### 6.7 GitHub et communauté

- CI avec checks locaux et packaging Apple Silicon smoke-testé.
- CodeQL Swift hebdomadaire et sur PR/push.
- Actions tierces/first-party épinglées à des SHA exacts.
- Dependabot mensuel pour GitHub Actions.
- Formulaires d'issue, template PR, CODEOWNERS.
- README, contribution, sécurité, support, conduite, mainteneur, roadmap, changelog, architecture et release guide.
- Description et huit topics techniques publiés ; label `needs-triage` créé.
- Alertes et correctifs Dependabot, private vulnerability reporting, secret scanning et push protection activés.
- Actions limitées aux actions appartenant à GitHub avec épinglage SHA obligatoire.
- Merge limité au squash, historique linéaire et suppression automatique des branches fusionnées.
- `main` protégé par `Validate` et `Analyze Swift`, branche à jour et conversations résolues ; force-push et suppression interdits.
- Ruleset actif `Protect release tags` : création de nouveaux tags `v*` autorisée, modification et suppression interdites.

### 6.8 Hygiène de l'historique Git

- Bundle complet de récupération créé et vérifié dans `.git/quartz-before-filter-20260810.bundle` ; il n'est jamais poussé.
- `git-filter-repo` limité au chemin `.build/`, avec conservation explicite des commits devenus vides et de la topologie.
- Les 25 commits de `main`, les 28 commits de la branche de modernisation, les auteurs, dates, messages et trois tags sont conservés.
- Le premier commit reste daté du 3 décembre 2025 avec son auteur et son message d'origine.
- Les 3 346 objets nommés sous `.build/` passent à zéro ; le pack Git utile local passe à environ 9,51 Mio hors bundle de sauvegarde.
- Les hashes sont nécessairement recalculés. Tout clone existant doit être re-cloné ou réaligné explicitement après publication de l'historique filtré.

## 7. Stratégie de tests

Le suivi durable des validations manuelles et de l'acceptation mainteneur vit dans [`docs/TEST_TRACKER.md`](TEST_TRACKER.md). Les tests manuels y restent explicitement `NOT RUN` tant que le mainteneur n'a pas communiqué son propre résultat ; ils sont distincts des validations automatisées et des contrôles assistés réalisés pendant l'audit.

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
| Syntaxe shell | `bash -n scripts/*.sh` | Réussi |
| Packaging Apple Silicon | `./scripts/package_app.sh` | Réussi |
| Architecture | `lipo -archs` | `arm64` uniquement |
| Plist | `plutil -lint` | Réussi |
| Signature locale | `codesign --verify --deep --strict` | Réussi, ad hoc attendue |
| DMG | `hdiutil verify` | Réussi |
| Nettoyage historique | `git filter-repo` + contrôles avant/après | Réussi : commits/tags/dates conservés, `.build` = 0 |
| Whitespace | `git diff --check` | Réussi |
| YAML workflows | parse YAML local | Réussi |
| PDF visuel | `pdftoppm` + inspection indépendante | Réussi : 7 pages A4, lignes 1–180 continues, aucun glyphe tronqué |
| UI smoke test assisté | lancement + contrôle accessibilité | Réussi pendant l'audit : editor/preview/split, canvas, undo/redo, raccourcis et labels AX |
| Acceptation manuelle mainteneur | [`docs/TEST_TRACKER.md`](TEST_TRACKER.md) | En cours ; lancement depuis les sources validé |
| Préflight Developer ID/notarisation | DMG local `1.3.0 (1001)` | Réussi ; Apple `Ready for distribution`, aucun problème, Gatekeeper accepte le DMG et l'app |
| CI distante | [run `31347600641`](https://github.com/rjn28/Quartz/actions/runs/31347600641) | Réussi (`Validate`, 1 min 28) |
| CodeQL distant | [run `31347600613`](https://github.com/rjn28/Quartz/actions/runs/31347600613) | Réussi (`Analyze Swift`, 14 min 10) |

## 9. Backlog priorisé

### Bloquants avant release `v1.3.0`

- [x] Adopter Apache-2.0, licence standard approuvée OSI, et aligner toute la documentation publique.
- [x] Relire/merger la PR avec CI et CodeQL verts.
- [x] Configurer l'environnement GitHub `release` et les secrets Developer ID.
- [x] Créer une clé de signature Git dédiée à Quartz, limitée aux tags de release, et documenter sa garde.
- [x] Activer les protections `main` et tags à partir des noms de checks observés.
- [ ] Tester la migration sur une copie réelle des préférences `v1.2`.
- [ ] Tester le DMG notarizé sur un Mac Apple Silicon propre.
- [x] Mettre le changelog en section datée pour `v1.3.0`.
- [ ] Créer et pousser le tag signé `v1.3.0` depuis le commit de release validé.

### P1 après release

- [ ] Repository fichier/record atomique sous Application Support.
- [ ] Schéma persistant explicite avec lecture tolérante entrée par entrée.
- [ ] Coordonnées canvas normalisées avec taille de référence et migration.
- [ ] Tests UI multi-fenêtres et accessibilité.
- [ ] Benchmark de frappe avec bibliothèque/canvas volumineux.
- [ ] Sauvegarde/import d'une note Quartz complète.
- [ ] Après la première release notarisée, intégrer Sparkle avec appcast et signatures EdDSA, tests fail-closed et procédure de rollback.

### P2 maintenance dépôt

- [x] Exécuter le nettoyage historique `git-filter-repo` avec sauvegarde locale, sans perdre auteurs, dates, messages ni ancienneté.
- [ ] Publier un canal privé dédié aux signalements de conduite et l'ajouter à `MAINTAINERS.md`/`CODE_OF_CONDUCT.md`.
- [ ] Ajouter une social preview optimisée sur GitHub.
- [x] Conserver la documentation technique en anglais et proposer un sélecteur README EN/FR sur GitHub.
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
| 2026-08-10 | Distribution Apple Silicon uniquement | périmètre produit explicitement choisi par le mainteneur | Oui |
| 2026-08-10 | Release fail-closed | ne plus demander aux utilisateurs d'affaiblir Gatekeeper | Non négociable pour les binaires publics |
| 2026-08-10 | Licence non commerciale et terminologie source-available | choix initial explicite du mainteneur ; ne pas présenter Quartz comme OSI open source | Supplantée le 2026-08-11 |
| 2026-08-11 | Relicencier Quartz sous Apache License 2.0 (`Apache-2.0`) | afficher un engagement open source OSI clair et reconnu auprès des recruteurs, utilisateurs et contributeurs | Non pour les copies déjà publiées sous Apache-2.0 ; changement prospectif possible |
| 2026-08-10 | Squash-only et branches fusionnées supprimées | historique lisible et entretien réduit | Oui |
| 2026-08-10 | Toute modification de `main` doit passer par une PR | décision explicite du mainteneur | Oui |
| 2026-08-10 | Tags `v*` non modifiables et non supprimables | conserver l'identité et la traçabilité des releases | Oui via le ruleset |
| 2026-08-10 | Compte Apple Developer visé à court terme | permettre une première release Developer ID notarisée | Oui |
| 2026-08-10 | Sparkle seulement après notarisation | ne pas ajouter une chaîne de mise à jour avant d'avoir une chaîne de release fiable | Oui |
| 2026-08-10 | Documentation anglaise, README EN/FR | corpus technique uniforme avec accueil GitHub bilingue | Oui |
| 2026-08-10 | Thème, police et mode restent par note | choix d'expérience explicite du mainteneur | Oui avec migration |
| 2026-08-10 | Nettoyage `.build` autorisé si chronologie préservée | réduire le dépôt sans effacer son ancienneté visible | Réécrit les hashes, sauvegarde requise |

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

## 12. Décision propriétaire encore ouverte

Un canal privé de conduite sert à recevoir confidentiellement les signalements de harcèlement, comportement abusif ou violation du Code of Conduct. Il est distinct du private vulnerability reporting, réservé aux failles techniques. Aucun email ne sera publié sans consentement ; `CODE_OF_CONDUCT.md` reste transparent sur l'absence actuelle de canal dédié jusqu'au choix éventuel d'une adresse ou d'un formulaire privé.

## 13. Règle de mise à jour de ce rapport

Lorsqu'un item est terminé :

1. cocher le backlog ;
2. ajouter la preuve de validation et le lien PR/release ;
3. enregistrer toute décision irréversible ou migration ;
4. mettre à jour le tableau de santé ;
5. déplacer les détails historiques dans le changelog si le rapport devient trop long.

Le dépôt ne doit être considéré « prêt pour release » que lorsque tous les bloquants de la section 9 sont fermés avec preuves, pas seulement parce que le build local réussit.

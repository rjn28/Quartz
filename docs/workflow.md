# 🔄 Workflow de Mise à Jour de l'Application

Ce document explique comment déployer une nouvelle version de l'application Quartz.

## Le Cycle de Vie (3 Étapes)

Pour sortir une mise à jour (ex: passer de v1.0 à v1.1), suivez ces étapes rigoureusement :

### 1. Coder & Tester 👨‍💻
* Effectuez vos modifications dans le code Swift (nouvelles fonctionnalités, corrections de bugs).
* Testez l'application en mode Debug via votre IDE ou `swift run`.

### 2. Versionner (Incrémentation) 🏷️
Avant de compiler, il faut dire à macOS que la version a changé.
1. Ouvrez le fichier `bundle_app.sh`.
2. Modifiez les lignes suivantes dans la section `Info.plist` :

```bash
<key>CFBundleShortVersionString</key>
<string>1.1</string>  <key>CFBundleVersion</key>
<string>2</string>    ```

### 3. Compiler & Packager 📦
Lancez le script d'automatisation depuis le terminal à la racine du projet :

```bash
./bundle_app.sh
```

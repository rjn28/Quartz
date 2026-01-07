# 🛠 Git Toolbox

Un aide-mémoire des commandes indispensables pour naviguer dans l'univers Git.

## 🚀 Flux Quotidien (Le Pain Quotidien)
- `git status` : Voir l'état des fichiers (modifiés, suivis, etc.).
- `git add .` : Préparer TOUS les fichiers modifiés pour le commit.
- `git add <file>` : Préparer un fichier spécifique.
- `git commit -m "message"` : Enregistrer les changements localement.
- `git push` : Envoyer les commits locaux vers le serveur (GitHub).
- `git pull` : Récupérer et fusionner les nouveautés du serveur.

## 🔍 Exploration et Infos
- `git log --oneline` : Voir l'historique des commits de manière condensée.
- `git diff` : Voir les modifications non préparées (avant le `git add`).
- `git fetch` : Télécharger les infos du serveur sans fusionner.

## 🌿 Branches (Travailler en parallèle)
- `git branch` : Lister les branches locales.
- `git checkout -b <nom>` : Créer une nouvelle branche et basculer dessus.
- `git checkout <nom>` : Basculer sur une branche existante.
- `git merge <nom>` : Fusionner une branche dans la branche actuelle.

## 🚑 Secours et Modifications
- `git commit --amend` : Modifier le dernier commit (message ou fichiers oubliés).
- `git reset --hard HEAD` : Annuler TOUT le travail non committé (⚠️ irréversible).
- `git checkout <file>` : Annuler les modifs d'un fichier spécifique.
- `git revert <commit>` : Créer un nouveau commit qui annule un commit précédent.

---

## 💡 Comment stocker ces commandes intelligemment ?

### 1. Les Alias Git (Le plus puissant)
Au lieu de taper `git checkout`, vous pouvez configurer des raccourcis dans votre fichier `~/.gitconfig` :
```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.cm "commit -m"
```
*Usage :* `git co ma-branche` au lieu de `git checkout ma-branche`.

### 2. Le fichier de "Snippet" (Ce que nous venons de créer)
Gardez ce fichier `docs/git_commands.md` dans votre projet. C'est idéal pour :
- Les commandes complexes que vous oubliez souvent.
- Partager les bonnes pratiques avec votre équipe.

### 3. Les Gists GitHub
Si vous voulez accéder à vos commandes partout :
- Créez un **Secret Gist** sur GitHub (gist.github.com).
- Collez-y votre liste.
- Vous pourrez y accéder via n'importe quel navigateur.

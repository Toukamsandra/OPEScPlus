# Collecte automatique

Sans cela, les données vieillissent en silence : la plateforme affiche des
chiffres périmés avec la même assurance que des chiffres récents.

Deux dispositions, et l'ordre compte.

## 1. La plateforme le dit d'elle-même

Un bandeau apparaît sous la barre d'onglets dès que les données dépassent
quarante-cinq jours, et passe en alerte au-delà de cent vingt. Rien ne
s'affiche tant qu'elles sont récentes : une mention permanente deviendrait du
décor et ne serait plus lue le jour où elle compte.

Ce dispositif fonctionne même si personne n'automatise jamais rien. C'est le
plus important des deux.

## 2. La tâche planifiée

### Installer

Ouvrez le **Planificateur de tâches** de Windows, puis :

1. **Créer une tâche** (pas « tâche de base »).
2. Onglet *Général* : nommez-la `OPESc+ collecte hebdomadaire`. Cochez
   **Exécuter même si l'utilisateur n'est pas connecté**.
3. Onglet *Déclencheurs* : nouveau déclencheur, **hebdomadaire**, le lundi à
   6 h 00.
4. Onglet *Actions* : nouvelle action, **Démarrer un programme**.
   - Programme : `C:\Program Files\R\R-4.4.1\bin\Rscript.exe`
     (ajustez le numéro de version à celle installée)
   - Arguments : `"C:\Users\user\Documents\OPEScGolem_V2\opescplus\dev\planification\collecte_hebdomadaire.R"`
   - Commencer dans : `C:\Users\user\Documents\OPEScGolem_V2\opescplus`
5. Onglet *Conditions* : décochez **Ne démarrer que si l'ordinateur est
   alimenté par le secteur** si c'est un portable.

### Vérifier

Lancez la tâche à la main une première fois, par clic droit puis *Exécuter*.
Comptez trente à quarante-cinq minutes. Puis consultez le journal :

```
%APPDATA%\R\data\R\opescplus\collecte_planifiee.log
```

Il indique le nombre d'observations avant et après, la taille de la base
publiée, et la durée.

### Ce que la tâche ne fait pas

Elle ne pousse rien sur le dépôt. Publier demande une authentification, et une
machine qui publierait sans surveillance finirait par mettre en ligne une base
corrompue un jour de panne.

Le journal rappelle la commande à lancer :

```powershell
git add . ; git commit -m "Collecte du 15/09/2026" ; git push
```

Prenez l'habitude de le faire le lundi matin, après avoir jeté un œil au
journal.

## Vérifier la fraîcheur à tout moment

```r
diagnostic_fraicheur()
```

Elle donne la date de la dernière collecte, son ancienneté, et le détail par
catégorie : une catégorie peut être bien plus ancienne que la moyenne sans que
le chiffre global le montre.

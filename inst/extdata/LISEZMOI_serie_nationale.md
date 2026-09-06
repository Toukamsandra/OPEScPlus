# Série nationale de la bannière d'accueil

La bannière d'accueil affiche une série camerounaise, publiée par une
institution nationale. Elle passe avant toute source internationale : sur la
page d'accueil d'une plateforme du ministère, un chiffre camerounais doit venir
d'une institution camerounaise. L'Institut national de la statistique produit
les comptes nationaux, la Banque mondiale les reprend.

## Ce qui est livré

`serie_nationale.csv` contient le taux de croissance du PIB réel de 2010 à
2035, fourni par la division. La colonne `statut` distingue les observations
des projections.

Les projections commencent en 2026. Le graphique les trace en pointillés, sur
un fond légèrement teinté, avec la mention « Projections à partir de 2026 ». Le
repère rouge marque la dernière année observée, non le dernier point tracé :
c'est elle qui sépare le constat de la prévision.

Cette distinction n'est pas cosmétique. Une prévision affichée comme un constat
engagerait le ministère sur un chiffre qu'il n'a pas constaté.

## Mettre à jour

À la parution des comptes nationaux suivants, ajoutez une ligne à
`serie_nationale.csv` et mettez à jour le champ `source` du fichier de
métadonnées.

```
annee,valeur,statut
2010,2.93,observe
...
2025,3.50,observe
2026,3.50,projection
```

Quand une année projetée devient observée, changez son statut et corrigez sa
valeur. Mettez aussi à jour `annee_derniere_observation` dans les métadonnées.

Puis, pour que la mise à jour parte en ligne :

```r
preparer_publication()
```

et poussez sur le dépôt.

## Changer d'indicateur

Rien n'oblige à afficher la croissance. Pour montrer l'inflation, le solde
budgétaire ou tout autre série, remplacez les valeurs et ajustez le titre et
l'unité dans les métadonnées. La bannière suivra.

## Si le fichier est vide

La plateforme se rabat sur les sources internationales présentes en base, puis
sur l'illustration. Elle ne reste jamais sans rien afficher.

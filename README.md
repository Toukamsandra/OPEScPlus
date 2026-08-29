# opescplus

**OPESc+ : Observatoire des perspectives économiques**

Plateforme R Shiny de collecte, de consultation et de visualisation des
indicateurs économiques mondiaux, pour le MINEPAT. Construite avec
[golem](https://thinkr-open.github.io/golem/) : l'application est un paquet R.

232 indicateurs actifs répartis en 14 catégories, collectés auprès de la Banque
mondiale, du FMI, de l'OCDE et du Growth Lab de l'Université Harvard.

---

## 1. Installation

```r
install.packages(c("golem", "config", "shiny", "bslib", "DBI", "RSQLite",
                   "DT", "ggplot2", "plotly", "openxlsx", "httr2", "jsonlite"))
```

Puis, depuis le dossier du projet :

```r
devtools::load_all()
```

Aucun paquet hors CRAN, aucune dépendance système : ni `webshot`, ni `kaleido`,
ni `phantomjs`. L'export d'image passe par `ggsave`.

## 2. Premier chargement

```r
devtools::load_all()
preparer_base()                    # schéma, catalogue, liste des pays
collecter_en_lot(defaut = TRUE)    # les 12 indicateurs proposés d'emblée
run_app()
```

Ou en ligne de commande, une fois le paquet installé :

```bash
Rscript -e 'opescplus::preparer_base()'
Rscript -e 'opescplus::collecter_en_lot(defaut = TRUE)'
Rscript -e 'opescplus::run_app()'
```

| Périmètre | Indicateurs | Durée indicative |
|---|---|---|
| `defaut = TRUE` | 12 | environ 1 minute |
| `categorie = "C01"` (matières premières) | 29 | 3 à 5 minutes |
| `source = "Banque mondiale (WDI)"` | 156 | 15 à 25 minutes |
| tout le catalogue | 258 | 30 à 45 minutes |

`debut = 1990` divise le volume par deux. `reprendre = TRUE` saute ce qui est
déjà collecté : une interruption est sans danger, chaque indicateur est écrit
dans sa propre transaction.

## 3. Où vit la base de données

C'est le point qui change le plus par rapport à une application Shiny
classique. **Un paquet installé est en lecture seule** : la base SQLite ne peut
donc pas vivre à l'intérieur. `chemin_base()` la cherche dans cet ordre.

1. La variable d'environnement `OPESC_BASE`.
2. La clé `base` de `inst/golem-config.yml`, selon le profil actif.
3. Une base livrée dans `inst/extdata/opesc.sqlite`, si elle existe. C'est le
   cas d'un déploiement en lecture seule sur shinyapps.io, où le système de
   fichiers est éphémère et où la collecte n'aurait pas de sens.
4. À défaut, le dossier de données de l'utilisateur, que `tools::R_user_dir()`
   place correctement sur Windows, Linux et macOS.

`base_modifiable()` teste l'accès en écriture. Quand la base est en lecture
seule, les commandes de collecte ne sont pas affichées : montrer un bouton qui
échouera toujours vaut moins que ne pas le montrer.

## 4. Structure

```
DESCRIPTION               dépendances déclarées, remplace la vérification manuelle
NAMESPACE                 exports (à régénérer avec devtools::document())
R/app_config.R            app_sys() et lecture de golem-config.yml
R/app_ui.R                interface, thème, ressources statiques
R/app_server.R            connexion à la base et appel des modules
R/run_app.R               point d'entrée exporté
R/config.R                paramètres, référentiel des fréquences, palette
R/bd.R                    schéma SQLite, chemin de la base, requêtes de lecture
R/connecteurs.R           accès aux sources internationales
R/collecte.R              moteur de collecte, journal, fonctions de haut niveau
R/graphiques.R            construction des graphiques
R/exports.R               classeur xlsx et image PNG
R/mod_tableau_bord.R      onglet Tableau de bord
R/mod_base_donnees.R      onglet Base de données
R/mod_collectes.R         onglet Collectes
inst/golem-config.yml     profils default, production, dev
inst/app/www/             feuille de style, script, logos
inst/extdata/             catalogue.csv et categories.csv
inst/scripts/             enveloppes en ligne de commande
tests/testthat/           22 tests, sans accès réseau
dev/                      01_start, 02_dev, 03_deploy
```

### Travail courant

```r
devtools::load_all()      # charger le paquet
devtools::document()      # régénérer NAMESPACE et man/ après modif. roxygen
devtools::test()          # lancer les tests
devtools::check()         # contrôle complet
run_app()                 # lancer l'application

golem::add_module("fiches_pays", with_test = TRUE)
golem::add_css_file("complements")
```

**`NAMESPACE` et `man/` ont été écrits à la main**, faute de pouvoir exécuter
roxygen dans l'environnement de développement. Lancez `devtools::document()`
une première fois : c'est ce qui rendra la documentation cohérente avec les
balises `#'` déjà présentes dans le code.

### Enchaînement des filtres

Catégorie, indicateur, fréquence, période, pays. Chaque liste est construite à
partir de ce qui existe **réellement en base**, jamais de ce que la source est
censée publier. `frequences_disponibles()` interroge les observations : un pas
absent n'est jamais proposé, sans quoi le graphique serait vide sans que rien
ne l'explique. Une date de début postérieure à la date de fin est corrigée et
signalée. Pour un cours mondial de matière première, qui n'a pas de dimension
pays, le sélecteur bascule sur « Cours mondial ».

## 5. Tests

22 tests couvrent la normalisation des périodes, l'ordre des fréquences, les
contraintes du schéma, la mise en base 100 et la cohérence du catalogue. Aucun
n'accède au réseau : ils tournent en quelques secondes.

```r
devtools::test()
```

Les connecteurs ne sont pas testés : cela demanderait soit un accès réseau, soit
des réponses enregistrées avec `httptest2`, qui reste à faire.

## 6. Ce qui reste à faire

**Six sources sont au catalogue sans connecteur** : CNUCED, FAO, OIT, PNUD, OEC
et Transparency International. Leurs sept indicateurs sont désactivés au
chargement plutôt que laissés visibles et muets. Ils se réactiveront d'eux-mêmes
le jour où le connecteur sera ajouté au registre de `R/connecteurs.R`.

**Les matières premières passent par le flux WEO**, et non par PCPS. Leurs 27
codes ont été repris sur la nomenclature officielle du flux, mais ils ne sont
publiés qu'en fréquence annuelle. Le passage au mensuel demandera de brancher
le flux PCPS. `PGOLD` en fait partie : l'or n'existe pas dans le WEO.

**Six flux du FMI ne sont pas encore branchés** : `IFS`, `CPI`, `FSIC`, `IMTS`,
`GFS_SOO` et `PCPS`. Leur ordre de dimensions n'a pas été vérifié, et le deviner
mène droit à une erreur 501. Pour en brancher un :

```r
explorer_flux_fmi()          # catalogue complet des flux
explorer_flux_fmi("PCPS")    # ordre exact des dimensions de ce flux
```

Ajoutez ensuite une entrée dans `REGISTRE`, dans `R/connecteurs.R`. Tant qu'un
flux est absent du registre, ses indicateurs sont désactivés au chargement.

**Le connecteur OCDE n'a jamais été validé** non plus.

## 7. Les fréquences fines n'existent pas encore

Le schéma prévoit sept pas, de l'intrajournalier à l'annuel. Il faut être clair
sur ce qui existe : **les sources retenues ne publient que de l'annuel, du
trimestriel et du mensuel.** Ce n'est pas une limite de la plateforme mais la
nature de ces données : un PIB trimestriel n'a pas de valeur quotidienne. Les
pas fins n'ont de sens que pour les données de marché, qui viennent d'autres
fournisseurs, souvent payants.

Le filtre ne proposera donc jamais ces pas tant qu'aucune observation de ce
niveau n'existera en base. Le jour où une source quotidienne sera branchée, elle
apparaîtra sans qu'une ligne d'interface soit à modifier.

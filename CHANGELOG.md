# Journal des versions

## OPEScGolem_V17 (août 2026)

**`impossible de trouver la fonction "ns"`**

Le module Accueil n'avait jamais récupéré `ns` de sa session, contrairement aux
trois autres. Mon formulaire l'utilisait : le rendu échouait dès l'ouverture.

**La cause de fond des textes non traduits**

Vos deux exemples avaient perdu leur `tr()`. C'est la quatrième fois, et j'ai
enfin compris pourquoi : mes remplacements de bloc ciblaient la forme échappée
`\u00e9` alors que le fichier contenait des accents littéraux, ou l'inverse.
Quand le motif ne correspond à rien, le remplacement ne fait rien, **sans
erreur**. Le `tr()` disparaissait donc à l'occasion d'une réécriture voisine.

J'ai écrit un détecteur qui repère les littéraux accentués situés hors de toute
portée `tr()`. Un texte portant des accents est presque toujours destiné à
l'utilisateur : les requêtes SQL, les classes de style et les adresses n'en
comportent pas. Le détecteur a trouvé 36 textes oubliés, tous enveloppés.

Ce détecteur devient un test. Il échouera désormais dès qu'un texte visible
perdra sa traduction, au lieu de laisser la régression passer.

Un second test vérifie que tout module appelant `ns()` l'a bien défini.

**Ce qui est exclu du contrôle, et pourquoi**

Les messages de `i18n.R`, `connecteurs.R`, `collecte.R` et `bd.R` vont à la
console et non à l'écran. Les constantes de `config.R` et les listes de
`mod_accueil.R` sont évaluées au chargement du paquet, avant même que `tr()`
n'existe : les envelopper là provoquerait une erreur au démarrage. Leurs textes
passent par le dictionnaire au moment du rendu, et `chaines_accueil()` les
énumère pour un test dédié.

La constante `PRESENTATION`, devenue inutile depuis que le bloc a migré vers
l'onglet Accueil, est supprimée.

Dictionnaire : 458 entrées.

## OPEScGolem_V16 (août 2026)

**Le téléchargement du manuel : quatrième mécanisme, et le bon**

Trois tentatives ont échoué avant celle-ci, toutes pour la même raison de fond,
que je n'avais pas vue : chacune dépendait d'une liaison établie par Shiny ou
par Bootstrap dans le navigateur.

| Mécanisme | Cause de l'échec |
|---|---|
| `downloadButton` en pied de fenêtre modale | jamais relié côté client |
| `sendCustomMessage` | gestionnaire enregistré depuis `opesc.js`, chargé avant le script de Shiny |
| `modalDialog` | thème Bootstrap 5 attaché à la barre d'onglets et non à la page, balisage incompatible |

Le formulaire s'affiche maintenant **dans la page**, replié sous les boutons de
la bannière. Langue et format en boutons radio, « Valider » est un lien vers un
fichier statique. Ni fenêtre modale, ni JavaScript, ni liaison Shiny : rien qui
puisse ne pas être branché.

**Traduction : les textes venus des listes**

Le point que je n'avais pas traité. Les descriptions des six cartes de
fonctionnalités, celles des liens et le sous-titre de la plateforme ne sont pas
des littéraux `tr("...")` dans le code : ils viennent des structures
`FONCTIONS`, `LIENS` et `CONFIG`. Mon contrôle de complétude, fondé sur une
expression régulière, ne les voyait pas, et ils restaient donc en français dans
l'interface anglaise.

S'y ajoutait une faute d'accents : le sous-titre était écrit « Observatoire des
perspectives economiques », sans accent, et ne correspondait à aucune clé du
dictionnaire.

Ces textes sont désormais écrits d'un seul tenant plutôt que composés par
`paste`, ce qui les rend lisibles. Une fonction `chaines_accueil()` les
énumère, et un test vérifie qu'aucune n'échappe au dictionnaire.

Dictionnaire : 429 entrées. Les seules chaînes non traduites sont les noms
propres d'institutions, qui ne se traduisent pas.

**Contrôle**

`verifier_manuels()` liste les quatre fichiers, leur présence et leur taille.

## OPEScGolem_V14 (août 2026)

**Manuel refait selon la charte d'OPESc 4.2**

Le manuel adopte la présentation du document que vous m'avez transmis :
page de garde, table des matières, liste des tableaux, résumé exécutif avec
principes numérotés, chapitres, encadrés sur fond clair à filet doré, annexes
lettrées, glossaire et références.

Il compte trente pages en français et vingt-neuf en anglais, exactement la
limite que vous aviez fixée. Onze chapitres couvrent la présentation générale,
la prise en main, chacun des quatre onglets, la méthodologie, les limites, un
mode opératoire rapide et une foire aux questions. Quatre annexes suivent : le
catalogue des 233 indicateurs, le référentiel des fréquences, le glossaire et
les références.

Dix-huit tableaux sont numérotés et repris dans la liste des tableaux. Onze
encadrés signalent les points sur lesquels un usage inattentif conduirait à une
lecture fausse : le camembert qui additionne des pourcentages, la base 100
imposée, les cascades qui suivent le premier indicateur, ce que les projections
ne sont pas.

**Le téléchargement du manuel**

Un formulaire demande la langue et le format, et le bouton « Valider » lance le
téléchargement. Le déclenchement passe par un message envoyé au navigateur, qui
va chercher un fichier statique : un bouton de téléchargement Shiny placé dans
une fenêtre modale n'était pas relié côté client, ce qui explique que le clic
restait sans effet.

**Message d'accueil**

Il n'était traduit que sur ses deux premiers mots. Titre et corps passent
maintenant par le dictionnaire.

Le dictionnaire compte 411 entrées. Le test de complétude reconnaît désormais
les deux formes employées dans le code, `tr("...")` et `tr(paste(...))` : il
ignorait la seconde et laissait donc passer les textes longs.

## OPEScGolem_V13 (août 2026)

**Lecture du classeur des cours mondiaux**

Le fichier se téléchargeait bien, mais aucun des 28 codes n'était trouvé. Deux
erreurs, toutes deux dans ma lecture du classeur.

La ligne d'en-tête était déduite d'un décalage fixe par rapport à la première
ligne de données. Le classeur ne respecte pas ce décalage, et il n'est pas le
même d'une feuille à l'autre. On parcourt désormais les trente premières lignes
de chaque feuille et on retient celle qui contient le plus de codes recherchés.
Le fichier peut donc gagner ou perdre une ligne de titre sans rien casser.

Surtout, je ne lisais que la première feuille dont le nom contient « month ».
Or le classeur sépare les cours et les indices en deux feuilles : les cinq
indices de prix ne pouvaient pas être trouvés, quoi qu'il arrive. Toutes les
feuilles mensuelles sont maintenant parcourues et leurs séries fusionnées.

L'algorithme a été vérifié sur un classeur reproduisant la structure du Pink
Sheet, avec deux feuilles aux décalages d'en-tête différents : les cinq séries
sont retrouvées avec leur unité et leur plage de périodes.

**Diagnostic**

`inspecter_classeur_produits()` affiche, feuille par feuille, les douze
premières lignes telles qu'elles sont lues. Si la collecte échoue encore, cette
sortie montre exactement où se trouvent les codes.

`codes_produits_de_base()` liste les séries reconnues avec leur unité et leur
nombre d'observations.

Et quand aucune série n'est reconnue, le message d'erreur indique désormais
combien de codes ont été trouvés sur chaque feuille, plutôt que de renvoyer à
une fonction sans rien dire de ce qui a été vu.

## OPEScGolem_V12 (août 2026)

**Traduction complète**

Le dictionnaire passe de 96 à 405 entrées. Il couvre désormais les libellés qui
venaient de la base et que je n'avais pas traités : les 14 catégories, les 233
indicateurs actifs, les unités, ainsi que tous les messages d'état, notes,
en-têtes de tableaux et descriptions de l'accueil.

Les libellés issus de la base sont traduits à l'affichage, pas en base : la
langue est un fait d'interface, pas de donnée.

Un test parcourt le code, relève chaque chaîne passée à `tr()` et vérifie
qu'elle figure au dictionnaire. Il échouera dès qu'un libellé sera ajouté sans
sa traduction, ce qui évite que la couverture se dégrade en silence.

**Le téléchargement du manuel ne faisait rien**

Le bouton de téléchargement était placé dans le pied d'une fenêtre modale.
Shiny ne le reliait pas côté client : le clic ne produisait aucun effet et
aucun message. Le téléchargement passe maintenant par un lien statique vers un
fichier livré dans `inst/app/www/manuel`, sans aucune liaison Shiny. Le lien
s'ajuste au fur et à mesure des choix de langue et de format.

**Les fréquences**

Elles sont toutes annuelles parce que rien d'autre n'a encore été collecté :
la Banque mondiale, qui fournit 156 des 233 indicateurs actifs, ne publie que
de l'annuel. Seules les matières premières sont mensuelles, et leur collecte
n'aboutit pas encore. Le filtre fonctionne, il n'a simplement rien d'autre à
proposer.

`diagnostic_frequences()` affiche les fréquences réellement présentes en base,
celles annoncées par le catalogue, et rappelle cette explication.

**Tests** : 58 au total, dont cinq sur la complétude de la traduction et la
présence des manuels.

## OPEScGolem_V11 (août 2026)

**La traduction ne fonctionnait pas du tout**

Une seule ligne en cause. Le dictionnaire est un vecteur nommé, et sur un
vecteur atomique `d[["clé absente"]]` lève « indice hors limites » au lieu de
rendre `NULL` comme le ferait une liste. La première chaîne hors dictionnaire
faisait donc échouer la construction de toute l'interface. Et comme la fonction
sort avant d'y arriver en français, seul l'anglais tombait : d'où l'impression
que rien ne changeait, doublée du message d'erreur.

La recherche passe maintenant par `match()`, qui est vectorisé et rend `NA`
pour une clé absente. Un test vérifie explicitement ce cas.

**La langue côté serveur**

L'interface lit la langue dans la requête, mais le serveur produit aussi des
libellés après coup : notifications, en-têtes de tableaux, messages d'état. Un
observateur la lit désormais à l'ouverture de session.

Limite assumée : la langue est portée par une variable du paquet, donc partagée
entre sessions. Deux utilisateurs simultanés ayant choisi des langues
différentes verraient l'un des deux basculer. Acceptable pour un usage interne à
quelques agents ; au-delà il faudrait porter la langue dans chaque module.

**Plusieurs indicateurs d'un coup**

Le sélecteur d'indicateur accepte maintenant une sélection multiple, jusqu'à
six. « Appliquer le filtre » les trace tous. « Ajouter au graphique » reste
disponible pour empiler des sélections faites dans des catégories différentes.

Les cascades qui suivent, fréquence, période et pays, se calent sur le premier
indicateur choisi. Les combiner sur plusieurs indicateurs produirait des
intersections souvent vides : mieux vaut un réglage lisible, quitte à ce qu'une
série secondaire soit tronquée.

**Camembert**

Quatrième type de représentation. Deux précautions.

Un camembert représente une répartition à un instant, pas une évolution : seule
la dernière période affichée est retenue, et son année figure en titre. Les
valeurs nulles ou négatives sont écartées, un secteur négatif n'ayant pas de
sens.

Surtout, un camembert additionne les valeurs. Sur des pourcentages du produit
intérieur brut, des indices ou des rangs, ce total ne veut rien dire. La
plateforme le trace quand même, parce que vous pouvez avoir une raison de le
vouloir, mais elle affiche un avertissement.

La mise en base 100 est désactivée pour ce type, où elle rendrait tous les
secteurs égaux.

**Tests** : 53 au total, dont cinq sur le camembert et un sur la clé absente du
dictionnaire.

## OPEScGolem_V10 (août 2026)

**Sélecteur de langue**

Les deux liens sont remplacés par une liste déroulante sur fond blanc, qui se
lit comme un champ de saisie et non comme du texte du bandeau. Le choix
recharge la page avec le paramètre `lang`, ce qui reste le seul moyen de
traduire l'intégralité de l'interface.

**Manuel d'utilisation**

Un bouton sur l'accueil, après « Consulter la base ». Il ouvre une fenêtre qui
demande la langue et le format avant de lancer le téléchargement.

Le manuel fait 14 pages, sous la limite de 30 que vous aviez fixée. Il présente
la plateforme, détaille les quatre onglets, expose les méthodes de projection
et les précautions de lecture, puis recense les 233 indicateurs actifs par
catégorie, avec code de collecte, source et unité.

Quatre fichiers sont livrés avec le paquet : français et anglais, en PDF et en
Word. Ils sont générés hors de l'application plutôt que composés à la volée :
produire un PDF depuis R aurait imposé une chaîne LaTeX complète en dépendance
système, pour un document qui ne change qu'avec le catalogue.

La langue du manuel est demandée et non déduite de l'interface : un agent qui
consulte la plateforme en français peut avoir besoin de la version anglaise
pour un partenaire.

**Libellés anglais des indicateurs**

Les 233 indicateurs actifs ont désormais leur désignation anglaise, reprise des
noms sous lesquels les fournisseurs les publient plutôt que traduite du
français. Elle sert au manuel anglais et pourra alimenter l'interface.

**Tests** : 48 au total, dont trois qui vérifient la présence des quatre
manuels avant toute mise en service.

## OPEScGolem_V9 (août 2026)

**Deux fonctions supprimées par accident**

`explorer_flux_fmi()` et `explorer_champs_atlas()` avaient disparu : mon
remplacement de bloc à la version précédente avait emporté le code situé entre
les deux repères. C'est ce que signalait l'avertissement « Objects listed as
exports, but not present in namespace ». Restaurées.

**Les cours mondiaux changent de fournisseur**

Quatre tentatives auront été nécessaires, et il faut être clair sur ce qui a
échoué :

| Voie | Résultat |
|---|---|
| Flux WEO du FMI | accepte les codes, ne renvoie aucune observation |
| Flux PCPS en SDMX | ignore le format CSV et les bornes temporelles |
| Classeur du FMI | 403 Forbidden |
| Pink Sheet de la Banque mondiale | fonctionne |

Le 403 mérite une explication, parce que j'avais mal conclu deux fois. Le
serveur `www.imf.org` filtre les requêtes automatisées quel que soit l'en-tête
envoyé. Ce n'était donc ni le `User-Agent`, comme je l'avais cru à la version 2,
ni seulement l'adresse, comme je l'avais cru à la version 4. Tout ce qui passe
par `www.imf.org` est bloqué ; `api.imf.org`, lui, répond.

La source retenue est le Pink Sheet, qui publie les mêmes cours mensuels depuis
1960 dans un classeur unique. Son serveur ne filtre pas, et l'API de la Banque
mondiale fonctionne déjà pour le reste du catalogue.

Avantage inattendu pour un usage camerounais : le Pink Sheet cote les **grumes
et les sciages du Cameroun**, là où le FMI ne donnait qu'un cours de référence
asiatique. Et il publie l'**or**, absent du WEO.

L'adresse du classeur comporte un identifiant de document qui change à chaque
parution mensuelle : elle est donc trouvée en lisant la page de présentation,
et non codée en dur.

**Les unités viennent désormais de la source**

Les deux nomenclatures n'expriment pas les mêmes cours dans les mêmes unités :
le cacao est en dollars par tonne chez le FMI, par kilogramme dans le Pink
Sheet. Plutôt que de les recopier à la main et de me tromper, le connecteur lit
la ligne d'unités du classeur et met à jour l'indicateur. Une unité fausse sur
un axe est pire qu'une unité absente.

**Fréquence mensuelle**

Chaque cours est collecté en mensuel et doublé d'une moyenne annuelle, faute de
quoi il n'aurait aucune fréquence commune avec les indicateurs annuels de la
Banque mondiale et ne pourrait pas être superposé.

**Tests** : 45 au total, dont cinq qui vérifient que chaque cours du catalogue
a bien une correspondance avant toute collecte.

## OPEScGolem_V8 (août 2026)

**Les matières premières passent enfin, et en mensuel**

Trois voies avaient échoué : le flux WEO accepte les codes dans sa nomenclature
mais ne renvoie aucune observation ; le flux PCPS ignore le format CSV comme
les bornes temporelles et impose huit méga-octets de JSON imbriqué à chaque
requête.

La page que vous m'avez indiquée donne la solution. Le FMI y publie un classeur
mis à jour chaque mois, qui contient les mêmes séries sous forme directement
lisible. Un fichier, un téléchargement, aucune structure à reconcilier.

La lecture est volontairement tolérante : la ligne d'en-tête est repérée comme
celle qui porte le plus de codes du système, et la colonne des dates comme
celle dont les valeurs ressemblent à une période. Le FMI peut donc ajouter une
ligne ou renommer une colonne sans casser la collecte.

Les cours sont désormais **mensuels**, ce qui répond à la deuxième remarque :
la fréquence n'était annuelle que parce que la Banque mondiale ne publie que de
l'annuel et que rien d'autre n'était collecté. Chaque cours est en outre agrégé
en moyennes annuelles, faute de quoi il n'aurait aucune fréquence commune avec
les indicateurs de la Banque mondiale et ne pourrait pas être comparé.

`codes_produits_de_base()` liste ce que contient le classeur et signale les
codes du catalogue qui n'y figurent pas.

**Le clic sur la carte ne renvoyait rien**

`event_data()` lit un identifiant global, non préfixé par l'espace de noms du
module. Dans un module Shiny, la valeur n'arrivait jamais et le panneau restait
sur son invite. Le clic passe maintenant par un gestionnaire explicite, dont
l'identifiant est construit avec `ns()`.

**Français et anglais**

Un sélecteur dans le bandeau. Le mécanisme est délibérément simple : la langue
est portée par le paramètre `lang` de l'adresse et changer de langue recharge la
page. C'est ce qui permet de traduire toute l'interface, y compris les libellés
construits au démarrage, sans transformer chaque élément en sortie réactive.

Le dictionnaire est dans `inst/extdata/traductions.csv`, deux colonnes, le
français faisant office de clé. Ajouter une traduction se fait en ajoutant une
ligne. Une chaîne absente revient telle quelle : mieux vaut un mot français
dans une interface anglaise qu'une case vide.

La couverture est partielle et assumée : 86 entrées couvrent la navigation, les
filtres, les boutons, les en-têtes et l'accueil. Les libellés des 232
indicateurs et des 14 catégories restent en français, leur traduction relevant
d'un travail terminologique qui vous appartient.

**Tests** : 40 au total, dont sept sur le bilinguisme et l'agrégation annuelle.

## OPEScGolem_V7 (août 2026)

**Onglet Accueil**

Le bloc de présentation, qui tenait mal sa place entre le bandeau et les
onglets, devient un onglet à part entière, placé en premier. Il contient une
bannière avec illustration, les chiffres réels de la base, six cartes
détaillant les fonctionnalités, et deux séries de liens : les institutions
(MINEPAT, OPESc, INS Cameroun) et les sources de données, chacune avec le
nombre d'indicateurs qu'elle alimente.

Les adresses sont regroupées dans `LIENS`, en un seul endroit, parce que les
fournisseurs réorganisent leurs portails : le FMI l'a fait deux fois en un an.

Les deux boutons de la bannière basculent d'onglet plutôt que de dupliquer la
navigation.

**Illustration**

Une composition vectorielle construite pour la plateforme, plutôt qu'une
photographie. Je n'ai pas de banque d'images à ma disposition, et une photo
libre de droits mal choisie sur un site ministériel se remarque. Le fichier
`inst/app/www/illustration.svg` se remplace par une vraie photographie si vous
en avez une, sans toucher au code.

**Message de bienvenue**

Une notification en bas à droite, qui s'efface au bout de onze secondes ou au
clic. Volontairement pas une fenêtre modale : un dialogue à fermer à chaque
connexion devient une corvée pour qui ouvre la plateforme plusieurs fois par
jour.

**Bandeau**

Figé en haut de page. Drapeaux centrés sous leur titre, ramenés de 14 à 11
pixels de haut, noms en blanc.

**Fiche pays au clic sur la carte**

Un clic ouvre un panneau latéral : drapeau, langue officielle, région, groupe
de revenu, valeur de l'indicateur et rang mondial. Les codes à deux lettres et
les langues de 216 pays sont dans `inst/extdata/pays_extra.csv`, maintenu à la
main et corrigeable sans toucher au code. Un pays absent de la table rend des
champs vides plutôt qu'une erreur : un clic ne doit jamais casser la carte.

**Tests** : 33 au total, dont six nouveaux sur les compléments pays et les
icônes.

## OPEScGolem_V6 (août 2026)

**Le graphique restait bloqué à deux séries**

Même cause que l'erreur des tuiles, sous une autre forme. Les jetons de retrait
étaient des `actionLink` reconstruits à chaque changement : ajouter une
troisième série régénérait la liste, ce qui remettait à zéro le compteur de
clics de chaque lien, ce que Shiny interprète comme un nouveau clic. Les séries
précédentes étaient donc retirées aussitôt. Le clic passe maintenant par
`Shiny.setInputValue` en mode événement, qui ne se déclenche que sur une action
réelle. Les six séries annoncées sont désormais atteignables.

**Bandeau**

La devise nationale est retirée : elle figure déjà sur les armoiries, où elle
est lisible. À sa place, une bande discrète présente les dix principaux
partenaires commerciaux avec leur drapeau. Les rangs 1 à 5 et 8 reprennent le
classement des clients du Cameroun publié par l'INS pour 2024 (Pays-Bas 19,2 %,
Chine 16,5 %, Inde 10,1 %, Italie 6,4 %, France 5,7 %, Tchad 4,3 %) ; les
autres sont les principaux fournisseurs, dont le rang exact n'a pas été
vérifié. La liste se modifie dans `PARTENAIRES`, au même endroit que le reste
de la configuration.

Les drapeaux viennent de flagcdn.com, ce qui évite de distribuer trente
fichiers avec le paquet. Hors connexion, l'image se masque et le nom du pays
reste affiché.

**Présentation**

Un bloc entre le bandeau et les onglets : titre, chapô et quatre points sur ce
que la plateforme contient et sait faire.

**Analyse cartographique**

Une carte du monde sous le graphique, pilotée par le même filtre. Elle suit le
premier indicateur affiché : superposer plusieurs indicateurs sur un même aplat
de couleur n'aurait pas de sens, les unités n'étant pas comparables. Un curseur
d'année, avec lecture animée, parcourt les années réellement renseignées. Les
pays de votre sélection sont soulignés. Le classement complet s'exporte en
tableur.

Deux précautions. Les agrégats sont exclus, faute de quoi le monde et la zone
euro écraseraient l'échelle. Et celle-ci est bornée aux centiles 2 et 98 : une
poignée de valeurs extrêmes donnerait à tous les autres pays la même teinte.
L'infobulle affiche toujours la valeur réelle.

La carte est construite avec plotly, qui reconnaît nativement les codes ISO à
trois lettres et porte sa propre géométrie du monde. Passer par `sf` aurait
ajouté deux dépendances lourdes et un fichier de formes à distribuer, pour un
résultat équivalent.

**Tests** : 27 au total, dont cinq nouveaux sur le module cartographique.

## OPEScGolem_V5 (août 2026)

Le connecteur PCPS bloquait sans rien afficher. Un diagnostic direct sur le
portail du FMI a montré trois choses que je supposais à tort.

**Le portail ignore `format=csv`** et répond en SDMX-JSON. Mon connecteur, lui,
réclamait du SDMX-CSV par en-tête `Accept` : cette combinaison fait échouer la
requête sans qu'aucune erreur ne remonte, d'où le blocage silencieux. La
réponse JSON par défaut, elle, arrive en une dizaine de secondes.

**Le portail ignore aussi `startPeriod` et `endPeriod`.** Une requête d'une
seule année rapatriait déjà tout l'historique, soit environ huit méga-octets.
C'est pourquoi `debut = 2000` ne changeait rien. Les bornes ne sont plus
transmises et le filtrage temporel se fait après réception.

**Lecture du SDMX-JSON.** Ce format remplace les codes de dimension par des
indices positionnels : une série s'appelle `0:2:1:0` et ses observations sont
indexées de la même façon. Une fonction reconcilie ces indices avec les listes
de codes du bloc `structures`. L'algorithme a été vérifié sur un extrait fidèle
de la réponse réelle, y compris le cas des observations non contiguës.

**Unités multiples.** PCPS publie le même produit sous plusieurs unités : le
prix en dollars et l'indice base 100. Les mélanger fabriquerait une série où un
cours à 3 500 dollars la tonne côtoie un indice à 112. Le connecteur ne retient
que l'unité qui couvre le plus de périodes.

**Délai d'attente** porté de 90 à 600 secondes. À 90 secondes, un
téléchargement en masse échouait après trois tentatives, soit quatre minutes et
demie sans le moindre message.

## OPEScGolem_V4 (août 2026)

Corrections issues de la première collecte complète : 1 434 871 observations en
base, et quatre défauts identifiés grâce aux traces d'exécution.

**L'erreur des tuiles était ailleurs que je ne le pensais**

La trace d'appel désignait `validateCssUnit` à l'intérieur de
`shiny::actionButton`. La signature est
`actionButton(inputId, label, icon, width, ...)` : mes deux `span`, passés en
arguments positionnels après un `label` nommé, étaient captés par `icon` puis
par `width`. Shiny appelait donc `validateCssUnit()` sur une balise HTML, qui
est une liste de longueur 3, d'où le message. Les `span` sont maintenant
passés dans `label`.

Ma correction précédente, sur l'extraction des scalaires, était donc à côté du
sujet. Elle reste en place parce qu'elle rend le code plus sûr, mais ce n'était
pas la cause.

**Les matières premières renvoyaient zéro ligne sans erreur**

Elles figurent bien dans la nomenclature du flux WEO, mais celui-ci ne contient
aucune de leurs observations. La collecte se terminait donc sur un succès
apparent avec zéro valeur ajoutée, ce qui est pire qu'une erreur.

Elles reviennent au flux PCPS, dont l'ordre des dimensions n'est pas documenté.
Plutôt que de le deviner, le connecteur télécharge le flux entier une seule
fois par session et filtre en R sur la colonne qui porte le code, quel que soit
son nom. Les vingt-sept indicateurs ne représentent ainsi qu'une seule requête,
et la fréquence mensuelle redevient disponible.

**Atlas de Harvard**

`eci` et `coi` fonctionnent. Les cinq autres noms de champs, déduits de la
convention de nommage, ont été refusés avec un HTTP 400 : ils sont retirés.
`pci` et `country_product_year` ne sont pas des champs de `countryYear` : le
premier décrit un produit, le second un couple pays-produit, tous deux hors du
schéma actuel. La fonction `explorer_champs_atlas()` interroge le schéma et
donne la liste exacte pour les rebrancher.

**OCDE**

Tous ses flux renvoient 404 : l'agence supposée n'est pas la bonne, et un des
codes du catalogue était malformé, avec deux identifiants séparés par une barre
oblique. La source sort du registre. Ses six indicateurs sont désactivés.

**Bilan**

232 indicateurs actifs sur 263. Les 31 restants sont désactivés pour une raison
nommée, et non laissés visibles et muets dans l'interface.

## OPEScGolem_V3 (août 2026)

Correction de l'erreur des tuiles et refonte de l'en-tête.

**`'length = 3' in coercion to 'logical(1)'`**

Le bloc des catégories extrayait ses valeurs par `categories[i, ]$code`, qui
renvoie selon les cas un scalaire ou un vecteur. Le `if` qui suivait échouait
alors, avec un message qui ne nommait pas la ligne fautive. Chaque valeur est
maintenant extraite explicitement par `[[i]]` et convertie dans son type, et la
comparaison passe par `isTRUE()`. Cette classe d'erreur ne peut plus se
produire.

**En-tête**

Le titre est centré et les logos collés aux extrémités, par une grille de trois
colonnes de largeur égale. L'espaceur unique de la version précédente ne
pouvait pas centrer le titre, puisque les deux logos n'ont pas la même largeur.
Vérifié au pixel : écart nul entre le centre du bandeau et celui du titre.

**L'état de collecte devient visible**

C'était la vraie cause du « toutes les données ne sont pas disponibles ».
Rien ne distinguait un indicateur collecté d'un indicateur qui ne l'était pas :
en sélectionner un donnait un cadre vide qui ressemblait à une panne.

- Chaque tuile indique combien de ses indicateurs sont collectés, et signale en
  orange les catégories entièrement vides.
- Dans la liste, les indicateurs collectés viennent en tête et les autres
  portent la mention « non collecté ».
- La plateforme s'ouvre sur une catégorie qui contient des données.
- Le champ Période distingue deux cas qui appelaient des remèdes différents :
  l'indicateur n'a jamais été collecté, ou il l'a été mais pas à ce pas.

**Barre de filtres**

Passage d'un flottement à une grille nommée. Les étiquettes des cinq champs
s'alignent sur une même ligne de base et les boutons ne se décalent plus quand
un champ passe sur deux lignes. Trois dispositions selon la largeur de l'écran.

## OPEScGolem_V2 (août 2026)

Correction de la collecte auprès du FMI, après la première exécution réelle.

**Le point d'entrée du FMI avait changé, et je visais les anciens**

Trois adresses ont été essayées avant de trouver la bonne :

| Adresse | Réponse | Statut |
|---|---|---|
| `dataservices.imf.org` | — | retirée le 5 novembre 2025 |
| `sdmxcentral.imf.org/sdmx/v2` | 501 Not Implemented | ne sert que les structures, pas les données |
| `www.imf.org/external/datamapper/api/v1` | 403 Forbidden | bloquée depuis l'extérieur, quel que soit l'en-tête |
| `api.imf.org/external/sdmx/3.0` | 200 | interface SDMX 3.0 publique, sans clé |

Les 501 sur PCPS et les 403 sur le DataMapper venaient donc de la même cause.
Le 403 en particulier ne se résolvait pas par un en-tête `User-Agent` de
navigateur : le blocage ne portait pas sur l'agent.

**Le flux WEO couvre deux besoins à la fois**

En parcourant la nomenclature du nouveau portail, il apparaît que le flux WEO
contient à la fois les agrégats de finances publiques (`GGXWDG_NGDP`,
`GGXCNL_NGDP`, `GGXONLB_NGDP`, `GGR_NGDP`) et les cours des matières premières
(`PCOCO`, `POILBRE`, `PALUM`, `PCOFFOTM`). Les trois anciennes entrées FMI du
registre convergent donc vers un connecteur unique.

**Codes de matières premières corrigés**

Cinq indices de prix portaient un code inexact : dans le WEO ils prennent un
suffixe `W` (`PALLFNFW` et non `PALLFNF`). Les unités ont été reprises sur la
nomenclature officielle : le coton, le café, le sucre et le caoutchouc sont
cotés en cents par livre et non en dollars par kilogramme.

`PGOLD` et `PCPS` sont retirés du catalogue : ils n'existent pas dans le WEO et
relèvent du flux PCPS, non encore branché. Un indicateur qui ne peut pas
fonctionner n'a pas sa place dans les listes.

La fréquence des matières premières passe de mensuelle à annuelle, le WEO ne
publiant qu'en annuel. Annoncer du mensuel produirait un filtre qui ne renvoie
jamais rien.

**SDMX-CSV plutôt que SDMX-JSON**

La réponse JSON du portail est un empilement de listes où les codes de
dimension sont remplacés par des indices positionnels à reconcilier avec les
structures. Le CSV donne un tableau plat et supprime tout ce remontage.

**Cours mondiaux**

Le WEO renvoie les prix de matières premières sous un code géographique. Ils
sont rangés sous `WLD` et dédoublonnés par période, sans quoi la clé primaire
serait violée.

**Flux du FMI encore non validés**

`IFS`, `CPI`, `FSIC`, `IMTS`, `GFS_SOO` et `PCPS` sortent du registre : leur
ordre de dimensions n'a pas été vérifié, et le deviner mène droit à une erreur.
Leurs 11 indicateurs sont désactivés au chargement. La nouvelle fonction
`explorer_flux_fmi()` interroge la structure d'un flux et affiche l'ordre exact
de ses dimensions, ce qui permet de les brancher un par un.

245 indicateurs actifs sur 263.

## OPEScGolem_V1 (août 2026)

Conversion de l'application Shiny en paquet R avec golem. Le découpage en
modules existait déjà : l'essentiel du travail a porté sur l'enveloppe.

**Structure de paquet**

- `DESCRIPTION` déclare les dépendances, à la place de la vérification manuelle
  qui vivait dans `global.R`. `global.R` disparaît : l'ordre de chargement, que
  la numérotation des fichiers imposait, est remplacé par l'espace de noms.
- `NAMESPACE` et `man/` sont écrits à la main, faute de pouvoir exécuter roxygen
  ici. Un `devtools::document()` les régénérera à partir des balises `#'` déjà
  présentes.
- Les modules suivent la convention golem : `mod_<nom>_ui` et
  `mod_<nom>_server`, un fichier par module.
- `inst/golem-config.yml` avec trois profils : default, production, dev.
- `dev/01_start.R`, `02_dev.R`, `03_deploy.R`.

**Emplacement de la base**

Un paquet installé est en lecture seule : la base SQLite ne peut pas y vivre.
`chemin_base()` la résout par `OPESC_BASE`, puis la configuration golem, puis
une base livrée dans `inst/extdata`, puis `tools::R_user_dir()`.
`base_modifiable()` teste l'accès en écriture et les commandes de collecte
disparaissent quand il manque, plutôt que d'échouer à chaque clic.

**Ressources statiques**

`www/` devient `inst/app/www/`, déclaré par `golem::add_resource_path()`. Les
références passent de `opesc.css` à `www/opesc.css`.

**Logique sortie des scripts**

`collecter_en_lot()` et `preparer_base()` sont désormais des fonctions
exportées. Les scripts de `inst/scripts/` n'en sont plus que des façades, ce qui
les rend appelables depuis cron, depuis une console R et depuis les tests.

**Tests**

22 tests, absents jusqu'ici, sur la normalisation des périodes, l'ordre des
fréquences, les contraintes du schéma, la mise en base 100 et la cohérence du
catalogue. Aucun n'accède au réseau.

**Un défaut trouvé au passage**

Dans le module Collectes, `updateSelectInput()` s'exécutait avant que le
`renderUI` n'ait créé le champ : la liste des portées serait restée vide. Les
choix sont maintenant posés directement dans le `selectInput`.

# Journal des versions

## OPEScGolem_V65 (septembre 2026)

**La liste des pays est rangée en trois groupes**

Le monde, puis les régions et regroupements, puis les pays. Chaque groupe est
classé par ordre alphabétique, et porte un intitulé dans la liste déroulante.

Une liste plate mêlait une quarantaine de regroupements aux deux cents pays, et
il fallait connaître le nom anglais d'une région pour la trouver.

**Quarante-neuf regroupements traduits**

La table de traduction couvre désormais tous les agrégats publiés par la Banque
mondiale : les régions géographiques, les groupes de revenu, les
classifications institutionnelles et celles des Nations unies.

**Une limite que je dois signaler**

Les communautés économiques régionales africaines, CEMAC, CEDEAO, UEMOA, SADC,
n'apparaissent pas dans cette liste. La Banque mondiale ne les publie pas comme
agrégats, et la plateforme ne les calcule pas.

Les calculer serait possible, mais hasardeux : agréger des pays n'a de sens que
pour certaines grandeurs. Additionner des produits intérieurs bruts se
justifie ; additionner des taux de croissance ou des indices de Gini n'a aucun
sens, et une moyenne non pondérée en aurait encore moins. Produire ces
agrégats demanderait de définir, indicateur par indicateur, la règle
d'agrégation applicable.

Si ces communautés vous sont nécessaires, deux voies. Les importer depuis une
source qui les publie, la BEAC ou la Commission de la CEMAC, par le dépôt de
fichier de l'onglet Collectes. Ou me demander d'implémenter l'agrégation, en
sachant qu'elle ne sera proposée que sur les grandeurs additives.

## OPEScGolem_V64 (septembre 2026)

**Le monde en tête de la liste des pays**

L'agrégat mondial existait déjà en base, mais deux choses le rendaient
introuvable.

Il portait le nom publié par la Banque mondiale, « World », alors qu'un
utilisateur francophone cherche « Monde ». Et il se rangeait par ordre
alphabétique au milieu d'une quarantaine de regroupements.

Il vient maintenant en premier, devant les pays, suivis des autres agrégats.
Sa valeur est celle qu'on cherche le plus souvent d'abord.

**Les noms d'agrégats sont traduits**

Une table dédiée, de l'anglais vers le français. Le dictionnaire ordinaire ne
pouvait pas servir : il va du français vers l'anglais, et ces noms sont déjà
dans la langue d'arrivée.

Trente-six agrégats couverts : zones géographiques, groupes de revenu,
classifications des Nations unies. Un nom absent est rendu tel quel, mieux
valant un nom anglais qu'un blanc.

Les noms de pays ne sont pas traduits : ils sont pour l'essentiel identiques ou
reconnaissables, et en traduire deux cents introduirait des erreurs pour un
gain faible.

## OPEScGolem_V60 (septembre 2026)

**Les définitions s'affichaient en anglais en mode français**

La Banque mondiale ne publie ses définitions qu'en anglais, et elles étaient
enregistrées puis affichées telles quelles. Un lecteur francophone recevait
donc de l'anglais sans que rien ne le signale.

Trois corrections.

**La langue est enregistrée avec chaque définition.** Une colonne s'ajoute à la
table, et les bases antérieures la reçoivent automatiquement.

**Le glossaire français passe avant la définition du fournisseur.** Quand la
notion y figure, c'est sa définition qui s'affiche, dans la langue de
l'interface, avec le manuel de référence pour source.

**À défaut, le texte du fournisseur reste affiché, avec la mention « texte
publié en anglais par la source ».** Ce n'est pas satisfaisant, mais une
définition en anglais renseigne davantage qu'un blanc, pourvu que le lecteur
sache qu'elle est en anglais.

**Le rattachement au glossaire a été refait**

Un libellé d'indicateur ne reprend presque jamais le nom canonique d'une
notion : « Taux de croissance du PIB réel » ne contient ni « croissance
économique » ni « produit intérieur brut ».

Vingt-neuf notions reçoivent désormais des variantes de libellé, et les
variantes sont éprouvées de la plus longue à la plus courte pour que la plus
spécifique l'emporte. Sans cet ordre, « PIB réel » rattachait la croissance à
la notion de produit intérieur brut.

Le seuil a été durci en sens inverse : deux mots partagés au moins, dès lors
que la notion en compte deux. Un seul suffisait, et « prix » rattachait « PIB
par habitant, prix courants » à l'indice des prix à la consommation. Une
définition fausse est pire qu'une définition absente.

Résultat mesuré : 31 % des indicateurs trouvent une définition française, sans
rattachement erroné sur les cas contrôlés. Les autres gardent la définition du
fournisseur, sa langue étant signalée.

## OPEScGolem_V59 (septembre 2026)

**Manuels actualisés, version 2.1**

Les quatre fichiers reflètent l'état actuel : **313 indicateurs, 14
catégories**, contre 341 et 15 auparavant.

Le chapitre sur les matières premières a été refait. Il opposait deux
catégories dont l'une n'existe plus : la présentation porte désormais sur la
seule catégorie subsistante, et explique pourquoi la précédente a été
supprimée, à savoir qu'elle faisait double emploi et que sa voie
d'alimentation automatique n'a jamais abouti.

Deux sections nouvelles. « La définition et sa source », qui expose d'où
viennent les définitions affichées et pourquoi leur origine est toujours
nommée. Et « Ce qui s'affiche au chargement », qui décrit la sélection tracée
d'emblée dans le tableau de bord et la base de données.

**Trois défauts de composition corrigés**

Les noms d'usage restaient en anglais, faute du paquet de francisation : le
manuel français affichait « Chapter ». Ils sont redéfinis à la main.

Les sous-titres étaient émis comme sous-sections sans section au-dessus, ce qui
donnait une numérotation en 7.0.1 au lieu de 7.1. Ils passent au niveau
section, et leur espacement a été resserré pour compenser les deux pages
gagnées.

Les fichiers auxiliaires de LaTeX n'étaient pas effacés entre deux
compositions : le sommaire gardait l'ancienne numérotation alors que le corps
portait la nouvelle.

**Trente pages** dans les deux langues, la limite tenue.

## OPEScGolem_V58 (septembre 2026)

**La carte « Projections » quitte l'accueil**

Six cartes au lieu de sept dans le bloc « Ce que la plateforme permet ».

La fonction elle-même reste dans le tableau de bord : seule sa présentation en
page d'accueil disparaît. Mettre en avant un prolongement statistique à côté de
la collecte et de la cartographie lui donnait un poids qu'il n'a pas, et
risquait de le faire prendre pour une prévision institutionnelle.

## OPEScGolem_V57 (septembre 2026)

**Le graphique quitte la page d'accueil**

L'espace de droite de la bannière reste vide. Le texte garde sa largeur de
lecture plutôt que de s'étirer sur toute la bannière : une ligne trop longue se
lit mal.

Le module `R/graphique_accueil.R` et la série nationale restent dans le projet,
dormants. Ils ne sont plus appelés, mais rien n'est supprimé : les données que
vous avez fournies, la distinction entre observations et projections et
l'interactivité sont conservées. Une ligne suffit à les rallumer, remplacer
`shiny::div(class = "hero-image")` par
`shiny::div(class = "hero-image", banniere_graphique())`.

**Marche à suivre du téléchargement**

L'étape sur la fréquence indiquait un choix ouvert. Elle recommande désormais
« Tous », et précise que la plateforme sépare ensuite les pas annuel,
trimestriel et mensuel. Télécharger une seule fréquence obligerait à refaire
l'opération pour obtenir les autres.

## OPEScGolem_V56 (septembre 2026)

**Série complète, observations et projections distinguées**

La bannière affiche désormais le taux de croissance du PIB réel de 2010 à 2035,
tel que fourni par la division.

Les dix dernières valeurs sont des projections. Elles sont tracées en
pointillés, sur un fond légèrement teinté, avec la mention « Projections à
partir de 2026 ». Le repère rouge marque la dernière année observée, non le
dernier point tracé : c'est elle qui sépare le constat de la prévision.

Cette distinction n'est pas cosmétique. Une prévision affichée comme un constat
engagerait le ministère sur un chiffre qu'il n'a pas constaté, et la page
d'accueil d'une plateforme officielle est le dernier endroit où se permettre
cette confusion.

**Deux défauts de tracé corrigés.** Les libellés d'années se chevauchaient aux
extrémités : la dernière année remplace maintenant le repère précédent s'il en
est trop proche. Et la construction des abscisses avait disparu lors d'un
remplacement de bloc, ce qui aurait fait échouer le rendu.

**Mise à jour.** Quand une année projetée devient observée, changez son statut
dans `serie_nationale.csv` et corrigez sa valeur. Le mode d'emploi qui
accompagne le fichier le détaille.

## OPEScGolem_V54 (septembre 2026)

**Le graphique d'accueil vient d'une source camerounaise**

Sur la page d'accueil d'une plateforme du ministère, un chiffre camerounais
doit venir d'une institution camerounaise. L'Institut national de la
statistique produit les comptes nationaux, la Banque mondiale les reprend :
citer la seconde quand la première est disponible était un contresens.

La série affichée est le taux de croissance du PIB réel de 2019 à 2024, relevé
dans le **tableau 3 des Comptes nationaux de 2024**, publiés par l'INS en août
2025, série en volumes chaînés de référence 2016.

**Vérifiez ces chiffres avant une diffusion officielle.** Ils ont été relevés
dans le document publié, mais une relecture par un statisticien de la division
vaut mieux qu'une confiance aveugle.

**Pourquoi un fichier et non un connecteur.** Aucune institution camerounaise
ne publie d'interface interrogeable par programme : la donnée se trouve dans
des rapports et des tableurs. La saisir une fois par an est plus sûr que de
moissonner une page qui changera.

Le fichier est `inst/extdata/serie_nationale.csv`, accompagné de ses
métadonnées et d'un mode d'emploi. Une ligne à ajouter à chaque parution, et
rien d'autre. Changer d'indicateur, pour montrer l'inflation ou le solde
budgétaire, demande seulement de remplacer les valeurs et d'ajuster le titre.

Si le fichier est vide, la plateforme se rabat sur les sources internationales
présentes en base, puis sur l'illustration. Elle ne reste jamais sans rien
afficher.

**Tracé adapté aux séries courtes.** Six points appellent des repères plus
marqués et toutes les années en abscisse ; vingt points appellent l'inverse.

## OPEScGolem_V52 (septembre 2026)

**Le graphique paraît avec la page**

Il passait par plotly, ce qui suppose de charger la bibliothèque graphique puis
de faire un aller-retour avec le serveur. Pendant ce temps la bannière restait
vide, et c'est ce délai que vous constatiez.

Il est désormais assemblé pendant la construction de la page, en SVG. Il arrive
avec le reste du document et s'affiche du premier coup, sans attente.

Son apparence reprend celle des graphiques du tableau de bord : fond clair,
grille horizontale légère, courbe bleue avec ses points, titre en gras, unité
sous le titre. Les graduations sont des valeurs rondes plutôt que des
intervalles calculés, un axe qui affiche 2,7 et 5,4 se lisant moins bien qu'un
axe qui affiche 0, 2, 4.

**Adaptation aux petits écrans, seconde passe**

La barre d'onglets n'avait aucune règle : ses cinq entrées se repliaient sur
trois lignes ou dépassaient de la fenêtre. Elle défile maintenant
horizontalement, comme dans les applications qui en comptent beaucoup.

Le document ne défile plus jamais horizontalement dans son ensemble : les
éléments qui débordent le font à l'intérieur de leur propre cadre. C'est la
règle qui évite qu'un tableau ou une barre d'onglets ne décale toute la page.

Les sorties graphiques suivent la largeur qu'on leur laisse. Sans cette règle,
plotly conservait la largeur calculée au premier rendu et débordait après une
rotation de l'écran.

**Vérifié** à 320, 390, 768 et 1280 pixels : aucun débordement horizontal.

## OPEScGolem_V51 (septembre 2026)

**GoogleOPESc+ ne répondait plus**

Une condition posée sur une source absente. `nzchar(NULL)` rend un vecteur
vide, et `if` sur un vecteur vide lève une erreur : l'affichage de toute la
recherche s'interrompait pour une définition sans attribution.

Deux corrections, car une seule laissait le défaut possible. La source est
désormais toujours une chaîne, avec le glossaire de la plateforme comme repli
nommé. Et la condition tolère une valeur absente.

Un test vérifie qu'aucune définition ne sort sans source.

**Adaptation aux petits écrans**

Les règles s'arrêtaient à un seuil unique : un téléphone recevait encore des
grilles à deux colonnes et une carte de quatre cent soixante pixels de haut,
qui masquait tout le reste.

Trois seuils désormais, correspondant à trois usages. À 1100 pixels, la carte
perd sa hauteur fixe et les grilles passent à deux colonnes. À 820, tout passe
en une colonne et les chiffres clés se rangent par deux. À 560, un chiffre par
ligne, les cadres occupent toute la largeur, la carte se réduit à 260 pixels.

Les éléments interactifs gardent une cible d'au moins quarante-quatre pixels
sur écran tactile : en deçà, ils sont manqués une fois sur trois au doigt.

Les tableaux débordent horizontalement plutôt que d'écraser leurs colonnes : un
tableau illisible ne vaut pas mieux qu'un tableau qu'on fait défiler.

**Vérifié** à 390, 768 et 1280 pixels : aucun débordement horizontal.

## OPEScGolem_V49 (septembre 2026)

**Le graphique de la bannière est celui du tableau de bord**

Mon tracé maison en SVG était une illustration à part, avec sa propre écriture
et ses propres conventions. Il emprunte désormais la fonction de tracé du
tableau de bord : la bannière montre exactement ce que l'utilisateur produira,
sur fond clair comme les autres. Les commandes de manipulation sont retirées,
une bannière se regarde et ne se manipule pas.

**Une sélection au chargement**

Le tableau de bord ouvrait sur un cadre gris, et la base de données sur un
tableau vide. Ni l'un ni l'autre n'apprenait quoi que ce soit, et un tableau
vide laissait même croire que la base l'était aussi.

Le tableau de bord trace au chargement la croissance du produit intérieur brut
par habitant pour le Cameroun, en annuel. La catégorie retenue est celle qui
porte cet indicateur, non une catégorie quelconque. La base de données ouvre
sur les indicateurs du secteur réel. Les deux se remplacent au premier filtre
appliqué.

**Le journal des collectes passe en dernier**

Il rend compte de ce qui a été fait, alors que l'import et la suppression sont
ce qu'on vient faire. L'ordre précédent obligeait à faire défiler un tableau
pour atteindre les commandes.

**Les définitions citent leur manuel**

« Glossaire OPESc+ » n'apprenait rien et laissait croire à une définition
maison. Les quarante-quatre notions reprennent en réalité des textes de
référence, qui sont désormais nommés : le Système de comptabilité nationale
pour le produit intérieur brut, le Manuel de la balance des paiements pour le
compte courant, les résolutions de la Conférence internationale des
statisticiens du travail pour le chômage.

Une définition doit renvoyer à une autorité, sans quoi elle ne vaut rien dans
une note.

## OPEScGolem_V48 (septembre 2026)

**Le graphique était invisible**

Tracé en blanc, il était dessiné sur le fond blanc de la bannière. Il lui
fallait un cadre : il repose désormais sur un aplat dégradé de bleu, avec sa
légende et sa source en dessous. C'est aussi ce qui lui donne le poids visuel
qu'il n'avait pas.

**La série est cherchée plus largement**

Quatre codes sont essayés dans l'ordre, du taux de croissance de la Banque
mondiale à celui du Fonds monétaire international, puis le déflateur. À défaut,
le produit intérieur brut en niveau, converti en milliards de dollars : mieux
vaut une série de niveau qu'une bannière sans donnée.

`diagnostic_banniere()` dit lequel des codes manque, et s'il manque au
catalogue ou seulement en données.

## OPEScGolem_V47 (septembre 2026)

**Charte reprise : bleu, blanc, rouge**

J'avais déduit les couleurs des armoiries de la République, qui sont vert, or
et rouge. C'était une déduction, pas une observation, et elle était fausse : la
charte du ministère est bleue, avec le rouge réservé aux actions.

Le bleu se décline en trois valeurs, du bandeau aux surfaces claires. Le rouge
est réservé à ce sur quoi on clique pour aller ailleurs : lien, bouton
d'action. Le réserver ainsi lui garde sa force ; l'employer comme ornement la
lui ôterait.

**Une réserve.** Le site du ministère ne publie pas sa feuille de style, et je
n'ai pas pu relever ses codes exacts. Ceux retenus sont un choix raisonné, tous
dans onze variables au même endroit : si vous disposez des codes officiels, ils
se substituent là et nulle part ailleurs.

**Un graphique à la place de l'illustration**

La bannière portait un dessin décoratif, qui ne disait rien. Elle porte
maintenant la croissance du produit intérieur brut camerounais sur vingt ans,
tirée de la base elle-même, avec sa source nommée sous la courbe. C'est une
démonstration plutôt qu'un ornement : le visiteur voit d'emblée ce que la
plateforme contient et d'où elle le tient.

Le tracé est en SVG produit côté serveur : une bannière n'a pas à être survolée
ni zoomée, et un SVG s'affiche sans attendre le chargement d'un moteur
graphique. L'échelle englobe toujours le zéro, sans quoi une année de récession
passerait pour un simple creux.

Si la série manque, l'illustration reprend sa place.

**Cartes d'accueil repliées**

Sept cartes déployées faisaient un mur de texte que l'œil ne parcourt pas. Seul
le titre et l'onglet concerné restent visibles ; le détail se déplie d'un clic.

**Source sur toute définition**

Celle du glossaire portait son texte sans dire d'où il venait. Toute définition
affichée porte désormais sa source, sans exception : l'utilisateur doit pouvoir
dire d'où vient ce qu'il recopie dans une note.

**Performance**

Je n'ai pas su reproduire la lenteur que vous décrivez : sur une base d'essai
de six cent mille lignes, une requête filtrée revient en un dixième de
milliseconde, avec ou sans index.

J'ai donc appliqué ce dont l'effet est certain sans prétendre avoir trouvé la
cause : index sur les tables de correspondance de la base publiée, statistiques
de planification calculées à la publication, et tables temporaires gardées en
mémoire.

Dites-moi ce qui est lent précisément, et si c'est en ligne ou en local : la
réponse oriente entièrement le diagnostic.

## OPEScGolem_V46 (septembre 2026)

**Charte graphique alignée sur l'identité du ministère**

La charte précédente, bleu marine et doré, n'appartenait à personne : elle
pouvait aussi bien habiller une banque qu'un cabinet de conseil. Rien n'y
situait la plateforme.

Les couleurs ont été relevées sur les armoiries de la République telles
qu'elles figurent déjà dans le bandeau : vert `#007854`, or `#FCCC0C`, rouge
`#CC0C24`. Ce sont les couleurs nationales, celles qu'emploient les sites du
gouvernement.

| Élément | Avant | Après |
|---|---|---|
| Couleur principale | bleu marine `#1F3864` | vert `#00694A` |
| Accent | doré `#C8A24A` | or `#F0B90B` |
| Alerte | rouge `#B4232A` | rouge `#C0392B` |
| Fonds clairs | teintés de bleu | teintés de vert |

Le changement porte partout, non seulement à l'écran : la palette des
graphiques, le dégradé de la carte, l'illustration de la bannière et les
en-têtes des classeurs exportés. Une charte qui s'arrête à l'interface n'en est
pas une.

**Palette des graphiques repensée.** Les trois premières couleurs sont celles
des armoiries, ce qui donne à un graphique de deux ou trois séries une
identité immédiate. Les suivantes s'en distinguent autant par leur clarté que
par leur teinte, pour rester lisibles par un daltonien.

**Carte à teinte unique.** Un dégradé du vert pâle au vert soutenu remplace le
dégradé bicolore : la valeur croît avec l'intensité, ce qu'une échelle à deux
teintes ne dit pas.

**Un contraste corrigé.** Le doré de la charte sur fond vert soutenu descend à
3,7 contre 1, sous le seuil de lisibilité. Une variante éclaircie lui est
réservée pour ces fonds : même teinte, clarté différente. Les neuf autres
associations contrôlées dépassent toutes le seuil.

## OPEScGolem_V45 (septembre 2026)

**La recherche échouait en ligne**

`preparer_publication()` recopiait quatre tables et oubliait celle des
définitions. En ligne, l'interface interrogeait donc une table absente, et la
recherche s'interrompait sur une erreur.

Deux corrections, car une seule n'aurait pas suffi.

La table des définitions voyage désormais avec les autres. C'est la cause.

Et `lire_definition()` rend `NULL` plutôt que d'échouer quand la table manque.
C'est la protection : une définition est un complément, jamais une condition
d'affichage. Interrompre une recherche entière faute d'une définition serait
hors de proportion, et le cas se reproduira avec une base antérieure à cette
version.

`verifier_publication()` compte désormais les définitions embarquées et
signale leur absence avant l'envoi.

## OPEScGolem_V44 (septembre 2026)

**La base publiée éclipsait la base de travail**

Erreur introduite avec `preparer_publication()`. Dès que la base compacte était
écrite dans `inst/extdata`, `chemin_base()` la préférait à la base locale :
vous travailliez donc sur la version publiée, où `observation` est une vue et
non une table.

D'où les deux erreurs constatées. `views may not be indexed`, parce que le
schéma tentait d'indexer une vue. Puis `no such table: definition`, parce que
le schéma s'était interrompu avant de créer cette table.

La base de travail passe désormais avant celle livrée avec le paquet. Sur le
serveur, le dossier de données de l'utilisateur n'existe pas : la base livrée
est alors la seule, et elle est retenue. Le déploiement fonctionne donc comme
prévu, sans que la publication perturbe le travail local.

`chemin_base()` indique laquelle est en usage.

**Le schéma tolère une base publiée**

SQLite refuse d'indexer une vue. La création des index est désormais
conditionnée à la présence d'une vraie table. Le schéma s'applique donc aux
deux formes de base sans échouer, ce qui importe puisqu'il crée aussi la table
des définitions.

## OPEScGolem_V43 (septembre 2026)

**Une définition et sa source pour chaque indicateur**

Les définitions sont récupérées auprès du fournisseur de chaque série, et non
rédigées dans le projet. Deux raisons.

La première tient à l'autorité. Dans un document administratif, une définition
sans source ne vaut rien : celle de la Banque mondiale pour le produit
intérieur brut engage la Banque mondiale, une définition anonyme n'engage
personne. La source est donc affichée sous chaque définition.

La seconde tient à l'exactitude. Trois cents définitions rédigées à la main
comporteraient des approximations, et une approximation sur une définition
d'indicateur se propage dans toutes les notes qui l'emploient.

La Banque mondiale publie, pour chaque indicateur, un texte de définition et
le nom de l'organisme qui en répond. Les deux champs sont repris tels quels.
Pour les séries d'autres fournisseurs, le glossaire de la plateforme sert de
recours, avec la mention explicite « Glossaire OPESc+ » : l'utilisateur doit
savoir que la définition vient d'ici et non de l'institution qui publie la
série.

`collecter_definitions()` lance la récupération, `diagnostic_definitions()`
montre où en est la couverture, catégorie par catégorie.

**Marche à suivre du téléchargement complétée**

Quatre étapes s'ajoutent, entre le choix de la période et la validation :
le déroulé des autres bases disponibles par la flèche devant « Ensemble de
données », dont l'indice des prix à la production ; la restriction aux pays et
indicateurs voulus ; la transformation des données ; et le choix de la
fréquence.

## OPEScGolem_V41 (septembre 2026)

**Préparation à la mise en ligne**

L'hébergement visé est Posit Connect Cloud, qui déploie depuis un dépôt GitHub
public et redéploie tout seul à chaque envoi. Deux obstacles se posaient, l'un
mesurable, l'autre de principe.

**La taille.** La base de travail pèse plus de deux cents méga-octets, alors
que GitHub refuse un fichier au-delà de cent. Les codes d'indicateur et de pays
y sont répétés en toutes lettres sur chaque ligne, soit cent cinquante octets
par observation, dont l'essentiel est de la redondance.

`preparer_publication()` les remplace par des entiers renvoyant à deux tables
de correspondance. Mesuré : trente-quatre octets par ligne au lieu de cent
cinquante, soit environ cinquante méga-octets pour un million et demi
d'observations. Une vue rend l'opération transparente au reste du code, qui
continue d'interroger `observation` sans savoir comment elle est rangée.

Si la base reste trop lourde, l'argument `annee_min` limite la profondeur
historique. C'est un dernier recours, la compaction devant suffire.

**Le dépôt est public.** Aucune clé ne doit y figurer. Un `.gitignore` écarte
`.Renviron`, et `verifier_publication()` contrôle avant l'envoi que rien de
confidentiel ne partira. Les clés du moteur de recherche se déclarent dans la
console de l'hébergeur.

**app.R à la racine**, point d'entrée attendu par l'hébergeur. Il charge le
paquet depuis les sources plutôt que de l'installer : `opescplus` n'est publié
sur aucun dépôt de paquets. Les appels à `library()` qu'il contient ne servent
pas au fonctionnement, le code étant préfixé par les espaces de noms ; ils
servent à `writeManifest()`, qui établit la liste des paquets à installer en
lisant ce fichier.

**Lecture seule assumée.** Le système de fichiers du serveur n'accepte pas
l'écriture. L'onglet Collectes n'y montre plus que le journal, avec une phrase
qui l'explique. Afficher un formulaire d'import qui échouerait toujours vaut
moins que ne pas l'afficher.

**Chapitre 10 du README** : préparation, premier déploiement, mise à jour.

## OPEScGolem_V40 (septembre 2026)

**La marche à suivre tient sur une ligne**

Déployée en permanence, elle mesurait cinq cents pixels et repoussait les
catégories sous la ligne de flottaison, alors qu'elle ne sert qu'au premier
usage. Elle tient maintenant en cinquante-six pixels : l'avertissement, le
bouton de téléchargement et un lien qui déploie les deux séries d'étapes à la
demande.

Rien n'est perdu : le détail reste accessible d'un clic, en deux colonnes
numérotées.

**Le nombre d'indicateurs est lu en base**

Il était écrit dans le texte du formulaire de téléchargement du manuel, et
donc faux dès le retrait de la catégorie C01. Il est désormais compté à
l'affichage, comme le nombre de catégories. Un chiffre figé dans une phrase
devient faux sans que rien ne le signale.

Le catalogue compte 313 indicateurs actifs répartis en 14 catégories.

**Bornes de période inversées**

Dans l'onglet Base de données, un résultat vide affichait le message générique
sur une base peut-être vide. C'est la cause la plus fréquente et la plus facile
à corriger qui manquait : le message précise maintenant que l'année de début
est postérieure à celle de fin, en rappelant les deux valeurs saisies.

## OPEScGolem_V39 (septembre 2026)

**Deux erreurs d'import, deux causes distinctes**

`objet 'remplacer' introuvable` venait d'un bloc redondant. L'effacement en
mode remplacement a lieu une fois, pour toute la catégorie, avant la lecture du
fichier. Un second bloc le refaisait série par série en invoquant une variable
`remplacer` qui n'existe pas : l'argument de ces fonctions s'appelle `mode`. Le
bloc est retiré, il faisait double emploi.

`near "o": syntax error` venait d'un alias de table dans un `DELETE`. SQLite
l'accepte dans un `SELECT`, pas dans un `DELETE`. La même condition sert
maintenant au comptage et à l'effacement, sans alias, ce qui garantit en outre
qu'ils portent sur les mêmes lignes.

C'est cette seconde erreur qui empêchait aussi la suppression.

**Un fichier vestige retiré**

`R/import_fichier.R` datait d'une version antérieure et n'était appelé nulle
part. Trois fonctions mortes de moins.

**La catégorie C01 est supprimée**

Elle faisait doublon avec C15 : les mêmes cours, en moins nombreux, alimentés
par une voie qui n'a jamais abouti. Vingt-huit indicateurs retirés du
catalogue. Il reste quatorze catégories et 344 indicateurs.

**Marche à suivre dans le tableau de bord**

Un encadré précède le cadre des catégories. Il explique que la base des cours
doit être téléchargée puis importée, donne le lien vers la page du Fonds
monétaire international, et détaille les deux séries d'étapes : cinq pour le
téléchargement, quatre pour l'import.

Cette marche à suivre a sa place dans l'interface et non dans un manuel : elle
concerne des agents qui découvrent la plateforme, et personne n'ouvre un manuel
avant d'avoir essayé.

**Base des cours remplacée** par celle que vous avez fournie : 1 268 séries,
247 périodes de 2012 à juillet 2026, 122 produits.

## OPEScGolem_V37 (septembre 2026)

**Collecte de rattrapage**

`collecter_manquants()` passe en revue les indicateurs actifs sans observation
et tente de les alimenter. Pour les cours de produits de base, le connecteur
essaie successivement le paquet `imf.data`, des requêtes ciblées, le flux
entier du Fonds monétaire international, puis le classeur Pink Sheet de la
Banque mondiale. Si tout échoue, le fichier livré avec la plateforme prend le
relais.

Quatre voies pour une même donnée, ce qui est beaucoup. Aucune n'a tenu seule.

Les indicateurs sans connecteur ne sont pas tentés : ce serait remplir le
journal d'échecs prévisibles. Ils sont recensés en fin d'exécution, groupés par
fournisseur manquant, avec le nombre d'indicateurs concernés.

L'exécution se termine par l'état du catalogue, catégorie par catégorie.

**Manuels refaits selon la charte d'OPESc 4.2**

Le manuel adopte la présentation exacte du document de référence, avec un
contenu propre à la plateforme.

| Élément | Reprise |
|---|---|
| Police | serif, corps de texte justifié |
| Page de garde | marque, titre, sous-titre, version, puis service, ministère, date, sans en-tête ni numéro |
| En-tête courant | titre à gauche, DAPE / MINEPAT à droite, filet fin |
| Pied de page | numéro seul, centré |
| Chapitres | mention « Chapitre N » au-dessus du titre |
| Sections | numérotées 1.1, 1.2, remises à zéro à chaque chapitre |
| Tableaux | légende « Table N.M. » sous le tableau |
| Encadrés | filet fin sur fond très clair, titre en gras |

Les aplats de couleur et les filets dorés de la version précédente sont
abandonnés : le document de référence est sobre, en noir et gris.

La page de garde forme une section distincte, sans en-tête ni numéro, comme
dans la référence.

## OPEScGolem_V35 (septembre 2026)

**La page semblait se mettre en veille**

Deux mécanismes distincts produisaient cette impression, et tous deux
appartiennent à Shiny.

**L'atténuation pendant le recalcul.** Shiny abaisse l'opacité d'une sortie à
un tiers pendant qu'elle se recalcule. Sur un graphique ou une carte, qui
occupent la moitié de l'écran, l'effet se lit comme un assombrissement de toute
la page. L'atténuation est retirée : le contenu reste lisible, et un liseré
défilant en haut de la zone signale le travail en cours. L'information demeure,
sans que la page paraisse s'éteindre.

**Le voile de déconnexion.** Quand la liaison avec le serveur se coupe, Shiny
pose un voile gris et attend un rechargement manuel. Deux causes se combinent :
le navigateur ralentit les minuteries d'un onglet laissé au second plan, et les
serveurs intermédiaires ferment les connexions restées silencieuses.

Un battement toutes les vingt-cinq secondes empêche la connexion de s'endormir.
La reprise de session est autorisée côté serveur. Et si la coupure survient
malgré tout, la page se recharge d'elle-même après quatre secondes, sous un
bandeau « Reconnexion en cours » qui suit la langue de l'interface.

L'écouteur est posé sur le document et non sur l'objet Shiny : le script est
chargé avant celui de Shiny, et tester son existence à cet instant reviendrait
à ne rien enregistrer. C'est l'erreur qui avait déjà coûté deux versions au
téléchargement du manuel.

## OPEScGolem_V34 (septembre 2026)

**Table des matières composée, avec ses numéros de page**

Elle était confiée au champ automatique de Word, qui reste vide tant que le
document n'est pas ouvert et actualisé dans Word. Résultat : une table blanche
dans le PDF et pour quiconque lit sans Word.

Elle est désormais composée ligne à ligne. Les numéros de page proviennent
d'une première passe : le document est généré, converti, puis chaque titre est
localisé dans le PDF avant la composition définitive. Une seconde mesure
confirme que la pagination n'a pas bougé entre les deux passes.

Les entrées sont repérées par leur rang et non par leur intitulé. Deux
sous-titres peuvent porter le même nom, « Projections » figure au chapitre du
tableau de bord comme à celui de la méthodologie, et une table indexée par le
titre leur donnait la même page.

Soixante-trois entrées, chapitres et sous-titres, toutes paginées.

**Tirets cadratins retirés**

Ils servaient d'incise dans le texte, de séparateur dans les légendes de
tableau et le pied de page, et d'unité absente dans le catalogue. Remplacés par
une ponctuation ordinaire : virgule, deux points, barre verticale, et la
mention « non précisée » là où l'unité manque. Vérifié dans tout le projet,
code et fichiers de données compris.

**GoogleOPESc+ sur la page d'accueil**

Le bloc « Ce que la plateforme permet » l'omettait, alors que c'est un onglet
entier. Une septième carte le présente, avec sa propre icône.

**Manuels** : trente et une pages, la table des matières en ayant pris une.

## OPEScGolem_V33 (septembre 2026)

**Manuels remis à jour, version 2.0**

Les quatre fichiers, français et anglais en PDF et en Word, reflètent l'état
actuel de la plateforme.

**Deux chapitres nouveaux.** « GoogleOPESc+, la recherche orientée » expose le
principe des sources fermées, les propositions de saisie, le classement en six
sources et les trois états de configuration. « Importer une base externe »
traite du fichier livré, du dépôt depuis l'interface, et de ce qui distingue
les catégories C01 et C15.

**Le catalogue passe de 233 à 341 indicateurs**, quinze catégories au lieu de
quatorze. La liste des fournisseurs distingue désormais les trois interfaces
interrogeables du fichier livré avec la plateforme.

**Trente pages, la limite tenue.** Le catalogue ayant grossi de moitié, la mise
en page a été resserrée plutôt que le contenu amputé : marges réduites,
tableaux du catalogue densifiés, colonne « source » reportée en note sous
chaque tableau puisqu'elle répétait la même valeur sur des dizaines de lignes,
et catalogue de plus de cinquante entrées présenté sur deux colonnes de paires.
Les annexes brèves s'enchaînent sans saut de page.

**Rendu vérifié** sur le résumé exécutif, le chapitre des collectes et la
double colonne de la catégorie C15.

## OPEScGolem_V30 (août 2026)

**Le filtre manquait, et c'était le principal**

Afficher les trente-cinq sources à chaque recherche revenait à ne pas filtrer
du tout. Seules celles qui traitent réellement du sujet sont désormais
retenues, **six au maximum**. À défaut de rattachement thématique, quatre
sources généralistes plutôt que la liste entière.

Mesuré sur cinq requêtes : « dette publique » retient 6 sources sur 35,
« complexité économique » en retient 3, « chômage » 5. Chacune est en tête pour
une raison lisible.

**Propositions pendant la frappe**

Une liste de complétion s'affiche sous le champ dès deux caractères saisis.
Elle puise dans le glossaire, les quinze catégories et les libellés des
indicateurs : les propositions portent donc sur ce que la plateforme sait
effectivement traiter, non sur un dictionnaire général. Un clic lance la
recherche.

**Quatre onglets**

| Onglet | Ce qu'il fait |
|---|---|
| Tout | définition de la notion, indicateurs disponibles en base, résultats web, sources |
| Images | recherche d'images sur les mêmes sources, en grille |
| Actualité | résultats limités aux sources de presse et de communiqués, restreints aux douze derniers mois et triés par date |
| Vidéos | pages de vidéo et de webcast des institutions |

Chaque onglet se traduit par des paramètres différents envoyés au moteur, non
par un simple tri de la même réponse.

**Définition des notions**

Un glossaire de 44 notions économiques est livré avec la plateforme : produit
intérieur brut, solde structurel, termes de l'échange, complexité économique.
La correspondance est souple, « PIB » retrouve « Produit intérieur brut » par
ses initiales, et « croissance » rend la notion la plus proche.

Le glossaire est maintenu dans le projet plutôt que tiré d'une encyclopédie
généraliste : la définition est ainsi vérifiable, stable dans le temps, et
formulée dans le vocabulaire des comptes nationaux. Il se complète en ajoutant
une ligne à `inst/extdata/definitions.csv`.

**Tests** : sept nouveaux, dont celui qui vérifie que le nombre de sources
proposées reste borné.

## OPEScGolem_V29 (août 2026)

**Recherche réelle sur le web, restreinte aux sources retenues**

L'onglet GoogleOPESc+ interroge désormais le web et rend de vrais résultats,
titre, adresse et extrait, et non plus seulement des liens vers les moteurs de
chaque site.

**Pourquoi passer par un service tiers.** Interroger directement un moteur de
recherche depuis un script est bloqué par tous les grands moteurs, et le peu
qui passe casse à la première refonte de page. Moissonner les sites un par un
demanderait autant d'analyseurs que de sites, chacun à refaire à chaque
changement de maquette. Aucune des deux voies ne tient dans la durée, et je
préfère le dire plutôt que de livrer quelque chose qui marchera trois semaines.

Le moteur de recherche programmable de Google résout exactement ce problème :
il permet de définir un ensemble fermé de sites et de n'y chercher que là. Les
résultats sont ceux d'un vrai moteur, l'index est restreint aux trente domaines
de la plateforme. C'est « comme Google, mais spécifique », au sens propre.

**La configuration est facultative.** Sans clé, la plateforme retombe sur les
liens de recherche par site, qui fonctionnent sans rien installer. Une note
explique comment activer la recherche directe. La mise en place est décrite au
chapitre 9 du fichier README, et `domaines_pour_moteur()` donne la liste des
domaines à déclarer.

**Un filtre conservé par prudence.** Même quand le moteur est déjà restreint
aux sites inclus, les résultats sont filtrés sur la liste des domaines avant
affichage. Une erreur de configuration ne doit pas suffire à faire entrer une
source quelconque. Les sous-domaines sont acceptés, les imitations rejetées :
`documents.worldbank.org` passe, `faux-worldbank.org` non.

**Économie des appels.** L'offre gratuite couvre cent recherches par jour. Une
même recherche relancée dans la session est servie depuis la mémoire.

## OPEScGolem_V28 (août 2026)

**Les cours de produits de base sont livrés avec la plateforme**

Je vous faisais taper des commandes pour quelque chose qui doit être
automatique. C'était mon erreur.

Le fichier des cours est désormais **distribué dans le paquet** et chargé par
`preparer_base()`, au même titre que le catalogue. Aucune commande d'import à
lancer : après l'initialisation, les 108 produits sont là, avec leurs 17 496
observations en mensuel, trimestriel et annuel.

Le chargement n'écrase rien s'il trouve déjà des données : si vous importez un
fichier plus récent, il reste en place.

**Le vocabulaire changeait de sens**

Un indicateur alimenté par import affichait « non collecté », ce qui laissait
croire à un manque alors que la donnée est là. Ces séries ne se collectent pas
et n'ont pas à l'être : leur source ne se laisse pas interroger par programme.
La mention devient « sans données », qui décrit un état plutôt qu'une tâche non
faite.

**Import depuis l'interface**

Onglet Collectes, un cadre permet de déposer un fichier et de choisir la
catégorie à alimenter. Les séries inconnues du catalogue y sont créées
automatiquement. Plus besoin de la console.

**GoogleOPESc+ présenté comme un moteur de recherche**

Les résultats formaient trois cadres séparés par type, ce qui obligeait à
parcourir la page pour trouver le meilleur. Ils forment maintenant **une liste
unique et ordonnée** : fil d'ariane avec l'organisme et le type, titre en lien,
description. Le premier résultat pertinent est mis en valeur.

Le bloc « Disponible dans la plateforme » reste en tête : si la donnée est déjà
en base, c'est la meilleure réponse possible.

Le champ de saisie est arrondi, les cases de type restent sous la barre. Le
principe qui écarte le hors-sujet n'a pas bougé : liste de sources fermée, et
chaque lien lance la recherche du terme sur le site visé.

## OPEScGolem_V27 (août 2026)

**Nouvelle catégorie : Matières premières commodityPrice**

Quinzième catégorie, qui accueille l'intégralité des séries du fichier PCPS
téléchargé, et non plus la seule sélection de 28 cours du catalogue d'origine.

**108 produits**, contre 28 auparavant : indices agrégés, métaux précieux et
métaux de la transition énergétique, terres rares, céréales, oléagineux,
viandes, produits de la mer, bois, engrais, thés par origine. Les libellés sont
traduits ; ceux que la source désigne d'un terme sans équivalent courant
gardent sa désignation, signalée comme telle plutôt qu'inventée.

**Quatorze séries écartées.** Le fichier livre avec les cours des taux de
change, reconnaissables à leur code commençant par T. Un taux de change n'est
pas une matière première : les ranger ensemble fausserait la lecture de la
catégorie. Ils restent disponibles dans la catégorie Taux de change.

**Une règle d'activation corrigée**

Un indicateur était actif si sa source figurait au registre des connecteurs.
Cette règle aurait rendu invisible toute la nouvelle catégorie : ses séries
viennent d'un import et n'ont, par construction, aucun connecteur.

Un indicateur est désormais actif s'il **peut être alimenté ou s'il l'est
déjà**. Une donnée présente est utilisable, quelle que soit la façon dont elle
est arrivée.

**L'import peut créer les indicateurs manquants**

`importer_produits_local(..., creer = TRUE)` ajoute à la catégorie les séries
présentes dans le fichier mais absentes du catalogue, en reprenant leur libellé
de la source. C'est ce qui permet d'accueillir une base externe entière sans
avoir à la décrire au préalable.

## OPEScGolem_V26 (août 2026)

**Deux indicateurs sur un même graphique : la cause enfin trouvée**

Le champ de sélection des indicateurs redevenait mono-sélection dès le premier
chargement de catégorie. En cause, une ligne de mon code :
`updateSelectizeInput()` recevait un argument `options`, ce qui réinitialise le
composant côté navigateur. Il perdait alors son caractère multiple, déclaré à
la création et non répété dans la mise à jour.

Vous ne pouviez donc littéralement pas sélectionner deux indicateurs, quelle
que soit la manœuvre. Les options ne sont plus transmises que lors de la
création du champ.

**Import ouvert à toute catégorie**

`importer_produits_local()` prend désormais un argument `categorie` et un
argument `iso3`. Elle ne sert donc plus seulement les cours mondiaux : toute
base externe dont les codes correspondent à ceux d'une catégorie peut
l'alimenter, pour un cours mondial comme pour une série nationale.

`codes_categories()` liste les catégories avec leur code, leur nombre
d'indicateurs, combien sont collectés et le volume d'observations. À consulter
avant un import.

**GoogleOPESc+ couvre maintenant trois natures de résultats**

Trente-cinq sources au lieu de vingt-six, réparties en trois types :

| Type | Sources | Exemples |
|---|---|---|
| Données | 17 | Banque mondiale, FMI, OCDE, ILOSTAT, BEAC, INS |
| Publications | 9 | Rapports article IV, Moniteur des finances publiques, MINFI |
| Actualité | 9 | Communiqués FMI et Banque mondiale, Agence Ecofin, Investir au Cameroun, Cameroon Tribune, BEAC |

Des cases à cocher filtrent par type. Le type filtre mais n'entre pas dans le
calcul de pertinence : une actualité reste rattachée à ses catégories comme une
base de données, et le classement par spécialisation continue de s'appliquer.

Le principe reste inchangé, et c'est lui qui garantit l'absence de hors-sujet :
la liste des sources est fermée, et chaque lien lance la recherche de votre
terme **sur le site visé**.

Vérifié sur quatre requêtes, dont « politique monétaire BEAC » qui renvoie à la
BEAC en données comme en actualité, et « Cameroun croissance » qui renvoie à
l'INS, au MINEPAT et à Cameroon Tribune.

## OPEScGolem_V25 (août 2026)

**Les cours importés restaient marqués « non collecté »**

Le nombre d'observations est stocké dans la table des indicateurs, pour éviter
un comptage à chaque affichage. Cette redondance dérivait : au rechargement du
catalogue, le compteur était **recopié** de l'ancienne table par correspondance
de code interne. Or cinq codes venaient de changer, et l'import manuel écrivait
pendant ce temps.

Le compteur est maintenant **recalculé** depuis les observations, qui font foi.
Une date de collecte est posée sur tout indicateur qui porte des données mais
n'en avait pas, cas exact d'un import manuel.

`rafraichir_compteurs()` fait ce recalcul à la demande. Elle est appelée à la
fin d'un import et au rechargement du catalogue.

**Ajouter au graphique**

Le message « Cette série est déjà affichée » s'affichait série par série.
Lorsque vous ajoutiez un second indicateur en gardant le premier sélectionné,
l'avertissement apparaissait pour le premier alors que le second **avait bien
été ajouté** : l'action semblait avoir échoué sans l'avoir fait.

Un seul message désormais, et seulement si rien n'a pu être ajouté. Il indique
quoi changer plutôt que de constater le doublon.

Une indication sous le champ rappelle que la sélection accepte jusqu'à six
indicateurs : le plus simple pour en tracer deux reste de les choisir ensemble
avant d'appliquer.

**L'onglet Recherche devient GoogleOPESc+**

Le nom n'est pas traduit : c'est celui de l'outil.

## OPEScGolem_V24 (août 2026)

**Le fichier téléchargé est au format large**

Une ligne par série, une colonne par période, et le nom de la colonne porte la
période elle-même : `2020`, `2020-Q1`, `2020-M01`. Ce n'est pas le format long
que produit une interface de programmation. Mon lecteur cherchait donc une
colonne de période qui n'existe pas.

Deux autres particularités, apprises en lisant votre fichier.

La colonne `INDICATOR` ne contient qu'un **libellé**, pas un code. Le code utile
est le deuxième élément de `SERIES_CODE` : `PCOCO` dans `G001.PCOCO.INDEX.Q`.

Chaque produit est publié sous **quatre transformations**, dont deux taux de
variation. Retenir la mauvaise aurait donné une série de pourcentages là où l'on
attend un cours en dollars. Le lecteur retient le niveau en dollars, puis
l'indice pour les séries qui n'existent que sous cette forme, et écarte
explicitement les variations : ce sont des grandeurs dérivées, que la plateforme
sait recalculer.

**Cinq codes du catalogue étaient faux**

Mes cinq indices de prix portaient un suffixe `W` hérité de la nomenclature du
flux WEO. Le fichier PCPS les nomme sans suffixe. `PALLFNFW` devient `PALLFNF`,
et de même pour les quatre autres.

**Vérification sur votre fichier**

L'import a été simulé sur le fichier que vous avez envoyé, avant livraison :
les **28 cours passent**, soit 4 536 observations, en trois fréquences.

| Fréquence | Observations par cours |
|---|---|
| Mensuelle | 115 |
| Trimestrielle | 38 |
| Annuelle | 9 |

La fréquence est déduite du **nom de la colonne** et non de la colonne
`FREQUENCY` : une même série occupe des colonnes annuelles, trimestrielles et
mensuelles distinctes, et seul le nom de la colonne dit ce qu'elle couvre.

C'est aussi ce qui débloque votre filtre de fréquence : la catégorie des
matières premières proposera Mensuelle, Trimestrielle et Annuelle.

**L'unité vient du fichier**

Elle est reprise de la colonne `DATA_TRANSFORMATION` plutôt que du catalogue :
la source fait foi.

## OPEScGolem_V23 (août 2026)

**Import manuel des cours de produits de base**

La page du jeu de données PCPS construit son bouton DOWNLOAD en JavaScript :
aucune adresse ne figure dans le HTML, elle ne peut donc pas être trouvée par
programme, exactement comme la page de téléchargement de l'Atlas de Harvard.

`importer_produits_local()` prend le relais. Vous téléchargez le fichier une
fois, à la main, et la plateforme l'intègre. La lecture est tolérante : les
colonnes sont repérées par leur contenu autant que par leur intitulé, ceux-ci
variant d'un export à l'autre. Un mode aperçu montre ce qui serait importé sans
rien écrire.

L'écriture en base est la même fonction que pour la collecte automatique. Une
donnée importée se comporte donc exactement comme une donnée collectée :
fréquence mensuelle, doublage en moyenne annuelle, compteurs mis à jour.

Ce n'est pas un pis-aller. Une source qui ne se laisse pas interroger
automatiquement se charge à la main, et cela vaut mieux qu'une catégorie vide
le jour d'une présentation.

**Recherche orientée**

Nouvel onglet. Ce n'est pas un moteur de recherche généraliste, c'est
l'inverse : la liste des sources est fermée et choisie, et chaque lien renvoie
vers la recherche du terme **sur le site visé**. Un résultat ne peut donc pas
être hors sujet, ni provenir d'une source dont l'autorité n'est pas établie.

Vingt-six sources : Banque mondiale, FMI, OCDE, CNUCED, OMC, BRI, OIT, FAO,
AIE, OMS, UNESCO, PNUD, Growth Lab, Transparency International, BAD, BEAC,
CEMAC, et côté camerounais l'INS, le MINEPAT, le MINFI et la Caisse autonome
d'amortissement.

La requête est d'abord confrontée au catalogue : si la donnée est déjà en base,
la réponse la plus utile est celle-là, pas un lien vers l'extérieur.

**Le classement des sources**

Trois critères, par poids décroissant : le rang de la catégorie dans la
requête, le rang de cette catégorie chez le site, et sa spécialisation.

Ce dernier critère s'est imposé à l'essai. Sans lui, une recherche sur le cacao
plaçait le portail généraliste du FMI avant la page des marchés de produits de
base de la Banque mondiale, simplement parce qu'il couvre plus de sujets. À
rang égal, un site qui traite trois domaines est plus pertinent qu'un portail
qui en couvre huit.

Les mots vides sont écartés : « des » figurait dans « indice des prix » et
rattachait à tort « chômage des jeunes » à la catégorie des prix.

Résultats vérifiés : le cacao renvoie aux marchés de produits de base, le
chômage à ILOSTAT, la complexité économique à l'Atlas de Harvard, la dette au
Moniteur des finances publiques et au MINFI.

**Tests** : sept nouveaux sur la recherche, dont un qui vérifie que chaque lien
porte bien la requête encodée, et un qui contrôle l'ordre de spécialisation.

## OPEScGolem_V22 (août 2026)

**Le paquet imf.data devient la voie principale**

`get_data()` prend des **filtres nommés** plutôt qu'une clé positionnelle. Cela
supprime d'un coup les deux obstacles qui ont provoqué cinq tentatives
infructueuses : l'ordre des dimensions et la syntaxe du joker. Le nom de la
dimension suffit, sa position n'a plus d'importance.

Le paquet est déclaré facultatif. S'il n'est pas installé, le connecteur
poursuit avec ses propres requêtes, dans cet ordre :

1. `imf.data` et ses filtres nommés ;
2. requêtes ciblées construites à la main, avec le joker `*` ;
3. téléchargement du flux entier puis filtrage, la voie dont nous savons
   qu'elle répond ;
4. classeur Pink Sheet de la Banque mondiale.

Quatre voies pour une même donnée, ce qui est beaucoup. Mais après cinq échecs
sur ce seul bloc, la redondance vaut mieux que l'élégance.

Pour l'activer : `install.packages("imf.data")`.

**Couleurs des tuiles de catégories**

Les tuiles sont des boutons Shiny, donc des éléments `.btn`. Bootstrap leur
applique ses propres couleurs sur les états `:hover`, `:focus` et `:active`, ce
qui rendait le libellé blanc sur fond clair au moment du clic.

Toutes les couleurs sont désormais fixées explicitement pour chaque état, et la
tuile retenue passe en bleu plein avec un texte blanc : le contraste ne dépend
plus d'une nuance de gris. Le compteur passe en bleu clair, et la mention d'une
catégorie non collectée en doré, lisible sur le fond sombre.

Contraste mesuré : texte blanc sur fond `#1F3864`, soit un rapport très
au-delà du seuil d'accessibilité.

## OPEScGolem_V21 (août 2026)

**La syntaxe du joker**

L'ordre des dimensions était enfin correct, mais aucune requête ne rendait rien.
Le rapprochement avec le tout premier diagnostic donne la réponse : une clé
réduite à `*` avait alors rendu huit méga-octets de données. Ce n'est donc pas
le flux qui est muet, c'est la façon dont j'écris la clé.

En SDMX 3.0, le joker d'une position s'écrit `*`. Une position laissée vide est
la syntaxe de SDMX 2.1 : ce portail la lit comme « code vide » et ne trouve
évidemment rien.

| Clé | Interprétation par le portail |
|---|---|
| `.PCOCO..` | pays vide, transformation vide, fréquence vide |
| `W00.PCOCO.*.M` | pays W00, toutes transformations, mensuel |

**Un recours dont on connaît le comportement**

Si les quatre clés ciblées échouent encore, le connecteur télécharge le flux
entier avec la clé `*`, la seule dont nous ayons la preuve qu'elle répond, et
filtre en R. Le téléchargement est fait une fois par session et sert les
vingt-huit cours.

C'est plus lourd que nécessaire, mais après cinq tentatives infructueuses, une
voie qui aboutit vaut mieux qu'une voie élégante.

**Découverte des codes**

`codes_produits_de_base()` lit désormais le flux lui-même et non sa
nomenclature, dont l'interrogation échouait. Elle liste les codes réellement
alimentés, avec leur zone géographique, leur transformation et leur nombre
d'observations. Si `PCOCO` n'y figure pas, la sortie donnera le code exact.

`tester_produit()` essaie les quatre clés puis le flux complet, et affiche dans
ce dernier cas la dimension des produits, le nombre de codes et un échantillon.

## OPEScGolem_V20 (août 2026)

**La structure réelle du flux, lue dans la réponse du portail**

Votre sortie de `tester_produit()` contenait exactement ce qui me manquait :

```
COUNTRY . INDICATOR . DATA_TRANSFORMATION . FREQUENCY   puis TIME_PERIOD
```

Ma clé `M.W00.PCOCO.` demandait donc le pays « M », l'indicateur « W00 » et la
transformation « PCOCO ». Aucune donnée ne pouvait revenir. La clé correcte est
`W00.PCOCO..M`.

Deux suppositions se sont révélées fausses d'un coup. La fréquence n'est pas en
tête de clé mais en quatrième position. Et la dimension des produits s'appelle
`INDICATOR`, pas `COMMODITY`, contrairement à ce qu'indiquent des exemples
publiés pour un autre millésime du flux. C'est précisément le genre de détail
qu'on ne devine pas.

**Le portail répond en JSON même quand on demande du CSV**

Votre sortie le montre aussi. Le connecteur lit désormais les deux formats : il
regarde le premier caractère de la réponse et bascule en conséquence.

Le lecteur JSON est rendu tolérant. Il rendait une erreur quand la réponse
était vide, parce que le portail renvoie alors une enveloppe complète dont
toutes les listes de valeurs sont vides. C'est cette erreur que vous voyiez :
`values must be length 1, but FUN(X[[1]]) result is length 0`. Il rend
maintenant « aucune donnée », ce qui est l'information utile.

**Plusieurs clés essayées**

Si `W00.PCOCO..M` ne rend rien, le connecteur essaie l'annuel, puis laisse la
dimension géographique libre. `tester_produit()` affiche les quatre essais avec
leur résultat.

**Diagnostic**

`codes_produits_de_base()` interroge la structure du flux avec ses
nomenclatures et repère celle des produits par son contenu, non par son nom,
puisque ce nom vient de changer sous mes yeux.

## OPEScGolem_V19 (août 2026)

**Trois faits établis, au lieu de trois suppositions**

La recherche sur la documentation du portail et sur des exemples publiés a
donné ce qui me manquait depuis le début.

| Point | Ce que je supposais | Ce qui est vrai |
|---|---|---|
| Dimensions de PCPS | inconnues, clé devinée | `FREQ.REF_AREA.COMMODITY.UNIT_MEASURE` |
| Zone de référence | absente ou par pays | `W00`, cours mondiaux uniquement |
| En-tête pour le CSV | `application/vnd.sdmx.data+csv;version=2.0.0` | `text/csv`, tout simplement |
| Format de période | `2018-01` | `2018-M01` |

L'en-tête explique l'échec le plus déroutant : le type long faisait échouer la
requête sans qu'aucune erreur ne remonte, ce qui m'a fait croire à un blocage
et m'a envoyée vers le JSON, puis vers le classeur Excel. `text/csv` renvoie un
tableau plat directement lisible.

**Une requête par produit**

Chaque réponse fait quelques dizaines de kilo-octets au lieu des huit
méga-octets du flux complet, et un produit absent n'empêche plus les autres
d'aboutir. Le mensuel est demandé en premier, l'annuel en secours pour les
indices publiés à un seul pas.

**Le lecteur SDMX-JSON est retiré**

Il échouait sur la dimension temporelle et n'a plus lieu d'être maintenant que
le CSV fonctionne. Deux cents lignes de reconciliation d'indices en moins.

**Diagnostic**

`tester_produit("PCOCO")` isole une seule requête, affiche l'adresse
interrogée, la taille de la réponse, ses premières lignes et ses colonnes.
C'est le premier réflexe si la collecte échoue encore.
`codes_produits_de_base()` interroge la nomenclature du flux, réponse légère,
et donne les codes exacts avec leur libellé.

## OPEScGolem_V18 (août 2026)

**Trois fautes de syntaxe que j'ai introduites**

Mon enveloppeur automatique de la version précédente a placé `tr()` sur des
**noms d'éléments nommés**, dans `c(tr("Toutes les catégories") = "", ...)`. En
R, ce qui figure à gauche d'un `=` dans un `c()` doit être un littéral ou un
nom : un appel de fonction y est une faute de syntaxe, et le paquet ne se
chargeait plus. Les trois cas sont réécrits avec `setNames`, dont le nom est
une valeur ordinaire. Un contrôle balaie désormais le code à la recherche de ce
motif.

**Les matières premières passent par le flux PCPS du FMI**

La page que vous m'avez indiquée confirme l'interface SDMX du portail. Le
diagnostic mené plus tôt montrait qu'elle répond correctement pour PCPS : code
200, huit méga-octets, une dizaine de secondes. Le seul obstacle était le
format de la réponse.

Le portail ignore le paramètre `format=csv` et répond en SDMX-JSON, qui
remplace les codes de dimension par des indices positionnels : une série
s'appelle `0:2:1:0` et ses observations sont indexées de la même façon. Une
fonction reconcilie ces indices avec les listes de codes du bloc `structures`.
L'algorithme a été vérifié sur une réponse reproduisant fidèlement la
structure observée, y compris les observations non contiguës.

Trois précautions. La dimension qui porte les produits est repérée par son
contenu et non par son nom, celui-ci ayant déjà changé d'un millésime à
l'autre. Le flux publie souvent le même produit sous plusieurs unités, prix en
dollars et indice base 100 : seule l'unité la mieux couverte est retenue, faute
de quoi un cours à 3 500 dollars la tonne côtoierait un indice à 112 dans la
même série. Et le filtrage temporel se fait après réception, le portail
ignorant les bornes transmises.

**Le classeur de la Banque mondiale devient le repli**

Les deux sources publient les mêmes cours mensuels. Si le flux du FMI échoue,
le connecteur bascule sur le Pink Sheet et le signale. Disposer d'une seconde
voie évite qu'une réorganisation de portail ne prive la plateforme de toute la
catégorie, ce qui s'est produit deux fois en un mois.

**Diagnostic**

`inspecter_flux_pcps()` affiche les dimensions du flux et un échantillon de
leurs valeurs. `codes_produits_de_base()` liste les produits réellement
disponibles, avec leur unité et leur nombre d'observations.

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

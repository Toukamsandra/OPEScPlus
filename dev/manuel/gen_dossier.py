#!/usr/bin/env python3
# Guide technique : le code et le deploiement. Meme charte que les manuels.

import subprocess
import re
from pathlib import Path

BLEU_FONCE = "12,35,87"
BLEU_LOGO = "31,77,162"
OR = "230,172,77"
GRIS_TITRE = "18,33,76"

PREAMBULE = r"""\documentclass[10pt,a4paper,openany]{report}
\usepackage[utf8]{inputenc}
\usepackage{textcomp}
\usepackage[a4paper,top=2cm,bottom=1.8cm,left=2cm,right=2cm]{geometry}
\usepackage{xcolor}
\usepackage{booktabs}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage{float}
\usepackage{fancyhdr}
\usepackage{titlesec}
\usepackage{tikz}
\usetikzlibrary{arrows.meta}
\usepackage[most]{tcolorbox}
\usepackage{enumitem}
\usepackage{hyperref}

\definecolor{bleufonce}{RGB}{@@BLEUFONCE@@}
\definecolor{bleulogo}{RGB}{@@BLEULOGO@@}
\definecolor{oropesc}{RGB}{@@OR@@}
\definecolor{gristitre}{RGB}{@@GRISTITRE@@}

\hypersetup{colorlinks=true, linkcolor=bleulogo, urlcolor=bleulogo,
            pdftitle={OPESc+ : dossier de projet}}

\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

\newtcolorbox{encadre}[1]{
  colback=black!3, colframe=black!30, boxrule=0.4pt, arc=1pt,
  left=7pt, right=7pt, top=5pt, bottom=5pt,
  title={\normalsize\bfseries\color{gristitre}#1},
  coltitle=gristitre, colbacktitle=black!3, titlerule=0pt,
  fonttitle=\bfseries, breakable, before skip=7pt, after skip=8pt}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\footnotesize OPESc+, dossier de projet}
\fancyhead[R]{\footnotesize DAPE / MINEPAT}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}

\titleformat{\chapter}[display]
  {\normalfont\bfseries}{\normalsize\mdseries\chaptertitlename\ \thechapter}
  {4pt}{\Large}
\titlespacing*{\chapter}{0pt}{6pt}{10pt}

% Les chapitres s'enchainent sans saut de page. `report` appelle \cleardoublepage
% avant chaque chapitre : le remplacer par une simple aeration suffit, et
% laisse \clearpage intact pour le reste du document.
\makeatletter
\renewcommand{\@chapapp}{\chaptername}
\def\@makechapterhead#1{%
  \vspace*{6pt}%
  {\parindent\z@ \raggedright \normalfont
   \normalsize\mdseries\@chapapp\space\thechapter\par\nobreak
   \vskip 4\p@
   \Large\bfseries #1\par\nobreak
   \vskip 10\p@}}
\renewcommand\chapter{%
  \par\addvspace{14pt}%
  \thispagestyle{fancy}%
  \global\@topnum\z@
  \@afterindentfalse
  \secdef\@chapter\@schapter}
\makeatother

\titleformat{\section}{\normalfont\large\bfseries}{\thesection}{0.7em}{}
\titlespacing*{\section}{0pt}{10pt}{4pt}

\counterwithin{section}{chapter}
\renewcommand{\thesection}{\thechapter.\arabic{section}}

\renewcommand{\chaptername}{Chapitre}
\renewcommand{\tablename}{Table}
\renewcommand{\contentsname}{Table des matières}

\setlist{itemsep=1pt, topsep=2pt, parsep=0pt}
\setlength{\parskip}{3.5pt}
\setlength{\parindent}{0pt}
\renewcommand{\arraystretch}{1.04}

\begin{document}
"""

GARDE = r"""
\thispagestyle{empty}
\begin{tikzpicture}[remember picture, overlay]
  \fill[bleufonce] (current page.north west)
    rectangle ([yshift=-0.248\paperheight]current page.north east);
  \node[fill=bleulogo, rounded corners=9pt, minimum width=2.5cm,
        minimum height=2.5cm, anchor=center]
    at ([yshift=-0.202\paperheight]current page.north)
    {\color{white}\fontsize{30}{34}\selectfont OP};
  \draw[oropesc, line width=2pt, line cap=round, line join=round,
        -{Latex[length=3.4mm, width=2.6mm]}]
    ([xshift=-1.05cm, yshift=-0.283\paperheight]current page.north)
    -- ++(0.60,0.34) -- ++(0.50,-0.26) -- ++(0.95,0.66);
\end{tikzpicture}

\vspace*{0.30\paperheight}
\begin{center}
  {\color{gristitre}\fontsize{22}{26}\selectfont\bfseries Dossier de projet\par}
  \vspace{0.6em}
  {\color{gristitre}\fontsize{18}{22}\selectfont\bfseries OPESc+\par}
  \vspace{1.0em}
  {\fontsize{13}{16}\selectfont De la commande à la mise en ligne\par}
  \vspace{1.6em}
  {\color{bleulogo}\fontsize{11}{13}\selectfont Version 2.1\par}
  \vspace{4.2em}
  {\fontsize{12}{15}\selectfont\bfseries Division des Analyses et des Politiques Économiques\par}
  \vspace{0.7em}
  {\fontsize{11}{13}\selectfont MINEPAT\par}
  \vspace{1.7em}
  {\fontsize{10}{12}\selectfont Septembre 2026\par}
\end{center}
\clearpage
"""

CORPS = r"""
\begingroup\setlength{\parskip}{0pt}
\tableofcontents
\endgroup
\clearpage

\chapter{Le besoin}

\section{La situation de départ}

Préparer une note de conjoncture à la Division des Analyses et des Politiques
Économiques suppose de rassembler des données dispersées entre les portails de
la Banque mondiale, du Fonds monétaire international et d'une dizaine d'autres
institutions. Chacun a son interface, sa nomenclature, son format d'export.

Trois conséquences. Le temps passé à collecter n'est pas passé à analyser. Deux
notes rédigées le même mois peuvent reposer sur des millésimes différents. Et
une donnée citée six mois plus tôt devient difficile à retrouver, faute de
trace de sa provenance.

\section{Ce qui était demandé}

Une plateforme de consultation des indicateurs économiques mondiaux, accessible
sans installation, alimentée automatiquement auprès des sources d'origine, et
utilisable par des agents qui ne sont pas statisticiens.

\begin{encadre}{Ce que la plateforme n'est pas}
OPESc+ est un outil de consultation et de restitution. Ce n'est pas un modèle
macroéconomique : elle ne simule aucun choc et ne produit aucune prévision
institutionnelle. Elle complète OPESc, dont elle reprend la charte, sans s'y
substituer.
\end{encadre}

\chapter{Les décisions de conception}

\section{Le portage depuis Django}

Une première version existait, écrite en Django. Elle fonctionnait, mais
l'écart entre l'outil et le besoin était grand : Django sert à bâtir des
applications à comptes utilisateurs, formulaires et écritures concurrentes.
OPESc+ est un explorateur en lecture seule. Sur les quatre grandes fonctions de
ce cadre, une et demie servaient.

Le portage en R et Shiny a été décidé pour cette raison, et parce que R est la
langue de travail des statisticiens de la division : une évolution future s'y
écrira en quelques lignes.

\section{Le catalogue avant le code}

Le premier travail n'a pas été d'écrire des fonctions, mais de dresser le
catalogue : quels indicateurs, chez quel fournisseur, sous quel code, à quelle
fréquence, avec quelle unité.

Ce fichier a précédé tout le reste, et c'est lui qui a dicté l'architecture. Un
programme qui lit un catalogue se modifie en modifiant le catalogue : ajouter
un indicateur d'un fournisseur déjà branché ne demande aucune ligne de code.

\section{Quatre étages séparés}

\begin{enumerate}
  \item Les connecteurs interrogent les interfaces publiques.
  \item Le moteur de collecte harmonise et écrit dans une base unique.
  \item L'interface lit cette base et n'y écrit jamais.
  \item Les exports produisent des fichiers autonomes portant leurs sources.
\end{enumerate}

Cette séparation a une conséquence pratique : une session de consultation ne
peut pas altérer les données, et une collecte en cours n'empêche pas la
consultation.

\section{Trois principes de traitement}

\textbf{Une valeur manquante n'est jamais un zéro.} Elle n'est pas
enregistrée, et une série lacunaire est tracée en pointillés, jamais
interpolée. Relier deux points distants de plusieurs années par un trait plein
suggérerait une évolution qui n'a pas été observée.

\textbf{Les agrégats sont écartés des classements et des cartes.} Sans cela, le
monde et la zone euro occuperaient systématiquement les premières places et
écraseraient l'échelle de couleur.

\textbf{Chaque collecte est journalisée.} Une collecte peut se terminer sans
erreur et sans rien ramener, si un fournisseur a renommé un code. Sans journal,
cette panne silencieuse passerait inaperçue des mois.

\chapter{Ce qui a été construit}

\section{Les cinq onglets}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.24\textwidth} Y}
\toprule
\textbf{Onglet} & \textbf{Usage} \\
\midrule
Accueil & Présentation, chiffres de la base, téléchargement du manuel \\
Tableau de bord & Graphiques, carte du monde, projections, exports \\
Base de données & Consultation tabulaire et téléchargement en tableur \\
GoogleOPESc+ & Recherche documentaire limitée à des sources choisies \\
Collectes & Import de fichiers, suppression, journal \\
\bottomrule
\end{tabularx}
\caption{Les cinq onglets}
\end{table}

\section{Les fonctions qui font la différence}

\textbf{Les filtres ne mènent jamais dans le vide.} Les fréquences proposées,
les pays offerts et les bornes de période sont ceux qui existent réellement en
base pour l'indicateur choisi.

\textbf{L'écran n'est jamais vide au chargement.} Le tableau de bord trace
d'emblée la croissance du produit intérieur brut par habitant pour le Cameroun.
Un écran gris au premier abord laisse croire à une panne.

\textbf{La comparaison est immédiate.} Jusqu'à six séries sur un même
graphique. Quand les unités diffèrent, elles sont ramenées en base 100.

\textbf{Tout export porte ses sources.} Chaque classeur comporte une feuille
indiquant, pour chaque indicateur, sa provenance et la date d'extraction.

\textbf{Chaque définition cite son autorité.} Les définitions viennent du
fournisseur de la série, ou des manuels de référence : Système de comptabilité
nationale, Manuel de la balance des paiements, résolutions de l'Organisation
internationale du travail.

\section{La recherche orientée}

GoogleOPESc+ répond à une difficulté quotidienne : trouver une donnée sans se
perdre dans des résultats dont on ignore la provenance. La liste des sources
est fermée, trente-cinq sources choisies, dont quatre camerounaises.

Six sources au plus sont retenues par recherche, classées par pertinence.
Afficher les trente-cinq à chaque fois reviendrait à ne pas filtrer.

\section{L'import de fichiers}

Toutes les sources ne se laissent pas interroger par programme. La page des
prix des produits de base construit son lien de téléchargement en JavaScript :
aucune adresse ne figure dans le code de la page.

La plateforme assume donc l'import manuel et l'organise : dépôt depuis
l'interface, création automatique des indicateurs inconnus, choix entre
compléter et remplacer, vérification avant écriture.

\chapter{Le déroulement du projet}

\section{Les grandes étapes}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.26\textwidth} Y}
\toprule
\textbf{Étape} & \textbf{Ce qui a été fait} \\
\midrule
Portage & Abandon de Django pour R et Shiny, structure golem \\
Catalogue & Recensement des indicateurs, de leur code et de leur source \\
Connecteurs & Un par fournisseur, avec voies de repli \\
Tableau de bord & Filtres en cascade, graphiques, superposition \\
Cartographie & Carte choroplèthe, curseur d'année, fiche pays \\
Base de données & Consultation tabulaire, export traçable \\
Bilinguisme & Dictionnaire, changement de langue, tests de couverture \\
Matières premières & Six voies essayées, import manuel retenu \\
GoogleOPESc+ & Recherche restreinte, glossaire, définitions sourcées \\
Manuels & Composition LaTeX, charte du ministère \\
Mise en ligne & Compaction de la base, dépôt public, hébergement \\
Entretien & Bandeau de fraîcheur, tâche planifiée \\
\bottomrule
\end{tabularx}
\caption{Les étapes de la construction}
\end{table}

\section{Ce que le nombre de versions révèle}

Le projet a connu plus de soixante-dix versions successives. Ce nombre n'est
pas un signe de tâtonnement mais de méthode : chaque correction a fait l'objet
d'une version distincte, documentée dans un journal, de sorte qu'un défaut
introduit puisse être situé.

Une part notable de ces versions corrige des défauts que la relecture seule
n'aurait pas révélés, et qui ne sont apparus qu'à l'usage : un graphique tracé
en blanc sur fond blanc, une liste déroulante qui perdait sa sélection
multiple, un registre évalué avant que les fonctions qu'il nomme n'existent.

\begin{encadre}{La leçon la plus utile}
Un défaut qui se voit est un défaut bénin. Les coûteux sont ceux qui produisent
un résultat plausible : une série dont les ventilations ne sont pas réduites,
une définition affichée dans la mauvaise langue, des données périmées
présentées comme récentes. Les contrôles ajoutés visent ceux-là.
\end{encadre}

\chapter{Le détail des onglets}

\section{L'accueil}

Une bannière, les chiffres de la base, et six cartes repliées décrivant ce que
la plateforme permet. Le détail se déplie d'un clic : sept cartes déployées
faisaient un mur de texte que l'œil ne parcourt pas.

La bannière portait un graphique de la croissance camerounaise, tiré d'une
source nationale, avec distinction des observations et des projections. Il a
été retiré à la demande, mais le module reste dans le projet et se rallume en
une ligne.

\section{Le tableau de bord}

Le cœur de l'outil. Cinq filtres en cascade, chacun ne proposant que ce qui
existe réellement en base pour la sélection courante.

La liste des pays est rangée en trois groupes : le monde, les régions et
regroupements, puis les pays, chacun par ordre alphabétique. Une liste plate
mêlait quarante regroupements à deux cents pays.

Quatre représentations : ligne, barres, aires, camembert. Jusqu'à six séries
superposées, ramenées en base 100 quand les unités diffèrent. Trois méthodes de
prolongement, avec intervalle.

Un bandeau replié en tête explique comment télécharger et importer la base des
matières premières, en deux séries d'étapes.

\section{L'analyse cartographique}

Une carte choroplèthe bornée aux centiles 2 et 98 : quelques valeurs extrêmes
donneraient à tous les autres pays la même teinte. Un curseur d'année animable
montre une dynamique que le graphique ne rend pas quand les pays sont nombreux.
Un clic ouvre la fiche du pays.

\section{La base de données}

Consultation tabulaire avec recherche, tri et export. La catégorie du secteur
réel est sélectionnée au chargement : un tableau vide au premier abord laisse
croire que la base l'est aussi.

Quand un résultat est vide, le message dit pourquoi. Des bornes de période
inversées, cause la plus fréquente, sont nommées explicitement.

\section{GoogleOPESc+}

Quatre blocs de réponse : la définition de la notion avec sa source, les
indicateurs de la plateforme qui correspondent, les résultats du web, et les
sources à interroger directement.

Les définitions viennent du fournisseur de la série. La Banque mondiale ne
publie qu'en anglais : la langue est enregistrée, et le glossaire français
passe devant quand la notion y figure. Le texte anglais reste affiché à défaut,
avec la mention de sa langue.

\section{Les collectes}

Import de fichiers, suppression par catégorie, puis le journal. Cet ordre est
voulu : le journal rend compte de ce qui a été fait, l'import est ce qu'on
vient faire.

En ligne, seul le journal paraît : le système de fichiers du serveur est en
lecture seule, et afficher un formulaire qui échouerait toujours vaut moins que
de ne pas l'afficher.

\chapter{Les données}

\section{Le périmètre}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.38\textwidth} Y}
\toprule
\textbf{Élément} & \textbf{État} \\
\midrule
Indicateurs actifs & 315, en 14 catégories \\
Économies couvertes & 217 pays, 78 regroupements \\
Couverture temporelle & 1960 en local, 1990 en ligne \\
Fournisseurs branchés & 4, plus un fichier importé \\
Observations & environ 1,5 million \\
\bottomrule
\end{tabularx}
\caption{Le périmètre de la base}
\end{table}

\section{Les fournisseurs}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.30\textwidth} Y}
\toprule
\textbf{Fournisseur} & \textbf{Ce qu'il apporte} \\
\midrule
Banque mondiale & Indicateurs du développement, dette internationale, gouvernance, pauvreté, Findex, logistique \\
Fonds monétaire international & Perspectives de l'économie mondiale, Moniteur des finances publiques \\
Organisation internationale du travail & Chômage et emploi, estimations harmonisées \\
Growth Lab, Harvard & Atlas de la complexité économique \\
Fonds monétaire international & Prix des produits de base, par fichier importé \\
\bottomrule
\end{tabularx}
\caption{Les sources alimentant le catalogue}
\end{table}

La plateforme ne produit aucune donnée. Elle collecte, harmonise et présente
des séries dont la propriété reste celle de leurs producteurs.

\chapter{Les difficultés et leur résolution}

Ce chapitre n'a pas d'utilité opérationnelle, mais il explique le temps qu'a
demandé le projet et des choix qui paraîtraient arbitraires sans lui.

\section{Les portails changent}

Trois fournisseurs ont réorganisé leur service pendant la construction.

Le Fonds monétaire international deux fois : une adresse retirée, une autre se
mettant à refuser les requêtes automatisées. L'OCDE a retiré \\texttt{stats.oecd.org}
en 2024 pour un nouveau service, ce qui explique des réponses 404 longtemps
restées incomprises. L'Organisation internationale du travail a déplacé son
entrepôt vers un autre domaine, sans redirection.

\begin{encadre}{La règle qu'impose l'expérience}
Chaque source critique dispose désormais de plusieurs voies d'accès, essayées
en ordre, et le connecteur retient celle qui répond. Essayer plusieurs adresses
n'est pas une précaution excessive : c'est la seule façon de survivre à une
réorganisation.
\end{encadre}

\section{Les sources qui ne se laissent pas interroger}

Deux pages construisent leur lien de téléchargement en JavaScript. Six
approches ont été tentées sur les prix des produits de base avant d'en tirer la
conclusion : flux en CSV, le même en JSON, classeur de la Banque mondiale,
paquet R dédié, requêtes ciblées, flux entier filtré.

Trois obstacles s'étaient succédé. L'en-tête demandé faisait échouer la requête
sans erreur, ce qui a fait croire à un blocage. L'ordre des dimensions n'était
pas celui que documentaient les exemples. Et le joker s'écrit différemment
selon la version du protocole.

\section{Une série fausse plutôt que vide}

Le défaut le plus grave n'a pas été un échec, mais une réussite apparente.

Le premier essai du connecteur de l'Organisation internationale du travail
ramenait seize mille observations. L'extrait montrait trois valeurs
différentes pour le même pays et la même année : les ventilations par sexe et
par âge n'étaient pas réduites.

Ces lignes se seraient écrasées en base, la dernière écrite l'emportant au
hasard. La série aurait paru correcte et aurait été fausse.

Un contrôle vérifie désormais qu'il ne reste qu'une valeur par pays et par
période. S'il en reste plusieurs, la série est refusée avec un message nommant
la ventilation en cause.

\begin{encadre}{Le service ne refuse pas un code inconnu}
Interrogé sur un identifiant inventé, le service a répondu favorablement avec
trente méga-octets. Il ne refuse pas un code inconnu : il rend autre chose.
Le connecteur compare donc l'indicateur demandé à celui rendu.
\end{encadre}

\section{Le bilinguisme, plus long que prévu}

Traduire une interface ne consiste pas à traduire des chaînes. Il a fallu
traiter les libellés construits au démarrage, ceux qui viennent de fichiers de
données, ceux assemblés par concaténation, et les noms de pays publiés en
anglais par les fournisseurs.

Quatre régressions successives ont fait disparaître des traductions sans que
rien ne le signale, jusqu'à ce qu'un test balaie le code à la recherche de
textes accentués hors de toute portée de traduction.

\section{La charte, reprise deux fois}

Une première charte, bleu marine et doré, n'appartenait à personne : elle
pouvait habiller une banque comme un cabinet de conseil. Une deuxième, déduite
des armoiries de la République, s'est révélée fausse : le ministère emploie le
bleu, le blanc et le rouge.

L'enseignement vaut d'être noté : les couleurs d'une institution se relèvent,
elles ne se déduisent pas.

\chapter{La mise en ligne}

\section{L'hébergement retenu}

Posit Connect Cloud, offre gratuite, déploiement depuis un dépôt GitHub public
avec redéploiement automatique à chaque envoi. Modifier la plateforme en ligne
revient à modifier le code en local, le tester, puis le pousser.

\section{Deux contraintes traitées}

\textbf{La taille.} La base de travail pesait plus de deux cents
méga-octets, alors que GitHub refuse un fichier au-delà de cent. Les codes
d'indicateur et de pays y étaient répétés en toutes lettres sur chaque ligne.
Les remplacer par des entiers renvoyant à deux tables de correspondance a
ramené la ligne de cent cinquante à trente-quatre octets. La profondeur a
ensuite été limitée à 1990 pour la version publiée, ce qui ramène la base à
soixante méga-octets.

\textbf{Le dépôt est public.} Aucune clé ne doit y figurer : celles du moteur
de recherche se déclarent dans la console de l'hébergeur.

\section{Ce que la mise en ligne change}

Le système de fichiers du serveur est en lecture seule. La base publiée est
figée à sa date de publication, et l'onglet Collectes n'y montre que le
journal. La collecte et l'import restent des opérations locales, suivies d'une
republication.

\begin{encadre}{À savoir avant une démonstration}
L'offre gratuite met le contenu en veille après une période d'inactivité. Le
premier visiteur attend une trentaine de secondes. Ouvrez la plateforme
quelques minutes avant de commencer.
\end{encadre}

\chapter{L'entretien de la plateforme}

\section{Les données ne vieillissent plus en silence}

Une plateforme dont les données vieillissent sans le dire est pire qu'une
plateforme vide : elle affiche des chiffres périmés avec la même assurance que
des chiffres récents.

Deux dispositions, et l'ordre compte.

\textbf{La plateforme le dit.} Un bandeau apparaît dès que les données
dépassent quarante-cinq jours, et passe en alerte au-delà de cent vingt. Rien
ne s'affiche tant qu'elles sont récentes : une mention permanente deviendrait
du décor. Ce dispositif fonctionne même si personne n'automatise rien.

\textbf{Une tâche planifiée.} Un script hebdomadaire collecte ce qui manque,
reconstruit la base publiée et journalise. Il ne pousse rien sur le dépôt :
publier demande une authentification, et une machine qui publierait sans
surveillance finirait par mettre en ligne une base corrompue un jour de panne.

\section{Les commandes de diagnostic}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.34\textwidth} Y}
\toprule
\textbf{Commande} & \textbf{Usage} \\
\midrule
\texttt{diagnostic\_plateforme()} & État de la base. À lancer en premier devant un écran vide \\
\texttt{diagnostic\_fraicheur()} & Âge des données, par catégorie \\
\texttt{diagnostic\_pays()} & Référentiel et couverture d'un indicateur \\
\texttt{tester\_fournisseur()} & Éprouve un connecteur avant d'inscrire un indicateur \\
\texttt{catalogue\_ilostat()} & Cherche un code chez l'Organisation internationale du travail \\
\texttt{verifier\_publication()} & Contrôles avant un envoi \\
\bottomrule
\end{tabularx}
\caption{Les commandes de diagnostic}
\end{table}

\section{Ajouter un indicateur}

Une ligne dans le catalogue, puis une collecte sur sa catégorie. Aucune ligne
de code si le fournisseur est déjà branché. Penser à ajouter le libellé au
dictionnaire de traduction.

\begin{encadre}{Éprouver avant d'inscrire}
Un code d'indicateur ne se devine pas. \texttt{tester\_fournisseur()} vérifie
qu'il ramène des données, et que ces données ne portent qu'une valeur par pays
et par période. Inscrire un code non éprouvé remplit le catalogue d'entrées
muettes.
\end{encadre}

\chapter{Ce qui reste à faire}

\section{Par ordre de priorité}

\textbf{Faire tester par d'autres.} C'est le manque le plus sérieux. Personne
d'autre que la conceptrice n'a utilisé la plateforme. Une heure d'observation
d'un collègue apprendra plus que des semaines de perfectionnement.

\textbf{Assurer la continuité.} Le dépôt, l'hébergement et la base de travail
dépendent d'un seul compte et d'un seul poste. Un compte institutionnel pour le
dépôt, et une copie hebdomadaire de la base sur un disque partagé, écarteraient
ce risque. La base n'est pas versionnée : un fichier corrompu, et un million et
demi d'observations disparaissent.

\textbf{Installer la tâche planifiée.} Le script et son mode d'emploi sont
prêts ; il reste à les mettre en place sur un poste de la division.

\textbf{Brancher les fournisseurs restants.} La FAO, le PNUD et Transparency
International demandent chacun un travail d'exploration. Ce dernier ne publie
qu'en classeur, sans service interrogeable : il relève de l'import manuel.

\textbf{Décider du régime d'hébergement.} L'offre gratuite convient à une
consultation interne. Une ouverture plus large demanderait une offre payante ou
un hébergement au ministère.

\section{Ce qui n'est pas prioritaire}

L'OCDE couvre ses trente-huit membres, dont le Cameroun ne fait pas partie.
Pour une plateforme du MINEPAT, l'apport est faible au regard du travail de
recherche des identifiants.

\chapter{En résumé}

La plateforme est opérationnelle et accessible par un lien. Elle rassemble 315
indicateurs sur 217 économies, alimentés auprès de quatre institutions, et les
met à disposition sous forme de graphiques, de cartes et d'exports traçables.

Elle répond au besoin qui l'a fait naître : disposer d'une base commune,
traçable et actualisée, pour que les analyses de la division reposent sur les
mêmes chiffres.

Trois documents l'accompagnent. Le manuel d'utilisation, trente pages en
français et en anglais, décrit ce qu'elle fait. Le guide technique, treize
pages, explique comment elle est faite et comment la déployer. La note de
présentation, dix pages, sert à l'exposer à un tiers.

\begin{encadre}{Une réserve de méthode}
Plusieurs connecteurs ont été écrits d'après la documentation publiée des
fournisseurs, puis éprouvés un par un. Ceux qui n'ont pas ramené de données
réelles ne figurent pas au catalogue. Cette prudence explique qu'il compte
moins d'indicateurs qu'il n'aurait pu : un indicateur muet dans une liste
coûte plus qu'il ne rapporte.
\end{encadre}

\end{document}
"""


def main():
    tex = PREAMBULE
    for jeton, valeur in {
        "@@BLEUFONCE@@": BLEU_FONCE, "@@BLEULOGO@@": BLEU_LOGO,
        "@@OR@@": OR, "@@GRISTITRE@@": GRIS_TITRE,
    }.items():
        tex = tex.replace(jeton, valeur)
    tex += GARDE + CORPS

    source = Path("dossier_projet.tex")
    source.write_text(tex, encoding="utf-8")
    for aux in ("dossier_projet.aux", "dossier_projet.toc", "dossier_projet.out"):
        Path(aux).unlink(missing_ok=True)

    for _ in range(3):
        subprocess.run(["pdflatex", "-interaction=nonstopmode", str(source)],
                       capture_output=True, text=True)

    journal = Path("dossier_projet.log").read_text(errors="ignore")
    erreurs = [l for l in journal.split("\n") if l.startswith("!")][:5]
    for e in erreurs:
        print("  ", e)

    sortie = subprocess.run(["pdfinfo", "dossier_projet.pdf"],
                            capture_output=True, text=True).stdout
    n = re.search(r"Pages:\s+(\d+)", sortie)
    print(f"dossier_projet.pdf : {n.group(1) if n else '?'} pages")


if __name__ == "__main__":
    main()

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
            pdftitle={OPESc+ : guide technique}}

\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

\newtcolorbox{encadre}[1]{
  colback=black!3, colframe=black!30, boxrule=0.4pt, arc=1pt,
  left=7pt, right=7pt, top=5pt, bottom=5pt,
  title={\normalsize\bfseries\color{gristitre}#1},
  coltitle=gristitre, colbacktitle=black!3, titlerule=0pt,
  fonttitle=\bfseries, breakable, before skip=7pt, after skip=8pt}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\footnotesize OPESc+, guide technique}
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
  {\color{gristitre}\fontsize{22}{26}\selectfont\bfseries Guide technique\par}
  \vspace{0.6em}
  {\color{gristitre}\fontsize{18}{22}\selectfont\bfseries OPESc+\par}
  \vspace{1.0em}
  {\fontsize{13}{16}\selectfont Le code, la maintenance et le déploiement\par}
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
\begingroup
\setlength{\parskip}{0pt}
\renewcommand{\baselinestretch}{0.92}\selectfont
\tableofcontents
\endgroup
\clearpage

\chapter{Vue d'ensemble}

\section{Ce que fait le programme}

OPESc+ interroge les interfaces publiques de trois fournisseurs, harmonise ce
qu'elles renvoient, écrit dans une base SQLite unique, et expose cette base par
une interface Shiny en lecture seule.

Environ 6\,600 lignes de R réparties en 25 fichiers, plus 1\,100 lignes de
tests. Le tout forme un paquet R installable, organisé selon la structure
golem.

\section{Les quatre étages}

\begin{enumerate}
  \item \textbf{Connecteurs} : une fonction par fournisseur, qui interroge et
        normalise. \texttt{connecteurs.R}
  \item \textbf{Moteur de collecte} : parcourt le catalogue, appelle le
        connecteur voulu, écrit en base, journalise. \texttt{collecte.R}
  \item \textbf{Interface} : cinq modules Shiny qui lisent la base et n'y
        écrivent jamais. \texttt{mod\_*.R}
  \item \textbf{Exports} : classeurs et images autonomes portant leurs sources.
        \texttt{exports.R}
\end{enumerate}

Cette séparation a une conséquence pratique : une session de consultation ne
peut pas altérer les données, et une collecte en cours n'empêche pas la
consultation.

\section{Le catalogue, pivot du programme}

Rien n'est codé en dur. \texttt{inst/extdata/catalogue.csv} décrit chaque
indicateur : code interne, catégorie, libellé, source, code employé chez le
fournisseur, fréquences, unité, dimension pays.

Ajouter un indicateur d'un fournisseur déjà branché ne demande aucune ligne de
code : une ligne dans ce fichier suffit.

\begin{encadre}{Le code interne et le code source}
Le \emph{code source} est celui du fournisseur et lui appartient. Le \emph{code
interne} le préfixe de sa catégorie, par exemple
\texttt{C02.NY.GDP.MKTP.CD}. Cette distinction permet qu'un même indicateur
figure dans deux catégories sans collision, et rend les jointures sans
ambiguïté.
\end{encadre}

\section{Pourquoi R et Shiny}

Une première version avait été construite en Django, cadre conçu pour des
applications à comptes utilisateurs, formulaires et écritures concurrentes.
OPESc+ n'est rien de tout cela : c'est un explorateur de données en lecture
seule. Sur les quatre grandes fonctions de Django, une et demie servaient.

R présente en outre l'avantage d'être la langue de travail des statisticiens de
la division. Une évolution future, projection ou comparaison, s'y écrit en
quelques lignes là où elle demanderait une bibliothèque entière ailleurs.

\chapter{Comment fonctionne Shiny}

Ce chapitre est destiné à qui n'a jamais écrit d'application Shiny. Il explique
le modèle, non l'ensemble de l'interface.

\section{Deux fonctions, une conversation}

Une application Shiny tient en deux fonctions. \texttt{ui} décrit ce que le
navigateur affiche, \texttt{server} décrit ce qui se passe quand
l'utilisateur agit. Shiny établit une liaison permanente entre les deux, par
une connexion ouverte pendant toute la session.

\begin{verbatim}
ui <- fluidPage(
  selectInput("pays", "Pays", choices = c("CMR", "NGA")),
  plotOutput("courbe"))

server <- function(input, output, session) {
  output$courbe <- renderPlot({
    tracer(lire_serie(input$pays))
  })
}
\end{verbatim}

L'utilisateur change le pays, Shiny s'en aperçoit, réexécute le bloc de
\texttt{renderPlot} et renvoie l'image. Aucun code ne dit \emph{quand}
redessiner : c'est déduit des dépendances.

\section{La réactivité}

C'est le concept central, et le seul qui demande un effort. Shiny observe
quelles valeurs un bloc de code consulte, et le réexécute quand l'une d'elles
change. On ne programme pas la séquence, on déclare les dépendances.

Trois familles d'objets.

\textbf{Les entrées}, \texttt{input\$quelque\_chose}, viennent du navigateur.
Lire une entrée crée une dépendance.

\textbf{Les expressions réactives}, \texttt{reactive()}, calculent une valeur
intermédiaire. Elles sont paresseuses, elles ne s'exécutent que si quelqu'un
les lit, et mémorisées, elles ne recalculent que si une dépendance a changé.
C'est ce qui évite d'interroger la base dix fois pour un seul filtre.

\textbf{Les observateurs}, \texttt{observe()} et \texttt{observeEvent()},
produisent un effet sans rendre de valeur : mettre à jour un champ, écrire un
message. Ils s'exécutent toujours, sans être lus.

\begin{encadre}{Le piège de la dépendance involontaire}
Un bloc dépend de \emph{tout} ce qu'il lit. Un observateur qui consulte cinq
entrées se réexécute au changement de n'importe laquelle. \texttt{isolate()}
permet de lire une valeur sans en dépendre, et \texttt{observeEvent()} de ne
réagir qu'à un déclencheur nommé, en ignorant le reste.

Dans le tableau de bord, c'est ce qui permet au graphique de ne se redessiner
qu'au clic sur ``Appliquer'', et non à chaque frappe dans un champ.
\end{encadre}

\section{Les sorties}

Chaque \texttt{output\$nom} est associé à une fonction de rendu :
\texttt{renderPlot} pour une image, \texttt{renderUI} pour du balisage,
\texttt{DT::renderDT} pour un tableau, \texttt{plotly::renderPlotly} pour un
graphique interactif. Chacune a son correspondant côté interface,
\texttt{plotOutput}, \texttt{uiOutput}, et ainsi de suite.

\texttt{renderUI} mérite une mention : il produit de l'interface à la volée.
C'est puissant, mais coûteux, chaque rendu reconstruisant le balisage et le
renvoyant au navigateur. La plateforme l'emploie là où la structure dépend des
données, et l'évite ailleurs.

\section{Les modules}

Une application qui grandit finit par avoir des identifiants qui se marchent
dessus : deux onglets qui déclarent chacun un champ \texttt{categorie}. Le
module résout cela par un préfixe.

\begin{verbatim}
mod_tableau_bord_ui <- function(id) {
  ns <- NS(id)
  selectInput(ns("categorie"), "Catégorie", choices = NULL)
}

mod_tableau_bord_server <- function(id, con) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observeEvent(input$categorie, { ... })
  })
}
\end{verbatim}

À l'intérieur du module, \texttt{input\$categorie} désigne le champ local ;
à l'extérieur, il s'appelle \texttt{tableau\_bord-categorie}. Les cinq onglets
de la plateforme sont cinq modules.

\begin{encadre}{L'erreur à ne pas refaire}
Un module qui appelle \texttt{ns()} côté serveur doit d'abord faire
\texttt{ns <- session\$ns}. L'oubli produit \emph{impossible de trouver la
fonction ns} au moment du rendu, non au chargement : le message n'apparaît que
lorsque l'utilisateur atteint la partie concernée, ce qui rend le diagnostic
plus lent qu'il ne devrait.
\end{encadre}

\section{Le cycle d'une session}

À l'ouverture d'une page, Shiny exécute la fonction \texttt{ui} pour produire le
document, puis la fonction \texttt{server} une fois par session. Les objets
créés dans \texttt{server} appartiennent à cette session : deux visiteurs ne
partagent rien, sinon la base.

À la fermeture de l'onglet, la session est détruite. Les connexions ouvertes
dans \texttt{server} doivent être refermées, faute de quoi elles s'accumulent.
La plateforme ouvre une connexion par session et la referme à la fin.

\begin{encadre}{Ce qui s'exécute une fois et ce qui s'exécute souvent}
Le code écrit directement dans \texttt{server} s'exécute une fois par session.
Celui placé dans un \texttt{reactive} ou un \texttt{render} s'exécute chaque
fois qu'une dépendance change. Placer une lecture coûteuse au mauvais endroit
est la première cause de lenteur d'une application Shiny.
\end{encadre}

\section{Les erreurs qui reviennent}

\textbf{Un \texttt{if} sur une valeur vide.} \texttt{nzchar(NULL)} rend un
vecteur vide, et \texttt{if} sur un vecteur vide lève une erreur. Une
définition sans source a ainsi interrompu l'affichage de toute la recherche.
La parade est \texttt{isTRUE()} ou l'opérateur \texttt{\%||\%}.

\textbf{Un rendu qui dépend d'une entrée pas encore créée.} Au premier
affichage, les champs mis à jour par le serveur sont vides.
\texttt{req()} suspend proprement le rendu jusqu'à ce qu'ils soient
renseignés.

\textbf{Un script chargé avant Shiny.} Les fichiers JavaScript placés dans
l'en-tête s'exécutent avant le script de Shiny : y tester l'existence de
l'objet \texttt{Shiny} revient à ne rien enregistrer. L'écouteur se pose sur le
document, qui existe toujours.

\section{Ce que Shiny ne fait pas}

Il ne persiste rien. Chaque session repart de zéro, et l'état vit dans des
objets réactifs détruits à la fermeture. Ce qui doit survivre va en base.

Il n'aime pas les traitements longs : pendant qu'un calcul tourne, la session
ne répond plus. C'est pourquoi la collecte, qui dure des minutes, s'exécute en
console et non depuis l'interface en production.

\chapter{La structure golem}

\section{Un paquet plutôt qu'un script}

golem impose d'organiser l'application comme un paquet R : un dossier
\texttt{R/} pour le code, \texttt{inst/} pour les ressources, \texttt{tests/}
pour les tests, un \texttt{DESCRIPTION} qui déclare les dépendances.

L'intérêt n'est pas cosmétique. Les fonctions sont documentées et testables une
à une, les dépendances sont déclarées explicitement, et le tout s'installe ou
se déploie comme n'importe quel paquet.

\section{Les fichiers d'ossature}

\begin{table}[H]
\centering\footnotesize
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.24\textwidth} Y}
\toprule
\textbf{Fichier} & \textbf{Rôle} \\
\midrule
\texttt{app\_ui.R} & Bandeau, barre d'onglets, thème, assemblage des modules \\
\texttt{app\_server.R} & Connexion à la base, langue de session, appel des serveurs de modules \\
\texttt{run\_app.R} & Point d'entrée exporté \\
\texttt{app\_config.R} & \texttt{app\_sys()}, qui retrouve un fichier dans \texttt{inst/} \\
\texttt{app.R} & Point d'entrée de l'hébergeur, à la racine du dépôt \\
\bottomrule
\end{tabularx}
\caption{L'ossature de l'application}
\end{table}

\texttt{app\_sys()} appelle \texttt{system.file()} : en développement,
\texttt{pkgload} le détourne vers \texttt{inst/} du projet ; une fois
installé, il pointe vers le paquet. Le même code fonctionne dans les deux cas.

\chapter{Les fichiers du projet}

\begin{table}[H]
\centering\footnotesize
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.23\textwidth} r Y}
\toprule
\textbf{Fichier} & \textbf{Lignes} & \textbf{Rôle} \\
\midrule
\texttt{connecteurs.R} & 950 & Un connecteur par fournisseur, et le registre qui les associe aux sources \\
\texttt{mod\_tableau\_bord.R} & 730 & Filtres en cascade, graphiques, carte, projections, exports \\
\texttt{collecte.R} & 560 & Moteur de collecte, journal, compteurs, rattrapage \\
\texttt{import\_manuel.R} & 510 & Import de fichiers, création d'indicateurs, suppression \\
\texttt{recherche\_web.R} & 500 & Moteur de recherche, glossaire, correspondance des notions \\
\texttt{mod\_recherche.R} & 435 & Interface de GoogleOPESc+ \\
\texttt{bd.R} & 400 & Schéma, connexion, lectures, diagnostics \\
\texttt{graphique\_accueil.R} & 375 & Graphique SVG de la bannière, dormant \\
\texttt{definitions.R} & 275 & Récupération des définitions et de leur source \\
\texttt{mod\_accueil.R} & 245 & Bannière, chiffres, cartes de fonctionnalités \\
\texttt{mod\_collectes.R} & 230 & Import, suppression, journal \\
\texttt{publication.R} & 230 & Base compacte pour la mise en ligne \\
\texttt{graphiques.R} & 180 & Construction des graphiques \\
\texttt{mod\_base\_donnees.R} & 170 & Consultation tabulaire et export \\
\texttt{i18n.R} & 160 & Bilinguisme \\
\texttt{carte.R} & 145 & Carte choroplèthe et fiche pays \\
\bottomrule
\end{tabularx}
\caption{Les fichiers principaux, par taille}
\end{table}

Les autres sont brefs : \texttt{config.R} centralise les constantes,
\texttt{icones.R} dessine les icônes en SVG, \texttt{pays\_extra.R} complète
les codes pays, \texttt{exports.R} produit les classeurs.

\chapter{La base de données}

\section{Le schéma}

Cinq tables.

\texttt{categorie} et \texttt{pays} sont des référentiels, chargés depuis
\texttt{inst/extdata}. \texttt{indicateur} porte le catalogue et deux
compteurs, nombre d'observations et date de dernière collecte.
\texttt{observation} contient les données. \texttt{definition} porte les
définitions, leur source et leur langue.

\begin{verbatim}
CREATE TABLE observation (
  code_interne TEXT NOT NULL,
  iso3         TEXT NOT NULL,
  frequence    TEXT NOT NULL,
  date_periode TEXT NOT NULL,
  annee        INTEGER,
  valeur       REAL,
  PRIMARY KEY (code_interne, iso3, frequence, date_periode))
\end{verbatim}

\begin{encadre}{Pourquoi une clé sur quatre colonnes}
Elle rend l'écriture idempotente : relancer une collecte met à jour les valeurs
révisées sans créer de doublons, par un \texttt{ON CONFLICT DO UPDATE}. C'est
ce qui permet de relancer une collecte interrompue sans précaution.
\end{encadre}

\section{Où se trouve la base}

\texttt{chemin\_base()} cherche dans cet ordre : la variable d'environnement
\texttt{OPESC\_BASE}, le fichier de configuration, la base de travail de
l'utilisateur dans son dossier de données, puis celle livrée dans le paquet.

L'ordre compte. La base de travail passe avant celle du paquet : sans cela, dès
qu'une base publiée existe dans \texttt{inst/extdata}, la plateforme cesse
d'utiliser la base locale. Sur le serveur, le dossier utilisateur n'existe pas
et la base livrée est retenue. C'est ce qui fait fonctionner le même code en
local et en ligne.

\section{Réglages de connexion}

\texttt{connexion()} applique quatre réglages SQLite. Le journal en mode WAL
autorise la lecture pendant l'écriture, la plateforme reste donc consultable
pendant une collecte. La synchronisation relâchée multiplie par cinq à dix le
débit d'écriture. Un cache élargi et des tables temporaires en mémoire
accélèrent les tris des exports.

\section{Conventions de lecture}

Une valeur manquante n'est jamais enregistrée : l'absence de ligne vaut absence
de donnée, jamais zéro. Les fournisseurs renvoient pourtant une ligne par
couple pays-période, y compris vide ; sur un indicateur à faible couverture,
plus de neuf dixièmes du volume seraient des lignes creuses.

Toute observation est ramenée au premier jour de la période qu'elle couvre.
Cette convention permet de superposer des séries de pas différents sur un même
graphique.

\chapter{Connecteurs et collecte}

\section{Le registre}

\texttt{REGISTRE} associe chaque valeur de la colonne \texttt{source} du
catalogue à une fonction. Un indicateur dont la source n'y figure pas est
désactivé au chargement plutôt que laissé visible et muet dans l'interface.

\begin{verbatim}
REGISTRE <- list(
  "Banque mondiale (WDI)" = connecteur_banque_mondiale,
  "FMI (WEO)"             = connecteur_fmi_weo,
  ...)
\end{verbatim}

\section{Écrire un connecteur}

Une fonction qui reçoit un code source, des bornes facultatives, et rend un
tableau à quatre colonnes : \texttt{iso3}, \texttt{date\_periode},
\texttt{frequence}, \texttt{valeur}. Le moteur se charge du reste, y compris
de l'écriture et du journal.

\begin{encadre}{Ce qu'un connecteur ne doit pas faire}
Ni écrire en base, ni supposer que la réponse est complète, ni échouer
bruyamment sur une série absente. Un fournisseur qui renomme un code doit
produire une série vide et un message, non une interruption qui arrêterait
toute la collecte.
\end{encadre}

\section{Le moteur}

\texttt{collecter()} parcourt les indicateurs, appelle le connecteur, écrit par
lots, et tient le journal. Une fonction d'avancement est passée en argument, ce
qui permet d'afficher la progression en console comme dans l'interface sans
dupliquer le moteur.

\texttt{collecter\_manquants()} restreint aux indicateurs sans données. Ceux
dont la source n'a pas de connecteur ne sont pas tentés : ce serait remplir le
journal d'échecs prévisibles. Ils sont recensés en fin d'exécution.

\section{Le journal}

Chaque exécution est tracée : portée, déclenchement, statut, valeurs ajoutées
et révisées, erreurs. Une collecte peut se terminer sans erreur et sans rien
ramener, par exemple si un fournisseur a renommé un code ; sans journal, cette
panne silencieuse passerait inaperçue des mois et les analyses reposeraient sur
des séries figées.

\section{Les sources qui résistent}

Deux pages construisent leur lien de téléchargement en JavaScript : celle des
prix des produits de base et celle de l'Atlas de Harvard. Aucune adresse ne
figure dans le code de la page, et aucun programme ne peut la trouver.

Six voies ont été essayées sur les produits de base avant d'en tirer la
conclusion : paquet dédié, requêtes ciblées en SDMX, flux entier, classeur de
la Banque mondiale, et deux variantes de clé. L'import manuel prend le relais,
et c'est un choix assumé plutôt qu'un pis-aller.

\chapter{L'interface}

\section{Les cinq modules}

Un par onglet. Chacun reçoit la connexion et n'expose que son interface et son
serveur.

\section{Les filtres en cascade}

Catégorie, indicateur, fréquence, période, pays. Chaque étape ne propose que ce
qui existe réellement en base pour la sélection courante. Aucun filtre ne mène
à un graphique vide, ce qui est la règle de conception la plus structurante du
tableau de bord.

Techniquement, chaque étape est un \texttt{observeEvent} sur l'étape
précédente, qui interroge la base et met à jour le champ suivant par
\texttt{updateSelectizeInput}.

\begin{encadre}{Le piège des options de mise à jour}
Passer \texttt{options} à \texttt{updateSelectizeInput} réinitialise le
composant côté navigateur, qui perd alors son caractère multiple. Le champ
redevenait mono-sélection dès le premier chargement, et il devenait impossible
de choisir deux indicateurs. Les options se posent à la création, jamais à la
mise à jour.
\end{encadre}

\section{Superposition et base 100}

Jusqu'à six séries. Quand les unités diffèrent, elles sont ramenées en base 100
à leur première observation : superposer un pourcentage du produit intérieur
brut et un cours en dollars par tonne sur un même axe écraserait l'un des deux.

\section{La carte}

Une carte choroplèthe produite par plotly, bornée aux centiles 2 et 98 de la
distribution. Sans cette précaution, quelques valeurs extrêmes donneraient à
tous les autres pays la même teinte. Les agrégats en sont exclus, comme des
classements.

\section{Le bilinguisme}

\texttt{tr()} traduit par recherche dans un dictionnaire de plus de cinq cents
entrées, chargé depuis un CSV. Le changement de langue recharge la page avec un
paramètre d'adresse, ce qui permet de traduire jusqu'aux libellés construits au
démarrage.

Deux pièges. Les constantes évaluées au chargement du paquet ne peuvent pas
appeler \texttt{tr()}, qui n'existe pas encore : elles passent par le
dictionnaire au moment du rendu. Et un test balaie le code à la recherche de
textes accentués hors de toute portée \texttt{tr()}, car un remplacement de
bloc fait disparaître un \texttt{tr()} sans que rien ne le signale. Ce test est
né de quatre régressions successives.

\section{La charte et l'adaptation aux écrans}

Onze variables CSS portent toute la charte : trois bleus, un rouge réservé aux
actions, les gris et les bordures. Changer la charte revient à changer ces onze
valeurs.

Trois seuils d'adaptation, à 1100, 820 et 560 pixels. Une règle générale
empêche le document de défiler horizontalement : les éléments qui débordent le
font dans leur propre cadre, ce qui évite qu'un tableau ou une barre d'onglets
ne décale toute la page.

\chapter{Import, définitions et recherche}

\section{Import de fichiers}

L'onglet Collectes accepte un CSV ou un classeur. La lecture est tolérante :
les colonnes sont repérées par leur contenu autant que par leur intitulé, et le
format large, une colonne par période, est reconnu, la fréquence étant lue dans
le nom de la colonne.

Deux modes. \emph{Compléter} ajoute ou corrige. \emph{Remplacer} efface
d'abord chaque série concernée, ce qui évite qu'un fichier plus court laisse
subsister d'anciennes valeurs au-delà de sa dernière date, donnant une série
qui paraît complète alors qu'elle mélange deux millésimes.

\begin{encadre}{Une donnée importée vaut une donnée collectée}
Elle emprunte la même fonction d'écriture et alimente les mêmes compteurs. Un
indicateur est actif s'il peut être alimenté \emph{ou s'il l'est déjà} : sans
cette seconde condition, une série importée resterait invisible faute de
connecteur.
\end{encadre}

\section{Les définitions}

Elles viennent du fournisseur, avec le nom de l'organisme qui en répond. La
Banque mondiale publie pour chaque indicateur un texte et une attribution : les
deux sont repris tels quels, en anglais.

L'interface préfère le glossaire français quand la notion y figure. Vingt-neuf
notions portent des variantes de libellé, car un indicateur s'appelle ``Taux de
croissance du PIB réel'', jamais ``Croissance économique''. Les variantes sont
éprouvées de la plus longue à la plus courte, pour que la plus spécifique
l'emporte.

Le seuil est volontairement strict : deux mots partagés au moins. Un seul
suffisait, et ``prix'' rattachait ``PIB par habitant, prix courants'' à l'indice
des prix à la consommation. Une définition fausse est pire qu'une définition
absente.

\section{GoogleOPESc+}

Une recherche restreinte à trente-cinq sources choisies. Sans configuration,
chaque lien lance la recherche du terme sur le site visé, ce qui garantit
l'absence de hors-sujet. Avec un moteur de recherche programmable, les
résultats s'affichent directement, filtrés une seconde fois sur la liste des
domaines par précaution.

\chapter{Tests}

Dix-neuf fichiers, environ 1\,100 lignes. Ils ne vérifient pas seulement que le
code s'exécute, mais que les règles de lecture tiennent : agrégats exclus des
cartes, séries lacunaires non interpolées, aucun texte visible sans traduction,
aucune définition sans source, tout module appelant \texttt{ns()} le
définissant.

Plusieurs sont nés d'erreurs constatées et les rendent impossibles à
reproduire. C'est leur meilleur usage : un test écrit après coup vaut mieux
qu'un test écrit par principe.

\begin{verbatim}
testthat::test_local()
\end{verbatim}

\chapter{Mise en ligne et déploiement}

\section{L'hébergement}

Posit Connect Cloud, offre gratuite, déploiement depuis un dépôt GitHub public
avec redéploiement automatique à chaque envoi.

\section{Préparer}

\begin{verbatim}
pkgload::load_all()
preparer_publication(annee_min = 1990)
verifier_publication()
rsconnect::writeManifest()
\end{verbatim}

\texttt{preparer\_publication()} construit une base compacte : les codes
textuels sont remplacés par des entiers renvoyant à deux tables de
correspondance, ce qui ramène la ligne de 150 à 34 octets. Une vue nommée
\texttt{observation} rend l'opération transparente, le reste du code
l'interrogeant sans savoir comment elle est rangée.

\begin{encadre}{Deux contraintes à connaître}
GitHub refuse un fichier au-delà de 100 méga-octets et en signale un au-delà de
50. L'argument \texttt{annee\_min} limite la profondeur historique quand la
compaction ne suffit pas.

Le dépôt est public : aucune clé ne doit y figurer. Le \texttt{.gitignore}
écarte \texttt{.Renviron}, et \texttt{verifier\_publication()} le contrôle
avant l'envoi.
\end{encadre}

\section{Publier}

Créer un dépôt GitHub public, y pousser le projet, puis sur
\texttt{connect.posit.cloud} choisir le dépôt, la branche et \texttt{app.R}
comme fichier principal. Déclarer ensuite les variables d'environnement dans
les réglages du contenu.

\texttt{app.R} charge le paquet depuis les sources plutôt que de l'installer :
\texttt{opescplus} n'est publié sur aucun dépôt de paquets, et l'hébergeur ne
saurait pas où le prendre. Les appels à \texttt{library()} qu'il contient ne
servent pas au fonctionnement, le code étant préfixé par les espaces de noms,
mais à \texttt{writeManifest()}, qui établit la liste des dépendances en lisant
ce fichier.

\section{Mettre à jour}

\begin{verbatim}
preparer_publication(annee_min = 1990)
git add . && git commit -m "..." && git push
\end{verbatim}

\begin{encadre}{La base ne se met pas à jour toute seule}
C'est l'oubli le plus fréquent. Pousser du code sans relancer
\texttt{preparer\_publication()} publie l'ancienne base : l'interface évolue,
les données non.
\end{encadre}

\section{Le serveur est en lecture seule}

L'onglet Collectes n'y montre que le journal. La collecte et l'import restent
des opérations locales, suivies d'une republication. Le contenu se met en
veille après inactivité : le premier visiteur attend une trentaine de secondes,
ce qu'il faut savoir avant une démonstration.

\chapter{Comment la plateforme a été construite}

Ce chapitre retrace la construction. Il n'a pas d'utilité opérationnelle, mais
il explique des choix qui paraîtraient arbitraires sans lui.

\section{Le point de départ}

Une première version existait en Django. Elle fonctionnait, mais l'écart entre
l'outil et le besoin était grand : Django sert à bâtir des applications à
comptes, formulaires et écritures concurrentes, quand OPESc+ est un
explorateur en lecture seule. Le portage en R et Shiny a été décidé pour cette
raison, et parce que R est la langue de travail de la division.

\section{Le catalogue avant le code}

Le premier travail n'a pas été d'écrire des fonctions, mais de dresser le
catalogue : quels indicateurs, chez quel fournisseur, sous quel code, à quelle
fréquence. Ce fichier a précédé tout le reste, et c'est lui qui a dicté
l'architecture. Un programme qui lit un catalogue se modifie en modifiant le
catalogue.

\section{Les connecteurs, un par un}

Chaque fournisseur a demandé son propre travail d'exploration : trouver
l'adresse, comprendre le format, identifier les codes. Les interfaces
publiques sont documentées inégalement, et certaines le sont mal.

\begin{encadre}{Les portails changent}
Le Fonds monétaire international a réorganisé ses interfaces deux fois pendant
la construction. Une adresse a été retirée, une autre s'est mise à refuser
toute requête automatisée. L'Atlas de Harvard a changé de technologie d'accès.

La leçon en a été tirée : chaque source critique dispose de plusieurs voies, et
le connecteur bascule de l'une à l'autre en le signalant. C'est pourquoi le
connecteur des produits de base en compte quatre.
\end{encadre}

\section{Ce qui a résisté le plus longtemps}

Les prix des produits de base. Six approches ont été tentées : le flux SDMX en
CSV, le même en JSON, le classeur Pink Sheet de la Banque mondiale, un paquet R
dédié, des requêtes ciblées, puis le flux entier filtré côté client.

Trois obstacles se sont succédé. L'en-tête demandé faisait échouer la requête
sans erreur, ce qui a fait croire à un blocage. L'ordre des dimensions n'était
pas celui que documentaient les exemples publiés. Et le joker s'écrit
différemment selon la version du protocole.

La solution retenue est l'import manuel d'un fichier téléchargé. Ce n'est pas
un aveu d'échec : la page construit son lien en JavaScript, aucun programme ne
peut le trouver, et s'obstiner aurait produit un code fragile.

\section{L'interface, par couches}

Le tableau de bord d'abord, puisqu'il porte l'essentiel de l'usage. Puis la
base de données, l'accueil, les collectes. GoogleOPESc+ est venu en dernier,
d'un besoin exprimé en cours de route : trouver une donnée ou une publication
sans se perdre dans des résultats dont on ignore la provenance.

\section{Le bilinguisme, plus long que prévu}

Traduire une interface ne consiste pas à traduire des chaînes. Il a fallu
traiter les libellés construits au démarrage, ceux qui viennent de fichiers de
données, ceux qui sont assemblés par concaténation. Quatre régressions
successives ont fait disparaître des traductions sans que rien ne le signale,
jusqu'à ce qu'un test balaie le code à la recherche de textes accentués hors de
toute portée de traduction.

\section{La charte, deux fois}

Une première charte, bleu marine et doré, n'appartenait à personne. Une
deuxième, tirée des armoiries de la République, s'est révélée fausse : le
ministère emploie le bleu, le blanc et le rouge. La troisième est la bonne.

L'enseignement vaut d'être noté : les couleurs d'une institution se relèvent,
elles ne se déduisent pas.

\section{La mise en ligne}

Deux obstacles. La base pesait plus de deux cents méga-octets quand GitHub en
refuse cent : la compaction par entiers l'a ramenée à soixante. Et le dépôt
étant public, aucune clé ne pouvait y figurer, d'où les variables
d'environnement déclarées chez l'hébergeur.

\chapter{Maintenance courante}

\begin{table}[H]
\centering\footnotesize
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.33\textwidth} Y}
\toprule
\textbf{Commande} & \textbf{Usage} \\
\midrule
\texttt{diagnostic\_plateforme()} & État de la base, par catégorie. À lancer en premier devant un écran vide \\
\texttt{collecter\_manquants()} & Collecte tout ce qui n'a pas de données \\
\texttt{rafraichir\_compteurs()} & Remet les compteurs en accord avec les observations \\
\texttt{marquer\_langue\_definitions()} & Renseigne la langue sans aucune requête \\
\texttt{diagnostic\_frequences()} & Fréquences réellement présentes \\
\texttt{codes\_categories()} & Codes des catégories et état de collecte \\
\texttt{verifier\_recherche()} & État du moteur de recherche \\
\texttt{verifier\_publication()} & Contrôles avant un envoi \\
\bottomrule
\end{tabularx}
\caption{Les commandes de diagnostic}
\end{table}

\section{Ajouter un indicateur}

Une ligne dans \texttt{catalogue.csv}, puis \texttt{preparer\_base()} et une
collecte sur sa catégorie. Aucune ligne de code si le fournisseur est déjà
branché. Penser à ajouter le libellé au dictionnaire de traduction.

\section{Ajouter un fournisseur}

Écrire le connecteur, l'inscrire au registre, ajouter les indicateurs au
catalogue. Six fournisseurs restent à brancher : CNUCED, FAO, OIT, OCDE, PNUD,
Transparency International.

\section{Régénérer les documents}

Les sources sont dans \texttt{dev/manuel}. Le PDF passe par LaTeX, le Word par
la bibliothèque \texttt{docx}, et les deux partagent le même contenu, lu dans
les mêmes fichiers JSON.

\begin{verbatim}
python3 gen_latex.py    # manuel, PDF
node gen.js             # manuel, Word
python3 gen_note.py     # note de présentation
python3 gen_guide.py    # ce guide
\end{verbatim}

Effacer les fichiers auxiliaires de LaTeX entre deux compositions, sans quoi le
sommaire garde une numérotation périmée.

\section{Ce qui reste à faire}

Brancher les six fournisseurs manquants. Automatiser la collecte par une tâche
planifiée hebdomadaire suivie d'une republication. Traduire les libellés des
indicateurs en anglais dans l'interface, le travail étant fait pour le manuel.
Et décider du régime d'hébergement si la plateforme doit s'ouvrir plus
largement.

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

    source = Path("guide_technique.tex")
    source.write_text(tex, encoding="utf-8")
    for aux in ("guide_technique.aux", "guide_technique.toc",
                "guide_technique.out"):
        Path(aux).unlink(missing_ok=True)

    for _ in range(3):
        subprocess.run(["pdflatex", "-interaction=nonstopmode", str(source)],
                       capture_output=True, text=True)

    journal = Path("guide_technique.log").read_text(errors="ignore")
    erreurs = [l for l in journal.split("\n") if l.startswith("!")][:5]
    for e in erreurs:
        print("  ", e)

    sortie = subprocess.run(["pdfinfo", "guide_technique.pdf"],
                            capture_output=True, text=True).stdout
    n = re.search(r"Pages:\s+(\d+)", sortie)
    print(f"guide_technique.pdf : {n.group(1) if n else '?'} pages")


if __name__ == "__main__":
    main()

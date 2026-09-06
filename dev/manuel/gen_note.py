#!/usr/bin/env python3
# Note de présentation de la plateforme, dans la charte des manuels.

import subprocess
import re
from pathlib import Path

BLEU_FONCE = "12,35,87"
BLEU_LOGO = "31,77,162"
OR = "230,172,77"
GRIS_TITRE = "18,33,76"

PREAMBULE = r"""\documentclass[11pt,a4paper,openany]{report}
\usepackage[utf8]{inputenc}
\usepackage{textcomp}
\usepackage[a4paper,top=2.4cm,bottom=2.2cm,left=2.3cm,right=2.3cm]{geometry}
\usepackage{xcolor}
\usepackage{booktabs}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage{float}
\usepackage{fancyhdr}
\usepackage{titlesec}
\usepackage{tikz}
\usepackage[most]{tcolorbox}
\usepackage{enumitem}
\usepackage{hyperref}

\definecolor{bleufonce}{RGB}{@@BLEUFONCE@@}
\definecolor{bleulogo}{RGB}{@@BLEULOGO@@}
\definecolor{oropesc}{RGB}{@@OR@@}
\definecolor{gristitre}{RGB}{@@GRISTITRE@@}

\hypersetup{colorlinks=true, linkcolor=bleulogo, urlcolor=bleulogo,
            pdftitle={OPESc+ : note de presentation}}

\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

\newtcolorbox{encadre}[1]{
  colback=black!3, colframe=black!30, boxrule=0.4pt, arc=1pt,
  left=7pt, right=7pt, top=5pt, bottom=5pt,
  title={\normalsize\bfseries\color{gristitre}#1},
  coltitle=gristitre, colbacktitle=black!3, titlerule=0pt,
  fonttitle=\bfseries, breakable, before skip=8pt, after skip=10pt}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\footnotesize OPESc+, note de presentation}
\fancyhead[R]{\footnotesize DAPE / MINEPAT}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}

\titleformat{\chapter}[display]
  {\normalfont\bfseries}{\normalsize\mdseries\chaptertitlename\ \thechapter}
  {5pt}{\Large}
\titlespacing*{\chapter}{0pt}{-26pt}{16pt}

\setlist{itemsep=1pt, topsep=3pt, parsep=1pt}
\setlength{\parskip}{5pt}
\setlength{\parindent}{0pt}
\renewcommand{\arraystretch}{1.06}

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
  {\color{gristitre}\fontsize{22}{26}\selectfont\bfseries Note de présentation\par}
  \vspace{0.6em}
  {\color{gristitre}\fontsize{18}{22}\selectfont\bfseries OPESc+\par}
  \vspace{1.0em}
  {\fontsize{13}{16}\selectfont Observatoire des perspectives économiques\par}
  \vspace{1.6em}
  {\color{bleulogo}\fontsize{11}{13}\selectfont Conception, réalisation et mise en ligne\par}
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
\renewcommand{\contentsname}{Table des matières}
\tableofcontents
\endgroup
\clearpage

\chapter*{En deux mots}
\addcontentsline{toc}{chapter}{En deux mots}

OPESc+ est une plateforme de consultation des indicateurs économiques
mondiaux, construite pour la Division des Analyses et des Politiques
Économiques. Elle rassemble 313 indicateurs répartis en 14 catégories,
couvrant environ 217 économies depuis 1960, et les met à disposition sous
forme de séries exploitables : graphiques, cartes, exports en tableur.

Elle est en ligne, accessible par un simple lien, sans installation.

\begin{encadre}{Ce qu'elle est, ce qu'elle n'est pas}
OPESc+ est un outil de consultation et de restitution. Ce n'est pas un modele
macroéconomique : elle ne simule aucun choc et ne produit aucune prévision
institutionnelle. Elle complète OPESc, dont elle reprend la charte, sans s'y
substituer.
\end{encadre}

\chapter{Ce que la plateforme apporte}

\section{Le probleme de départ}

Préparer une note de conjoncture suppose de rassembler des données dispersées
entre les portails de la Banque mondiale, du Fonds monétaire international et
d'une dizaine d'autres institutions. Chacun a son interface, sa nomenclature,
son format d'export. Le temps passe a collecter n'est pas passe a analyser, et
deux notes rediges le meme mois peuvent reposer sur des millésimes différents.

\section{La réponse}

Une base unique, alimentée automatiquement aupres des sources d'origine, et une
interface qui la rend consultable sans connaissance technique.

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.26\textwidth} Y}
\toprule
\textbf{Onglet} & \textbf{Usage} \\
\midrule
Accueil & Présentation, chiffres de la base, acces aux sites de référence, téléchargement du manuel \\
Tableau de bord & Graphiques, carte du monde, projections, exports \\
Base de données & Consultation tabulaire et téléchargement en tableur \\
GoogleOPESc+ & Recherche documentaire limitée a des sources choisies \\
Collectes & Journal des actualisations et import de fichiers \\
\bottomrule
\end{tabularx}
\caption{Les cinq onglets}
\end{table}

\section{Les fonctions qui font la différence}

\textbf{Les filtres ne mènent jamais dans le vide.} Les fréquences proposées,
les pays offerts et les bornes de période sont ceux qui existent réellement en
base pour l'indicateur choisi. Un cadre vide indique toujours la raison et la
marche a suivre.

\textbf{La comparaison est immédiate.} Jusqu'a six séries sur un meme
graphique. Quand les unités diffèrent, elles sont ramenées en base 100 pour
rester comparables, automatiquement.

\textbf{La carte suit le filtre.} Un curseur d'année animable montre une
dynamique que le graphique ne rend pas quand les pays sont nombreux. Un clic
ouvre la fiche du pays.

\textbf{Tout export porte ses sources.} Chaque classeur téléchargé comporte une
feuille indiquant, pour chaque indicateur, sa provenance et la date
d'extraction. C'est ce qui rend une note vérifiable des mois plus tard.

\chapter{Les données}

\section{Origine}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.30\textwidth} Y}
\toprule
\textbf{Fournisseur} & \textbf{Ce qu'il apporte} \\
\midrule
Banque mondiale & Indicateurs du développement dans le monde, dette internationale, gouvernance, pauvreté, Findex, performance logistique \\
Fonds monétaire international & Perspectives de l'economie mondiale, Moniteur des finances publiques \\
Fonds monétaire international & Prix des produits de base, par fichier \\
Growth Lab, Harvard & Atlas de la complexité économique \\
\bottomrule
\end{tabularx}
\caption{Les sources alimentant le catalogue}
\end{table}

La plateforme ne produit aucune donnée. Elle collecte, harmonise et présente
des séries dont la propriété reste celle de leurs producteurs.

\section{Trois principes de traitement}

\textbf{Une valeur manquante n'est jamais un zero.} Elle n'est pas enregistrée,
et une serie lacunaire est tracée en pointillés, jamais interpolée. Relier deux
points distants de plusieurs années par un trait plein suggérerait une
évolution qui n'a pas ete observée.

\textbf{Les agrégats sont écartés des classements et des cartes.} Sans cela, le
monde et la zone euro occuperaient systématiquement les premières places et
écraseraient l'échelle de couleur.

\textbf{Chaque collecte est journalisée.} Une collecte peut se terminer sans
erreur et sans rien ramener, par exemple si un fournisseur a renommé un code.
Sans journal, cette panne silencieuse passerait inaperçue pendant des mois et
les analyses reposeraient sur des séries figées.

\section{Le cas des matières premières}

Cette catégorie mérite une mention, car elle fonctionne autrement.

Le portail du Fonds monétaire international construit son lien de
téléchargement en JavaScript : aucune adresse ne figure dans le code de la
page, et elle ne peut donc pas etre trouvée par programme. Six voies
differentes ont ete essayées avant d'en tirer la conclusion.

La base se téléchargé donc à la main, une fois, puis s'importée dans la
plateforme depuis l'onglet Collectes. Un encadré en tête du tableau de bord
donne la marche a suivre en deux séries d'étapes. Une base est livrée avec la
plateforme, ces étapes servent a l'actualiser.

\begin{encadre}{Une donnée importee vaut une donnée collectee}
Elle emprunte la meme fonction d'écriture, porte les mêmes fréquences et
alimente les mêmes compteurs. Un indicateur est utilisable dès lors qu'il porte
des données, quelle que soit la facon dont elles sont arrivées.
\end{encadre}

\chapter{Comment elle est faite}

\section{Le choix technique}

La plateforme est écrite en R, avec le cadre Shiny, et organisée en paquet
selon la structure golem.

Ce choix se justifie par l'usage. Une première version avait ete construite en
Django, un cadre conçu pour des applications a comptes utilisateurs, formulaires
et ecritures concurrentes. OPESc+ n'est rien de tout cela : c'est un
explorateur de données en lecture seule. Sur les quatre grandes fonctions de
Django, une et demie servaient.

R présente en outre l'avantage d'etre la langue de travail des statisticiens de
la division : les évolutions futures, projections ou comparaisons, y seront plus
faciles a mener.

\section{L'architecture}

Quatre étages, volontairement séparés.

\begin{enumerate}
  \item Les connecteurs interrogent les interfaces publiques des fournisseurs.
  \item Le moteur de collecte harmonise les codes pays, les périodes et les
        unités, puis écrit dans une base unique.
  \item L'interface lit cette base et n'y écrit jamais.
  \item Les exports produisent des fichiers autonomes portant leurs sources.
\end{enumerate}

Cette séparation a une conséquence pratique : consulter la plateforme ne peut
en aucun cas altérer les données, et une collecte en cours n'empêche pas la
consultation.

\section{Ce qui garantit la qualité}

Le projet comporte une soixantaine de tests automatisés. Ils ne vérifient pas
seulement que le code s'exécute, mais que les règles de lecture sont
respectées : que les agrégats sont bien exclus des cartes, qu'une serie
lacunaire n'est pas interpolée, qu'un changement de langue ne laisse pas de
texte en français.

Deux de ces tests sont nés d'erreurs constatées, et les rendent désormais
impossibles a reproduire.

\chapter{Les difficultés rencontrées}

Cette section n'a pas vocation a etre présentée en détail, mais elle explique
pourquoi certains choix ont ete faits, et pourquoi le projet a demandé le temps
qu'il a demandé.

\section{Les portails changent}

Le Fonds monétaire international a réorganisé ses interfaces deux fois pendant
la construction. Une adresse a ete retirée en novembre 2025, une autre s'est
mise a refuser toute requête automatisée. L'Atlas de Harvard a change de
technologie d'acces.

La leçon en a été tirée : chaque source critique dispose désormais de plusieurs
voies d'acces, et le connecteur bascule de l'une a l'autre en le signalant.

\section{Certaines sources ne se laissent pas interroger}

Deux pages, celle des prix des produits de base et celle de l'Atlas,
construisent leur lien de téléchargement en JavaScript. Aucun programme ne peut
le trouver.

Plutot que de s'obstiner, la plateforme assume l'import manuel et l'organise :
dépôt depuis l'interface, création automatique des indicateurs inconnus,
vérification de ce qui sera écrit avant de l'ecrire.

\section{Six fournisseurs restent hors d'atteinte}

La CNUCED, la FAO, l'OIT, l'OCDE, le PNUD et Transparency International
demandent chacun un connecteur spécifique, qui reste a ecrire. Leurs
indicateurs sont désactivés plutot que laissés visibles et muets dans
l'interface.

C'est un choix délibéré : un indicateur qui ne donnera rien ne doit pas figurer
dans une liste.

\chapter{La mise en ligne}

\section{Où et comment}

La plateforme est hebergee sur Posit Connect Cloud, dans son offre gratuite.
Elle se déploie depuis un dépôt GitHub public et se redéploie automatiquement a
chaque envoi de code.

Concrètement, modifier la plateforme en ligne revient a modifier le code en
local, le tester, puis le pousser. Le redéploiement prend une a deux minutes.

\section{Deux contraintes traitées}

\textbf{La taille.} La base de travail pesait plus de deux cents méga-octets,
alors que GitHub refuse un fichier au-dela de cent. Les codes d'indicateur et
de pays y etaient répétés en toutes lettres sur chaque ligne. Les remplacer par
des entiers renvoyant a deux tables de correspondance a ramené la ligne de cent
cinquante a trente-quatre octets.

\textbf{Le dépôt est public.} Aucune clef n'y figure. Les identifiants du
moteur de recherche se déclarent dans la console de l'hébergeur, en variables
d'environnement.

\section{Ce que la mise en ligne change}

Le système de fichiers du serveur est en lecture seule. La base publiée est
donc figée a sa date de publication, et l'onglet Collectes n'y montre que le
journal. La collecte et l'import restent des opérations locales, menées sur le
poste qui alimente la base, puis republiées.

\begin{encadre}{A savoir avant une démonstration}
L'offre gratuite met le contenu en veille après une période d'inactivité. Le
premier visiteur attend une trentaine de secondes au réveil. Prévenez votre
auditoire, sans quoi il croira a une panne, et ouvrez la plateforme quelques
minutes avant de commencer.
\end{encadre}

\chapter{Ce qui reste a faire}

\begin{enumerate}
  \item \textbf{Brancher les six fournisseurs manquants}, ce qui rendrait
        actifs une trentaine d'indicateurs supplémentaires.
  \item \textbf{Automatiser la collecte}, par une tâche planifiée hebdomadaire
        sur un poste de la division, suivie d'une republication.
  \item \textbf{Traduire les libellés des indicateurs en anglais} dans
        l'interface. Le travail est fait pour le manuel, il reste a le porter.
  \item \textbf{Décider du régime d'hébergement.} L'offre gratuite convient a
        une consultation interne. Une ouverture plus large demanderait une
        offre payante ou un hébergement au ministère.
\end{enumerate}

\chapter{En résumé}

\begin{table}[H]
\centering\small
\begin{tabularx}{\textwidth}{>{\raggedright\arraybackslash}p{0.34\textwidth} Y}
\toprule
\textbf{Élément} & \textbf{État} \\
\midrule
Indicateurs actifs & 313, en 14 catégories \\
Économies couvertes & environ 217, plus 40 agrégats \\
Couverture temporelle & 1960 a l'année en cours \\
Fournisseurs branchés & 3, plus un fichier importée \\
Langues & français et anglais \\
Documentation & manuel de 30 pages, dans les deux langues \\
Tests automatisés & une soixantaine \\
Hébergement & Posit Connect Cloud, offre gratuite \\
Mise à jour & envoi de code, redéploiement automatique \\
\bottomrule
\end{tabularx}
\caption{État de la plateforme}
\end{table}

La plateforme est opérationnelle et accessible par un lien. Elle répond au
besoin qui l'a fait naître : disposer d'une base commune, traçable et
actualisée, pour que les analyses de la division reposent sur les mêmes
chiffres.

\end{document}
"""


def main():
    tex = PREAMBULE
    for jeton, valeur in {
        "@@BLEUFONCE@@": BLEU_FONCE, "@@BLEULOGO@@": BLEU_LOGO,
        "@@OR@@": OR, "@@GRISTITRE@@": GRIS_TITRE,
    }.items():
        tex = tex.replace(jeton, valeur)
    tex = tex.replace("\\usepackage{tikz}", "\\usepackage{tikz}\n\\usetikzlibrary{arrows.meta}")
    tex += GARDE + CORPS

    source = Path("note_opesc.tex")
    source.write_text(tex, encoding="utf-8")

    for _ in range(3):
        r = subprocess.run(["pdflatex", "-interaction=nonstopmode", str(source)],
                           capture_output=True, text=True)
    journal = Path("note_opesc.log").read_text(errors="ignore")
    erreurs = [l for l in journal.split("\n") if l.startswith("!")][:5]
    if erreurs:
        for e in erreurs:
            print("  ", e)
    pages = subprocess.run(["pdfinfo", "note_opesc.pdf"], capture_output=True,
                           text=True).stdout
    n = re.search(r"Pages:\s+(\d+)", pages)
    print(f"note_opesc.pdf : {n.group(1) if n else '?'} pages")


if __name__ == "__main__":
    main()

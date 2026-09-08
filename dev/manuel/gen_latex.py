#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# Composition du manuel en LaTeX.
#
# Le document de reference est compose en LaTeX avec Latin Modern. Reproduire
# sa page de garde et sa typographie depuis un traitement de texte donnait un
# a-peu-pres : la police n'existe pas sur un poste ordinaire, et les
# proportions ne se retrouvent qu'a l'oeil. La chaine LaTeX les reproduit
# exactement, puisque c'est la meme.
#
# Le Word reste produit par la bibliotheque docx : un DOCX issu de LaTeX est
# toujours degrade. Les deux formats partagent en revanche le meme contenu,
# lu dans les memes fichiers JSON.
# ---------------------------------------------------------------------------

import json
import re
import subprocess
import sys
from pathlib import Path

# Couleurs relevees sur la page de garde du manuel de reference.
BLEU_FONCE = "12,35,87"      # bandeau superieur
BLEU_LOGO = "31,77,162"      # carre de la marque
OR = "230,172,77"            # fleche
GRIS_TITRE = "18,33,76"      # titre

ECHAPPEMENTS = {
    "\\": r"\textbackslash{}",
    "&": r"\&", "%": r"\%", "$": r"\$", "#": r"\#", "_": r"\_",
    "{": r"\{", "}": r"\}", "~": r"\textasciitilde{}", "^": r"\textasciicircum{}",
}


def echapper(t):
    """Protege les caracteres que LaTeX interprete."""
    # Un seul balayage : substituer les caracteres l'un apres l'autre ferait
    # retraiter par la suite les antislashs que les premieres substitutions
    # viennent d'introduire.
    t = "".join(ECHAPPEMENTS.get(c, c) for c in str(t))
    # Les guillemets francais n'existent pas dans l'encodage retenu : ils
    # deviennent des guillemets anglais, seule forme disponible sans changer
    # de police.
    t = t.replace("\u00ab\u00a0", "``").replace("\u00ab ", "``")
    t = t.replace("\u00a0\u00bb", "''").replace(" \u00bb", "''")
    t = t.replace("\u00ab", "``").replace("\u00bb", "''")
    t = t.replace("\u2019", "'").replace("\u00a0", "~")
    t = t.replace("...", r"\dots{}").replace('"', "``")
    # Le contenu entre accents graves designe du code : il prend une police a
    # chasse fixe, comme dans le manuel de reference.
    return re.sub(r"`([^`]+)`", r"\\texttt{\1}", t)


def bloc(b, langue):
    """Traduit un bloc de contenu en LaTeX."""
    genre = b[0]

    if genre == "h2":
        return "\\section{%s}\n" % echapper(b[1])

    if genre == "p":
        return echapper(b[1]) + "\n\n" if b[1] else ""

    if genre == "l":
        items = "\n".join("  \\item %s" % echapper(x) for x in b[1])
        return "\\begin{itemize}\n%s\n\\end{itemize}\n\n" % items

    if genre == "ol":
        items = "\n".join("  \\item %s" % echapper(x) for x in b[1])
        return "\\begin{enumerate}\n%s\n\\end{enumerate}\n\n" % items

    if genre == "enc":
        return ("\\begin{encadre}{%s}\n%s\n\\end{encadre}\n\n"
                % (echapper(b[1]), echapper(b[2])))

    if genre == "tab":
        titre, entetes, lignes = b[1], b[2], b[3]
        n = len(entetes)
        # La premiere colonne porte le libelle, souvent long : elle reste
        # elastique, les autres se partagent le reste.
        # La premiere colonne porte le libelle, souvent long : elle recoit une
        # largeur fixe, les autres se partagent le reste par elasticite.
        premiere = {2: "0.42", 3: "0.30"}.get(n, "0.25")
        spec = (">{\\raggedright\\arraybackslash}p{%s\\textwidth}" % premiere
                + " " + " ".join(["Y"] * (n - 1)))
        entete = " & ".join("\\textbf{%s}" % echapper(h) for h in entetes)
        corps = " \\\\\n".join(
            " & ".join(echapper(c) for c in l) for l in lignes)
        return (
            "\\begin{table}[H]\n\\centering\\small\n"
            "\\begin{tabularx}{\\textwidth}{%s}\n"
            "\\toprule\n%s \\\\\n\\midrule\n%s \\\\\n\\bottomrule\n"
            "\\end{tabularx}\n\\caption{%s}\n\\end{table}\n\n"
            % (spec, entete, corps, echapper(titre)))

    return ""


def catalogue_latex(catalogue, T, langue):
    """Annexe du catalogue, une section par categorie."""
    sortie = []
    for cat in catalogue:
        sortie.append("\\section*{%s. %s}\n"
                      % (cat["code"], echapper(cat[langue])))
        sortie.append("\\addcontentsline{toc}{section}{%s. %s}\n"
                      % (cat["code"], echapper(cat[langue])))
        indic = cat["indicateurs"]
        sources = sorted({i["source"] for i in indic})

        if len(indic) > 50:
            # Deux colonnes de paires : cent huit produits tiennent ainsi sur
            # une page et demie au lieu de quatre.
            moitie = (len(indic) + 1) // 2
            lignes = []
            for k in range(moitie):
                g = indic[k]
                d = indic[k + moitie] if k + moitie < len(indic) else None
                lignes.append([g[langue], g["code"],
                               d[langue] if d else "", d["code"] if d else ""])
            entetes = [T["entetesCatalogue"][0], T["entetesCatalogue"][1]] * 2
            sortie.append(
                "{\\scriptsize\\setlength{\\tabcolsep}{2pt}\\renewcommand{\\arraystretch}{0.96}\n"
                "\\begin{longtable}{p{0.29\\textwidth}p{0.15\\textwidth}"
                "p{0.29\\textwidth}p{0.15\\textwidth}}\n\\toprule\n"
                + " & ".join("\\textbf{%s}" % echapper(h) for h in entetes)
                + " \\\\\n\\midrule\n\\endhead\n"
                + " \\\\\n".join(
                    " & ".join(
                        "\\texttt{%s}" % echapper(c) if j in (1, 3) else echapper(c)
                        for j, c in enumerate(l)) for l in lignes)
                + " \\\\\n\\bottomrule\n\\end{longtable}}\n")
        else:
            lignes = [[i[langue], i["code"], i["unite"]] for i in indic]
            sortie.append(
                "{\\footnotesize\\setlength{\\tabcolsep}{4pt}\n\\begin{longtable}{p{0.40\\textwidth}p{0.24\\textwidth}"
                "p{0.26\\textwidth}}\n\\toprule\n"
                + " & ".join("\\textbf{%s}" % echapper(h) for h in T["entetesCatalogue"])
                + " \\\\\n\\midrule\n\\endhead\n"
                + " \\\\\n".join(
                    " & ".join(
                        "\\texttt{%s}" % echapper(c) if j == 1 else echapper(c)
                        for j, c in enumerate(l)) for l in lignes)
                + " \\\\\n\\bottomrule\n\\end{longtable}}\n")

        sortie.append("\\noindent{\\footnotesize\\itshape %s %s\\par}\n\\vspace{1.2em}\n"
                      % (echapper(T["sourceLabel"]), echapper(", ".join(sources))))
    return "".join(sortie)


def preambule(T):
    modele = r"""\documentclass[10pt,a4paper,openany]{report}
\usepackage[utf8]{inputenc}
\usepackage{textcomp}
\usepackage[a4paper,top=2.3cm,bottom=2.1cm,left=2.2cm,right=2.2cm]{geometry}
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
\usepackage{hyperref}
\usepackage{enumitem}

\definecolor{bleufonce}{RGB}{@@BLEUFONCE@@}
\definecolor{bleulogo}{RGB}{@@BLEULOGO@@}
\definecolor{oropesc}{RGB}{@@OR@@}
\definecolor{gristitre}{RGB}{@@GRISTITRE@@}

\hypersetup{colorlinks=true, linkcolor=bleulogo, urlcolor=bleulogo,
            pdftitle={@@TITRE@@}, pdfauthor={@@SERVICE@@}}

\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

% Encadre : filet fin, fond tres clair, titre en gras. Meme sobriete que le
% document de reference.
\newtcolorbox{encadre}[1]{
  colback=black!3, colframe=black!30, boxrule=0.4pt, arc=1pt,
  left=7pt, right=7pt, top=5pt, bottom=5pt,
  title={\normalsize\bfseries\color{gristitre}#1},
  coltitle=gristitre, colbacktitle=black!3, titlerule=0pt,
  fonttitle=\bfseries, breakable, before skip=8pt, after skip=9pt}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\footnotesize @@ENTETEG@@}
\fancyhead[R]{\footnotesize @@ENTETED@@}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.4pt}

\titleformat{\chapter}[display]
  {\normalfont\bfseries}{\normalsize\mdseries\chaptertitlename\ \thechapter}
  {5pt}{\Large}
\titlespacing*{\chapter}{0pt}{-26pt}{16pt}
\titleformat{\section}{\normalfont\large\bfseries}{\thesection}{0.7em}{}
\titlespacing*{\section}{0pt}{12pt}{5pt}

\setlist{itemsep=1pt, topsep=3pt, parsep=1pt}
\setlength{\parskip}{5pt}
\setlength{\parindent}{0pt}
\renewcommand{\arraystretch}{1.06}

\renewcommand{\chaptername}{@@CHAPITRE@@}
\renewcommand{\tablename}{@@TABLE@@}
\renewcommand{\appendixname}{@@ANNEXE@@}
\renewcommand{\contentsname}{@@SOMMAIRE@@}
\renewcommand{\listtablename}{@@LISTETAB@@}

% Les sous-titres sont numerotes 7.1, 7.2, non 7.0.1 : sans cette remise a
% zero, le compteur de section ignore le changement de chapitre.
\counterwithin{section}{chapter}
\renewcommand{\thesection}{\thechapter.\arabic{section}}

\begin{document}
"""
    remplacements = {
        "@@BLEUFONCE@@": BLEU_FONCE, "@@BLEULOGO@@": BLEU_LOGO,
        "@@OR@@": OR, "@@GRISTITRE@@": GRIS_TITRE,
        "@@TITRE@@": echapper(T["titre"]), "@@SERVICE@@": echapper(T["service"]),
        "@@ENTETEG@@": echapper(T["enteteGauche"]),
        "@@ENTETED@@": echapper(T["servicePied"]),
        "@@CHAPITRE@@": echapper(T["chapitre"]),
        "@@TABLE@@": echapper(T["tableau"]),
        "@@ANNEXE@@": echapper(T["annexe"]),
        "@@SOMMAIRE@@": echapper(T["sommaire"]),
        "@@LISTETAB@@": echapper(T["listeTableaux"]),
    }
    for jeton, valeur in remplacements.items():
        modele = modele.replace(jeton, valeur)
    return modele


def garde(T):
    """Page de garde, reproduite d'apres celle du manuel de reference.

    Le bandeau occupe le quart superieur de la page, la marque le chevauche,
    et la fleche doree en depasse vers le bas. Les proportions sont celles
    relevees sur le document d'origine.
    """
    modele = r"""
\thispagestyle{empty}
\begin{tikzpicture}[remember picture, overlay]
  % Bandeau superieur, sur le quart de la hauteur.
  \fill[bleufonce] (current page.north west)
    rectangle ([yshift=-0.248\paperheight]current page.north east);
  % Marque, a cheval sur le bas du bandeau : elle le deborde vers le bas,
  % comme dans le document de reference.
  \node[fill=bleulogo, rounded corners=9pt, minimum width=2.5cm,
        minimum height=2.5cm, anchor=center]
    at ([yshift=-0.202\paperheight]current page.north)
    {\color{white}\fontsize{30}{34}\selectfont OP};
  % Fleche montante, sous la marque, debordant sur le blanc. La pointe est
  % dessinee par le trace lui-meme plutot que par un triangle rapporte : elle
  % s'aligne ainsi sur la direction du dernier segment.
  \draw[oropesc, line width=2pt, line cap=round, line join=round,
        -{Latex[length=3.4mm, width=2.6mm]}]
    ([xshift=-1.05cm, yshift=-0.283\paperheight]current page.north)
    -- ++(0.60,0.34) -- ++(0.50,-0.26) -- ++(0.95,0.66);
\end{tikzpicture}

\vspace*{0.30\paperheight}
\begin{center}
  {\color{gristitre}\fontsize{22}{26}\selectfont\bfseries @@TITRE@@\par}
  \vspace{1.0em}
  {\fontsize{13}{16}\selectfont @@SOUSTITRE@@\par}
  \vspace{1.6em}
  {\color{bleulogo}\fontsize{11}{13}\selectfont @@VERSION@@\par}
  \vspace{4.2em}
  {\fontsize{12}{15}\selectfont\bfseries @@SERVICE@@\par}
  \vspace{0.7em}
  {\fontsize{11}{13}\selectfont @@MINISTERE@@\par}
  \vspace{1.7em}
  {\fontsize{10}{12}\selectfont @@DATE@@\par}
\end{center}
\clearpage
"""
    for jeton, valeur in {
        "@@TITRE@@": echapper(T["titre"]), "@@SOUSTITRE@@": echapper(T["sousTitre"]),
        "@@VERSION@@": echapper(T["version"]), "@@SERVICE@@": echapper(T["service"]),
        "@@MINISTERE@@": echapper(T["ministere"]), "@@DATE@@": echapper(T["date"]),
    }.items():
        modele = modele.replace(jeton, valeur)
    return modele


def construire(langue):
    T = json.load(open(f"contenu_{langue}.json", encoding="utf-8"))
    catalogue = json.load(open("catalogue.json", encoding="utf-8"))

    sortie = [preambule(T), garde(T)]

    # Sommaire et liste des tableaux, en chiffres romains comme la reference.
    sortie.append("\\pagenumbering{roman}\n\\setcounter{page}{1}\n")
    sortie.append("\\renewcommand{\\contentsname}{%s}\n" % echapper(T["sommaire"]))
    sortie.append("\\begingroup\\setlength{\\parskip}{0pt}\n\\tableofcontents\n")
    sortie.append("\\renewcommand{\\listtablename}{%s}\n" % echapper(T["listeTableaux"]))
    sortie.append("\\vspace{1.5em}\n\\listoftables\n\\endgroup\n\\clearpage\n")
    sortie.append("\\pagenumbering{arabic}\n\\setcounter{page}{1}\n")

    # Resume executif, sans numero de chapitre.
    sortie.append("\\chapter*{%s}\n" % echapper(T["resume"]))
    sortie.append("\\addcontentsline{toc}{chapter}{%s}\n" % echapper(T["resume"]))
    for b in T["resumeBlocs"]:
        sortie.append(bloc(b, langue))
    sortie.append("\\clearpage\n")

    for c in T["chapitres"]:
        sortie.append("\\chapter{%s}\n" % echapper(c["t"]))
        for b in c["blocs"]:
            sortie.append(bloc(b, langue))

    sortie.append("\\appendix\n")
    sortie.append("\\renewcommand{\\chaptername}{%s}\n" % echapper(T["annexe"]))
    for a in T["annexes"]:
        sortie.append("\\chapter{%s}\n" % echapper(a["t"]))
        for b in a["blocs"]:
            if b[0] == "cat":
                sortie.append(catalogue_latex(catalogue, T, langue))
            else:
                sortie.append(bloc(b, langue))

    sortie.append("\\end{document}\n")
    return "".join(sortie)


def main():
    for langue in ("fr", "en"):
        source = Path(f"manuel_{langue}.tex")
        source.write_text(construire(langue), encoding="utf-8")

        # Trois passes : la premiere etablit les references, la deuxieme
        # renseigne le sommaire, la troisieme stabilise la pagination que le
        # sommaire vient de decaler.
        for passe in range(3):
            r = subprocess.run(
                ["pdflatex", "-interaction=nonstopmode", "-halt-on-error",
                 str(source)],
                capture_output=True, text=True)
            if r.returncode != 0 and passe == 0:
                journal = Path(f"manuel_{langue}.log")
                erreurs = [l for l in journal.read_text(errors="ignore").split("\n")
                           if l.startswith("!")][:6]
                print(f"{langue} : echec de composition")
                for e in erreurs:
                    print("   ", e)
                sys.exit(1)

        pdf = Path(f"manuel_{langue}.pdf")
        cible = Path(f"manuel_opesc_{langue}.pdf")
        pdf.replace(cible)
        pages = subprocess.run(["pdfinfo", str(cible)], capture_output=True,
                               text=True).stdout
        n = re.search(r"Pages:\s+(\d+)", pages).group(1)
        print(f"{langue} : {n} pages, {cible.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()

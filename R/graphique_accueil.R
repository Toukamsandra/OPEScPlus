# ---------------------------------------------------------------------------
# Graphique de la banniere d'accueil.
#
# Une illustration decorative ne dit rien de la plateforme. Un graphique de la
# croissance camerounaise, tire de la base elle-meme, montre d'emblee ce
# qu'elle contient et de quelle source elle le tient : c'est une demonstration
# plutot qu'un ornement.
#
# Il est trace en SVG cote serveur, et non par une bibliotheque interactive :
# une banniere n'a pas a etre survolee ni zoomee, et un SVG s'affiche sans
# attendre le chargement d'un moteur graphique.
# ---------------------------------------------------------------------------

#' Serie de croissance a afficher sur la banniere
#'
#' Cherche successivement la croissance du produit interieur brut, puis le
#' produit interieur brut en volume. La premiere trouvee est retenue.
#' @noRd
serie_croissance <- function(con, iso3 = "CMR") {
  # Une source nationale passe avant toute autre. Sur la page d'accueil d'une
  # plateforme du ministere, un chiffre camerounais doit venir d'une
  # institution camerounaise : l'Institut national de la statistique produit
  # les comptes nationaux, la Banque mondiale les reprend. Citer le second
  # quand le premier est disponible serait un contresens.
  nationale <- serie_nationale()
  if (!is.null(nationale)) return(nationale)

  # A defaut, les sources internationales, dans l'ordre de preference.
  candidats <- list(
    list(code = "NY.GDP.MKTP.KD.ZG",
         titre = "Taux de croissance du PIB r\u00e9el, Cameroun", unite = "%"),
    list(code = "NGDP_RPCH",
         titre = "Taux de croissance du PIB r\u00e9el, Cameroun", unite = "%"),
    list(code = "NY.GDP.PCAP.KD.ZG",
         titre = "Croissance du PIB par habitant, Cameroun", unite = "%"),
    list(code = "NY.GDP.DEFL.KD.ZG",
         titre = "D\u00e9flateur du PIB, variation annuelle, Cameroun", unite = "%"))

  for (c_ in candidats) {
    d <- tryCatch(DBI::dbGetQuery(con, "
      SELECT o.annee, o.valeur, i.source
      FROM observation o
      JOIN indicateur i ON i.code_interne = o.code_interne
      WHERE i.code_source = ? AND o.iso3 = ? AND o.frequence = 'A'
        AND o.valeur IS NOT NULL
      ORDER BY o.annee", params = list(c_$code, iso3)),
      error = function(e) NULL)

    if (!is.null(d) && nrow(d) >= 5) {
      d <- utils::tail(d, 20)
      d$titre <- c_$titre
      d$unite <- c_$unite
      return(d)
    }
  }

  d <- tryCatch(DBI::dbGetQuery(con, "
    SELECT o.annee, o.valeur, i.source
    FROM observation o
    JOIN indicateur i ON i.code_interne = o.code_interne
    WHERE i.code_source = 'NY.GDP.MKTP.CD' AND o.iso3 = ? AND o.frequence = 'A'
      AND o.valeur IS NOT NULL
    ORDER BY o.annee", params = list(iso3)), error = function(e) NULL)
  if (!is.null(d) && nrow(d) >= 5) {
    d <- utils::tail(d, 20)
    d$valeur <- d$valeur / 1e9
    d$titre <- "Produit int\u00e9rieur brut, Cameroun"
    d$unite <- "milliards USD"
    return(d)
  }
  NULL
}

#' Serie nationale saisie a la main
#'
#' Lue dans `inst/extdata/serie_nationale.csv`, que l'on remplit avec les
#' chiffres publies par l'institution camerounaise de son choix. Le fichier de
#' metadonnees qui l'accompagne porte le titre, l'unite et le nom de la source
#' a citer.
#'
#' Ce detour par un fichier n'est pas un pis-aller. Aucune institution
#' camerounaise ne publie d'interface interrogeable par programme : la donnee
#' se trouve dans des rapports et des tableurs, et la saisir une fois par an
#' est plus sur que de moissonner une page qui changera.
#' @noRd
serie_nationale <- function() {
  chemin <- app_sys("extdata/serie_nationale.csv")
  meta_chemin <- app_sys("extdata/serie_nationale_metadonnees.csv")
  if (!nzchar(chemin) || !file.exists(chemin)) return(NULL)

  d <- tryCatch(utils::read.csv(chemin, stringsAsFactors = FALSE,
                                fileEncoding = "UTF-8-BOM"),
                error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)
  if (!all(c("annee", "valeur") %in% names(d))) return(NULL)

  d$annee <- suppressWarnings(as.integer(d$annee))
  d$valeur <- suppressWarnings(as.numeric(d$valeur))
  d <- d[!is.na(d$annee) & !is.na(d$valeur), ]
  if (nrow(d) < 5) return(NULL)
  d <- d[order(d$annee), ]

  # Le statut distingue observation et projection. Sans lui, une prevision
  # s'afficherait comme un constat, ce qui n'est pas admissible sur la page
  # d'accueil d'une plateforme du ministere.
  if (!"statut" %in% names(d)) d$statut <- "observe"

  meta <- tryCatch(utils::read.csv(meta_chemin, stringsAsFactors = FALSE,
                                   fileEncoding = "UTF-8-BOM"),
                   error = function(e) NULL)
  lire <- function(champ, defaut) {
    if (is.null(meta)) return(defaut)
    v <- meta$valeur[meta$champ == champ]
    if (length(v) && nzchar(v[[1]])) v[[1]] else defaut
  }
  anglais <- identical(langue_courante(), "en")

  # Toute la serie est conservee : couper les projections priverait le lecteur
  # de ce que la banniere a de plus interessant a montrer.
  data.frame(
    annee = d$annee,
    valeur = d$valeur,
    statut = d$statut,
    source = lire(if (anglais) "source_en" else "source",
                  "Institut national de la statistique du Cameroun"),
    titre = lire(if (anglais) "titre_en" else "titre",
                 "Taux de croissance du PIB r\u00e9el"),
    unite = lire("unite", "%"),
    mention = lire(if (anglais) "mention_projection_en" else "mention_projection",
                   ""),
    stringsAsFactors = FALSE)
}

#' Explique pourquoi la banniere n'affiche pas de graphique
#'
#' A lancer quand la banniere montre l'illustration au lieu de la courbe : la
#' fonction dit lequel des codes attendus manque, et s'il manque au catalogue
#' ou seulement en donnees.
#'
#' @examples
#' \dontrun{
#' diagnostic_banniere()
#' }
#' @export
diagnostic_banniere <- function(iso3 = "CMR") {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  codes <- c("NY.GDP.MKTP.KD.ZG", "NGDP_RPCH", "NY.GDP.PCAP.KD.ZG",
             "NY.GDP.DEFL.KD.ZG", "NY.GDP.MKTP.CD")
  cat(sprintf("Recherche d'une serie pour %s.\n\n", iso3))

  for (code in codes) {
    ind <- DBI::dbGetQuery(con,
      "SELECT code_interne, libelle, actif, nb_observations FROM indicateur
       WHERE code_source = ?", params = list(code))
    if (!nrow(ind)) {
      cat(sprintf("  %-20s absent du catalogue\n", code)); next
    }
    n <- DBI::dbGetQuery(con, "
      SELECT COUNT(*) AS n FROM observation
      WHERE code_interne = ? AND iso3 = ? AND frequence = 'A'
        AND valeur IS NOT NULL",
      params = list(ind$code_interne[[1]], iso3))$n
    cat(sprintf("  %-20s %s, %d observations pour %s\n", code,
                if (ind$actif[[1]] == 1) "actif" else "inactif", n, iso3))
  }

  d <- serie_croissance(con, iso3)
  if (is.null(d)) {
    cat("\nAucune serie retenue : la banniere affiche l'illustration.\n")
    cat("Lancez collecter_en_lot(categorie = \"C02\") pour alimenter le PIB.\n")
  } else {
    cat(sprintf("\nSerie retenue : %s, %d points de %d a %d.\n",
                d$titre[[1]], nrow(d), min(d$annee), max(d$annee)))
  }
  invisible(NULL)
}

#' Trace la serie en SVG, a la maniere du tableau de bord
#'
#' Le graphique est construit pendant l'assemblage de la page, et non par un
#' rendu reactif. La difference est nette a l'usage : un rendu reactif demande
#' de charger la bibliotheque graphique, puis un aller-retour avec le serveur,
#' pendant lesquels la banniere reste vide. Un SVG arrive avec le reste du
#' document et s'affiche du premier coup.
#'
#' L'apparence reprend celle des graphiques du tableau de bord : fond clair,
#' grille horizontale legere, courbe bleue avec ses points, titre en gras.
#' @noRd
svg_croissance <- function(d, largeur = 560, hauteur = 300) {
  marge <- list(g = 52, d = 18, h = 46, b = 40)
  aire_l <- largeur - marge$g - marge$d
  aire_h <- hauteur - marge$h - marge$b

  x <- d$annee
  y <- d$valeur

  # L'echelle englobe le zero pour un taux : sans l'axe des abscisses, une
  # annee de recession passerait pour un simple creux.
  taux <- grepl("%", d$unite[[1]], fixed = TRUE)
  y_min <- if (taux) min(c(y, 0)) else min(y)
  y_max <- max(c(y, if (taux) 0 else y))
  etendue <- y_max - y_min
  if (etendue == 0) etendue <- 1
  y_min <- y_min - etendue * 0.12
  y_max <- y_max + etendue * 0.12

  px <- function(v) marge$g + (v - min(x)) / max(1, diff(range(x))) * aire_l
  py <- function(v) marge$h + (y_max - v) / (y_max - y_min) * aire_h

  # Graduations rondes plutot qu'a intervalles calcules : un axe qui affiche
  # 2,7 et 5,4 se lit moins bien qu'un axe qui affiche 0, 2, 4.
  graduations <- pretty(c(y_min, y_max), n = 4)
  graduations <- graduations[graduations >= y_min & graduations <= y_max]

  nombre <- function(v) {
    formatC(v, format = "f", digits = if (max(abs(y)) < 100) 1 else 0,
            big.mark = "\u202f", decimal.mark = ",")
  }

  grille <- paste(vapply(graduations, function(g) sprintf(
    '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1"/>
     <text x="%.1f" y="%.1f" class="g-axe" text-anchor="end">%s</text>',
    marge$g, py(g), largeur - marge$d, py(g),
    if (abs(g) < 1e-9) "#B9C6D6" else "#EDF1F6",
    marge$g - 9, py(g) + 4, nombre(g)), character(1)), collapse = "")

  # Deux traces distincts. La projection reprend au dernier point observe pour
  # que la courbe ne se rompe pas, et se poursuit en pointilles : le lecteur
  # voit d'un coup d'oeil ou s'arrete le constat et ou commence la prevision.
  statut <- if ("statut" %in% names(d)) d$statut else rep("observe", length(x))
  observes <- statut != "projection"
  i_obs <- which(observes)
  i_proj <- which(!observes)

  trace <- function(indices) {
    if (!length(indices)) return("")
    paste(sprintf("%.1f,%.1f", px(x[indices]), py(y[indices])), collapse = " ")
  }
  points_obs <- trace(i_obs)
  points_proj <- if (length(i_proj)) {
    trace(c(utils::tail(i_obs, 1), i_proj))
  } else ""

  # Fond leger sur la zone de projection, pour la designer sans la souligner.
  zone <- if (length(i_proj)) {
    debut_zone <- px(x[utils::tail(i_obs, 1)])
    sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#0A2F5C"
             fill-opacity=".04"/>', debut_zone, marge$h,
            largeur - marge$d - debut_zone, aire_h)
  } else ""

  rayon <- if (length(x) <= 8) 3.6 else 2.2

  # Chaque point recoit une zone de survol large, un repere et une infobulle.
  # L'interactivite est obtenue en CSS seul, sans bibliotheque a telecharger :
  # une banniere ne doit pas faire attendre, et plotly imposait de charger un
  # moteur graphique puis un aller-retour avec le serveur avant de rien
  # afficher.
  demi <- if (length(x) > 1) aire_l / (length(x) - 1) / 2 else aire_l / 2
  bord_droit <- largeur - marge$d

  groupes <- vapply(seq_along(x), function(i) {
    cx <- px(x[i]); cy <- py(y[i])
    # L'infobulle bascule a gauche pres du bord droit, sinon elle sortirait
    # du cadre.
    a_gauche <- cx > largeur - 120
    tx <- if (a_gauche) cx - 10 else cx + 10
    ancrage <- if (a_gauche) "end" else "start"
    largeur_bulle <- 96
    bx <- if (a_gauche) tx - largeur_bulle else tx

    sprintf(paste0(
      '<g class="g-point" tabindex="0">',
      '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="transparent"/>',
      '<line class="g-guide" x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/>',
      '<circle class="g-repere" cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>',
      '<circle class="g-halo" cx="%.1f" cy="%.1f" r="6.5" fill="%s"/>',
      '<g class="g-infobulle">',
      '<rect x="%.1f" y="%.1f" width="%d" height="34" rx="4"/>',
      '<text x="%.1f" y="%.1f" text-anchor="%s" class="g-bulle-annee">%d</text>',
      '<text x="%.1f" y="%.1f" text-anchor="%s" class="g-bulle-valeur">%s %s</text>',
      '</g></g>'),
      cx - demi, marge$h, demi * 2, aire_h,
      cx, marge$h, cx, marge$h + aire_h,
      cx, cy, rayon, if (observes[i]) "#0A2F5C" else "#7C93B4",
      cx, cy, if (observes[i]) "#0A2F5C" else "#7C93B4",
      bx, max(marge$h, cy - 44), largeur_bulle,
      tx, max(marge$h, cy - 44) + 14, ancrage, x[i],
      tx, max(marge$h, cy - 44) + 28, ancrage, nombre(y[i]),
      if (observes[i]) escamoter(d$unite[[1]])
      else paste0(escamoter(d$unite[[1]]), " (proj.)"))
  }, character(1))
  groupes <- paste(groupes, collapse = "")

  # Quelques annees en abscisse, pas toutes : vingt-six libelles se
  # chevaucheraient. La derniere est toujours portee, mais elle remplace le
  # repere precedent s'il en est trop proche.
  pas <- max(1, ceiling(length(x) / 8))
  reperes <- x[seq(1, length(x), by = pas)]
  if (utils::tail(reperes, 1) != max(x)) {
    if (max(x) - utils::tail(reperes, 1) < pas / 2) {
      reperes <- utils::head(reperes, -1)
    }
    reperes <- c(reperes, max(x))
  }
  abscisses <- paste(vapply(reperes, function(a) sprintf(
    '<text x="%.1f" y="%.1f" class="g-axe" text-anchor="middle">%d</text>',
    px(a), hauteur - 14, a), character(1)), collapse = "")

  paste0(
    sprintf('<svg viewBox="0 0 %d %d" class="g-croissance" role="img"
             xmlns="http://www.w3.org/2000/svg">', largeur, hauteur),
    sprintf('<text x="%.1f" y="24" class="g-titre">%s</text>', marge$g - 9,
            escamoter(d$titre[[1]])),
    sprintf('<text x="%.1f" y="40" class="g-unite">%s</text>', marge$g - 9,
            escamoter(d$unite[[1]])),
    zone, grille,
    sprintf('<polyline points="%s" fill="none" stroke="#0A2F5C"
             stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
            points_obs),
    if (nzchar(points_proj)) sprintf(
      '<polyline points="%s" fill="none" stroke="#7C93B4" stroke-width="2"
       stroke-dasharray="5 4" stroke-linejoin="round" stroke-linecap="round"/>',
      points_proj) else "",
    groupes,
    # Le repere rouge marque la derniere annee observee, non le dernier point
    # trace : c'est elle qui separe le constat de la prevision.
    sprintf('<circle cx="%.1f" cy="%.1f" r="4.2" fill="#CE1126"/>',
            px(x[utils::tail(i_obs, 1)]), py(y[utils::tail(i_obs, 1)])),
    sprintf('<text x="%.1f" y="%.1f" class="g-derniere" text-anchor="middle">%s</text>',
            px(x[utils::tail(i_obs, 1)]), py(y[utils::tail(i_obs, 1)]) - 12,
            nombre(y[utils::tail(i_obs, 1)])),
    if (length(i_proj)) sprintf(
      '<text x="%.1f" y="%.1f" class="g-mention" text-anchor="end">%s</text>',
      largeur - marge$d, marge$h - 8, escamoter(d$mention[[1]])) else "",
    abscisses,
    '</svg>')
}

#' Protege un texte insere dans du SVG
#' @noRd
escamoter <- function(t) {
  t <- gsub("&", "&amp;", t, fixed = TRUE)
  t <- gsub("<", "&lt;", t, fixed = TRUE)
  gsub(">", "&gt;", t, fixed = TRUE)
}

#' Bloc complet de la banniere : graphique, titre et source
#'
#' Appelee pendant l'assemblage de l'interface. La connexion y est ouverte et
#' refermee aussitot : c'est une lecture unique, et la garder ouverte pour une
#' banniere immobiliserait une connexion par session.
#' @noRd
banniere_graphique <- function() {
  d <- tryCatch({
    con <- connexion()
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    serie_croissance(con)
  }, error = function(e) NULL)

  if (is.null(d) || nrow(d) < 5) {
    # Sans donnee, l'illustration reprend sa place : une banniere vide serait
    # pire qu'une banniere decorative.
    return(shiny::img(src = "www/illustration.svg",
                      alt = tr("Illustration : donn\u00e9es et analyse \u00e9conomique")))
  }

  d$titre <- tr(d$titre[[1]])
  shiny::div(class = "hero-graphique",
    shiny::HTML(svg_croissance(d)),
    shiny::div(class = "hero-legende",
      shiny::span(class = "hero-legende-source",
                  sprintf(tr("Source : %s"), d$source[[1]]))))
}

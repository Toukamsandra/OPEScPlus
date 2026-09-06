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
  # Plusieurs codes designent la meme notion selon le fournisseur, et rien ne
  # garantit que le premier soit alimente. Ils sont essayes dans l'ordre de
  # preference, et la premiere serie exploitable est retenue.
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
      # Les vingt dernieres annees : au-dela, les points se serrent au point de
      # rendre la courbe illisible dans une banniere.
      d <- utils::tail(d, 20)
      d$titre <- c_$titre
      d$unite <- c_$unite
      return(d)
    }
  }

  # A defaut de croissance, le produit interieur brut en niveau : mieux vaut
  # une serie de niveau qu'une banniere sans donnee.
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

  points <- paste(sprintf("%.1f,%.1f", px(x), py(y)), collapse = " ")
  cercles <- paste(vapply(seq_along(x), function(i) sprintf(
    '<circle cx="%.1f" cy="%.1f" r="2.4" fill="#0A2F5C"/>',
    px(x[i]), py(y[i])), character(1)), collapse = "")

  # Quelques annees seulement en abscisse : les afficher toutes les ferait se
  # chevaucher.
  pas <- max(1, ceiling(length(x) / 6))
  reperes <- x[seq(1, length(x), by = pas)]
  if (utils::tail(reperes, 1) != max(x)) reperes <- c(reperes, max(x))
  abscisses <- paste(vapply(reperes, function(a) sprintf(
    '<text x="%.1f" y="%.1f" class="g-axe" text-anchor="middle">%d</text>',
    px(a), hauteur - 14, a), character(1)), collapse = "")

  dernier <- length(y)
  paste0(
    sprintf('<svg viewBox="0 0 %d %d" class="g-croissance" role="img"
             xmlns="http://www.w3.org/2000/svg">', largeur, hauteur),
    sprintf('<text x="%.1f" y="24" class="g-titre">%s</text>', marge$g - 9,
            escamoter(d$titre[[1]])),
    sprintf('<text x="%.1f" y="40" class="g-unite">%s</text>', marge$g - 9,
            escamoter(d$unite[[1]])),
    grille,
    sprintf('<polyline points="%s" fill="none" stroke="#0A2F5C"
             stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
            points),
    cercles,
    sprintf('<circle cx="%.1f" cy="%.1f" r="4.2" fill="#CE1126"/>',
            px(x[dernier]), py(y[dernier])),
    sprintf('<text x="%.1f" y="%.1f" class="g-derniere" text-anchor="end">%s</text>',
            largeur - marge$d, py(y[dernier]) - 11, nombre(y[dernier])),
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

# ---------------------------------------------------------------------------
# Exports : classeur xlsx et image PNG.
# ---------------------------------------------------------------------------

#' Classeur a deux feuilles : les donnees et les sources a citer.
#'
#' La feuille des sources n'est pas une formalite : le Growth Lab de Harvard,
#' l'OCDE et le FMI exigent l'attribution, et un fichier qui circule sans sa
#' source devient inexploitable au bout de quelques semaines.
ecrire_classeur <- function(chemin, d, format_large = FALSE) {
  wb <- openxlsx::createWorkbook()
  style_entete <- openxlsx::createStyle(
    fontColour = "#FFFFFF", fgFill = "#0A2F5C", textDecoration = "bold",
    halign = "left", border = "TopBottomLeftRight", wrapText = TRUE)

  donnees <- d[c("pays", "iso3", "libelle", "unite", "frequence",
                 "date_periode", "annee", "valeur", "source")]
  names(donnees) <- c("Pays", "Code pays", "Indicateur", "Unite", "Frequence",
                      "Periode", "Annee", "Valeur", "Source")

  if (format_large) {
    # Une ligne par pays et par periode, une colonne par indicateur : le format
    # attendu par un economiste qui enchaine sur une regression.
    donnees <- stats::reshape(
      d[c("pays", "iso3", "date_periode", "libelle", "valeur")],
      idvar = c("pays", "iso3", "date_periode"), timevar = "libelle",
      direction = "wide")
    names(donnees) <- sub("^valeur\\.", "", names(donnees))
    names(donnees)[1:3] <- c("Pays", "Code pays", "Periode")
  }

  openxlsx::addWorksheet(wb, "Donnees")
  openxlsx::writeData(wb, "Donnees", donnees, headerStyle = style_entete)
  openxlsx::freezePane(wb, "Donnees", firstRow = TRUE)
  openxlsx::setColWidths(wb, "Donnees", seq_along(donnees), widths = "auto")

  sources <- unique(d[c("libelle", "source", "unite")])
  sources$`Date d'extraction` <- format(Sys.Date(), "%d/%m/%Y")
  names(sources)[1:3] <- c("Indicateur", "Source", "Unite")
  openxlsx::addWorksheet(wb, "Sources")
  openxlsx::writeData(wb, "Sources", sources, headerStyle = style_entete)
  openxlsx::setColWidths(wb, "Sources", seq_along(sources), widths = "auto")

  openxlsx::saveWorkbook(wb, chemin, overwrite = TRUE)
  invisible(chemin)
}

#' Image PNG du graphique.
#'
#' On repasse par ggplot2 plutot que par une capture du rendu interactif :
#' l'export d'un graphique plotly demande un moteur externe (kaleido ou
#' webshot) qui alourdit l'installation, alors que ggsave ne depend de rien.
ecrire_image <- function(chemin, g, largeur = 26, hauteur = 14) {
  ggplot2::ggsave(chemin, plot = g, width = largeur, height = hauteur,
                  units = "cm", dpi = 200, bg = "white")
  invisible(chemin)
}

horodatage <- function() format(Sys.time(), "%Y%m%d_%H%M")

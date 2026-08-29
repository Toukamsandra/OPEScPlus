# ---------------------------------------------------------------------------
# Analyse cartographique.
#
# La carte est un aplat de couleur par pays, construit avec plotly. Le choix
# est deliberé : plotly reconnait nativement les codes ISO a trois lettres et
# porte sa propre geometrie du monde. Passer par sf et un fond de carte
# ajouterait deux dependances lourdes, un fichier de formes a distribuer et un
# travail de jointure geographique, pour un resultat visuellement equivalent.
# ---------------------------------------------------------------------------

#' Valeurs d'un indicateur pour tous les pays, une annee donnee
#'
#' Les agregats sont exclus : colorer le monde, la zone euro et les groupes de
#' revenu au milieu des pays rendrait la carte illisible et fausserait l'echelle.
#' @noRd
donnees_carte <- function(con, code_interne, frequence, annee) {
  DBI::dbGetQuery(con, "
    SELECT o.iso3, p.nom AS pays, p.region, o.valeur, o.annee,
           i.libelle, i.unite
    FROM observation o
    JOIN indicateur i ON i.code_interne = o.code_interne
    JOIN pays p ON p.iso3 = o.iso3
    WHERE o.code_interne = ? AND o.frequence = ? AND o.annee = ?
      AND o.valeur IS NOT NULL AND p.est_agregat = 0
    ORDER BY o.valeur DESC",
    params = list(code_interne, frequence, annee))
}

#' Annees pour lesquelles la carte a de la matiere
#' @noRd
annees_carte <- function(con, code_interne, frequence, seuil = 5L) {
  d <- DBI::dbGetQuery(con, "
    SELECT o.annee, COUNT(*) AS n
    FROM observation o JOIN pays p ON p.iso3 = o.iso3
    WHERE o.code_interne = ? AND o.frequence = ? AND o.valeur IS NOT NULL
      AND p.est_agregat = 0
    GROUP BY o.annee HAVING n >= ? ORDER BY o.annee",
    params = list(code_interne, frequence, seuil))
  d$annee
}

#' Trace la carte choropleth
#'
#' @param d tableau renvoye par `donnees_carte()`.
#' @param surligner codes ISO3 des pays selectionnes dans le filtre, entoures
#'   d'un trait plus epais pour rester reperables dans la masse.
#' @noRd
tracer_carte <- function(d, surligner = character(0), id_clic = NULL) {
  if (is.null(d) || !nrow(d)) return(NULL)

  unite <- d$unite[1]
  libelle <- d$libelle[1]

  # Les valeurs extremes ecrasent l'echelle : une poignee de pays a 300 % du
  # PIB rendrait tous les autres de la meme teinte. On borne l'echelle aux
  # centiles 2 et 98, en indiquant la vraie valeur dans l'infobulle.
  bornes <- stats::quantile(d$valeur, c(0.02, 0.98), na.rm = TRUE)

  d$infobulle <- sprintf("%s<br>%s : %s %s", d$pays, libelle,
                         format(round(d$valeur, 2), big.mark = " ", trim = TRUE),
                         if (is.na(unite)) "" else unite)
  d$epaisseur <- ifelse(d$iso3 %in% surligner, 2.2, 0.3)

  p <- plotly::plot_ly(
    d, source = "carte", type = "choropleth", locations = ~iso3, z = ~valeur,
    text = ~infobulle, hoverinfo = "text",
    zmin = bornes[[1]], zmax = bornes[[2]],
    colorscale = list(c(0, "#EEF2F8"), c(0.5, "#5B85C4"), c(1, "#1F3864")),
    marker = list(line = list(color = "#C8A24A", width = ~epaisseur)),
    colorbar = list(title = list(text = if (is.na(unite)) "" else unite,
                                 font = list(size = 11)),
                    thickness = 12, len = 0.7))

  # Le clic est renvoye par un gestionnaire explicite plutot que par
  # `event_data()`. Celui-ci lit un identifiant global, non prefixe par
  # l'espace de noms du module : dans un module Shiny la valeur n'arrivait
  # jamais et le panneau restait sur son invite. Ici l'identifiant est
  # construit avec `ns()`, donc la valeur atteint le bon module.
  if (!is.null(id_clic)) {
    p <- htmlwidgets::onRender(p, sprintf(
      "function(el) {
         el.on('plotly_click', function(e) {
           if (!e.points || !e.points.length) { return; }
           Shiny.setInputValue('%s', e.points[0].location,
                               { priority: 'event' });
         });
       }", id_clic))
  }

  plotly::layout(
    p,
    geo = list(showframe = FALSE, showcoastlines = FALSE,
               showland = TRUE, landcolor = "#F5F7FA",
               projection = list(type = "natural earth"),
               bgcolor = "rgba(0,0,0,0)"),
    margin = list(t = 10, b = 10, l = 0, r = 0),
    paper_bgcolor = "rgba(0,0,0,0)")
}

#' Fiche d'un pays, affichee au clic sur la carte
#'
#' @param iso3 code du pays clique.
#' @param valeur valeur de l'indicateur pour ce pays.
#' @param rang position dans le classement mondial de l'annee.
#' @noRd
fiche_pays <- function(con, iso3, libelle_indicateur, unite, annee,
                       valeur, rang, total) {
  p <- DBI::dbGetQuery(con,
    "SELECT nom, region, groupe_revenu FROM pays WHERE iso3 = ?",
    params = list(iso3))
  if (!nrow(p)) return(NULL)

  extra <- infos_pays(iso3)
  drapeau <- url_drapeau(extra$iso2, 160)

  shiny::div(class = "fiche-pays",
    shiny::div(class = "fiche-drapeau",
      if (nzchar(drapeau)) {
        shiny::img(src = drapeau, alt = p$nom[[1]],
                   onerror = "this.style.display='none'")
      },
      shiny::span(class = "fiche-code", iso3)),
    shiny::div(class = "fiche-corps",
      shiny::h4(p$nom[[1]]),
      shiny::div(class = "fiche-lignes",
        ligne_fiche(tr("Langue officielle"),
                    if (nzchar(extra$langues)) extra$langues else tr("non renseign\u00e9e")),
        ligne_fiche(tr("R\u00e9gion"), if (nzchar(p$region[[1]])) p$region[[1]] else "\u2014"),
        ligne_fiche(tr("Groupe de revenu"),
                    if (nzchar(p$groupe_revenu[[1]])) p$groupe_revenu[[1]] else "\u2014"),
        ligne_fiche(sprintf("%s (%d)", tr(libelle_indicateur), annee),
                    sprintf("%s %s", format(round(valeur, 2), big.mark = "\u202f",
                                            trim = TRUE),
                            if (is.na(unite)) "" else unite)),
        ligne_fiche(tr("Rang mondial"), sprintf(tr("%d sur %d"), rang, total)))))
}

#' @noRd
ligne_fiche <- function(etiquette, valeur) {
  shiny::div(class = "fiche-ligne",
    shiny::span(class = "fiche-etiquette", etiquette),
    shiny::span(class = "fiche-valeur", valeur))
}

# ---------------------------------------------------------------------------
# Construction des graphiques et des exports.
# ---------------------------------------------------------------------------

#' Assemble les series demandees en un tableau long pret a tracer.
#'
#' @param series liste de listes (code_interne, frequence, pays)
assembler <- function(con, series, debut = NULL, fin = NULL) {
  morceaux <- lapply(series, function(s) {
    d <- lire_series(con, s$code_interne, s$frequence, s$pays, debut, fin)
    if (!nrow(d)) return(NULL)
    # Une serie de cours mondial n'a pas de pays : la legende porte alors le
    # seul nom de l'indicateur, sans mention geographique parasite.
    d$serie <- if (d$dimension_pays[1] == 0) d$libelle
               else paste0(d$libelle, " : ", d$pays)
    d
  })
  morceaux <- Filter(Negate(is.null), morceaux)
  if (!length(morceaux)) return(NULL)
  do.call(rbind, morceaux)
}

#' Ramene chaque serie en base 100 a sa premiere observation.
#'
#' Superposer un pourcentage du PIB et un cours en dollars par tonne sur un
#' meme axe ecrase l'un des deux et rend le graphique illisible. La mise en
#' base 100 restitue les evolutions relatives, au prix des niveaux.
en_base_100 <- function(d) {
  parts <- split(d, d$serie)
  parts <- lapply(parts, function(p) {
    p <- p[order(p$date_periode), ]
    reference <- p$valeur[which(!is.na(p$valeur))[1]]
    if (is.na(reference) || reference == 0) return(NULL)
    p$valeur <- 100 * p$valeur / reference
    p
  })
  parts <- Filter(Negate(is.null), parts)
  if (!length(parts)) return(NULL)
  do.call(rbind, parts)
}

unites_distinctes <- function(d) unique(d$unite[!is.na(d$unite) & d$unite != ""])

#' Compose les parts d'un camembert
#'
#' Un camembert represente une repartition a un instant donne, pas une
#' evolution : on ne retient donc qu'une seule periode, la derniere renseignee
#' pour l'ensemble des series affichees.
#' @noRd
parts_camembert <- function(d) {
  if (is.null(d) || !nrow(d)) return(NULL)
  derniere <- max(d$date_periode, na.rm = TRUE)
  parts <- d[d$date_periode == derniere & !is.na(d$valeur), ]
  parts <- parts[parts$valeur > 0, ]
  if (!nrow(parts)) return(NULL)
  parts <- parts[order(-parts$valeur), ]
  parts$part <- 100 * parts$valeur / sum(parts$valeur)
  attr(parts, "periode") <- derniere
  parts
}

#' Un camembert a-t-il un sens pour ces series ?
#'
#' Additionner des parts de PIB de plusieurs pays, ou des indices, ne produit
#' aucun total interpretable : le camembert ne convient qu'aux grandeurs
#' additives exprimees dans la meme unite.
#' @noRd
camembert_pertinent <- function(d) {
  if (is.null(d) || !nrow(d)) return(FALSE)
  unites <- unites_distinctes(d)
  if (length(unites) != 1) return(FALSE)
  !grepl("%|indice|index|score|rang|ann\u00e9e", unites[[1]], ignore.case = TRUE)
}

#' Trace les series. `type` vaut "ligne", "barre", "aire" ou "camembert".
tracer <- function(d, type = "ligne", base100 = FALSE, titre = NULL) {
  if (is.null(d) || !nrow(d)) return(NULL)
  if (base100) {
    d <- en_base_100(d)
    if (is.null(d)) return(NULL)
  }

  unites <- unites_distinctes(d)
  axe_y <- if (base100) "Base 100 a la premiere observation"
           else if (length(unites) == 1) unites else "Unites multiples"

  couleurs <- stats::setNames(
    rep(PALETTE, length.out = length(unique(d$serie))), sort(unique(d$serie)))

  if (type == "camembert") return(tracer_camembert(d))

  g <- ggplot2::ggplot(d, ggplot2::aes(x = date_periode, y = valeur,
                                       colour = serie, fill = serie, group = serie))
  g <- switch(type,
    barre = g + ggplot2::geom_col(position = "dodge", width = 200),
    aire  = g + ggplot2::geom_area(alpha = 0.25, position = "identity") +
                ggplot2::geom_line(linewidth = 0.7),
    # Une serie a trous n'est pas reliee par un trait continu : cela
    # suggererait une evolution qui n'a jamais ete observee.
    g + ggplot2::geom_line(linewidth = 0.8, na.rm = TRUE) +
        ggplot2::geom_point(size = 0.9, na.rm = TRUE))

  g +
    ggplot2::scale_colour_manual(values = couleurs, name = NULL) +
    ggplot2::scale_fill_manual(values = couleurs, name = NULL) +
    ggplot2::scale_x_date(date_labels = "%Y", expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(title = titre, x = NULL, y = axe_y) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.text = ggplot2::element_text(size = 9),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", colour = "#1F3864", size = 13),
      axis.title.y = ggplot2::element_text(size = 9, colour = "#5C6672"))
}

#' Version interactive, pour l'affichage a l'ecran.
tracer_interactif <- function(g, d = NULL, type = "ligne") {
  if (identical(type, "camembert")) return(tracer_camembert_interactif(d))
  if (is.null(g)) return(NULL)
  p <- plotly::ggplotly(g, tooltip = c("x", "y", "colour"))
  plotly::layout(p, legend = list(orientation = "h", y = -0.18),
                 hovermode = "x unified", margin = list(t = 40))
}

#' Camembert, version ggplot pour l'export en image
#' @noRd
tracer_camembert <- function(d) {
  parts <- parts_camembert(d)
  if (is.null(parts)) return(NULL)

  couleurs <- stats::setNames(
    rep(PALETTE, length.out = nrow(parts)), parts$serie)
  parts$etiquette <- sprintf("%s\n%.1f %%", parts$serie, parts$part)

  ggplot2::ggplot(parts, ggplot2::aes(x = "", y = part, fill = serie)) +
    ggplot2::geom_col(width = 1, colour = "white", linewidth = 0.6) +
    ggplot2::coord_polar(theta = "y", start = 0) +
    ggplot2::scale_fill_manual(values = couleurs, name = NULL) +
    ggplot2::labs(
      title = format(attr(parts, "periode"), "%Y"),
      x = NULL, y = NULL) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      legend.position = "right",
      legend.text = ggplot2::element_text(size = 9),
      plot.title = ggplot2::element_text(face = "bold", colour = "#1F3864",
                                         hjust = 0.5, size = 13))
}

#' Camembert interactif
#'
#' Construit directement avec plotly : la conversion d'un `coord_polar` de
#' ggplot donne un rendu degrade, alors que plotly dispose d'un type natif.
#' @noRd
tracer_camembert_interactif <- function(d) {
  parts <- parts_camembert(d)
  if (is.null(parts)) return(NULL)

  couleurs <- rep(PALETTE, length.out = nrow(parts))
  unite <- unites_distinctes(parts)
  p <- plotly::plot_ly(
    parts, type = "pie", labels = ~serie, values = ~valeur,
    marker = list(colors = couleurs, line = list(color = "#FFFFFF", width = 1.5)),
    textinfo = "label+percent", textposition = "auto",
    hovertemplate = paste0("%{label}<br>%{value:,.2f} ",
                           if (length(unite)) unite[[1]] else "",
                           "<br>%{percent}<extra></extra>"),
    sort = TRUE, direction = "clockwise")

  plotly::layout(
    p,
    title = list(text = format(attr(parts, "periode"), "%Y"),
                 font = list(size = 14, color = "#1F3864")),
    legend = list(orientation = "v", x = 1.02, y = 0.5),
    margin = list(t = 46, b = 10))
}

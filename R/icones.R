# ---------------------------------------------------------------------------
# Icones vectorielles, dessinees en ligne.
#
# Elles sont ecrites ici plutot que tirees d'une bibliotheque externe : six
# pictogrammes ne justifient pas une dependance de plus, et un trait uniforme
# vaut mieux qu'un assemblage de styles empruntes.
# ---------------------------------------------------------------------------

#' @noRd
icone <- function(nom, taille = 26) {
  traces <- switch(nom,
    chart = '<path d="M3 3v18h18"/><path d="M7 15l4-5 3 3 5-7"/>',
    layers = '<path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/>',
    globe = paste0('<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>',
                   '<path d="M12 3a14 14 0 000 18a14 14 0 000-18"/>'),
    trend = '<path d="M3 17l5-6 4 3 6-8"/><path d="M14 6h5v5"/>',
    table = paste0('<rect x="3" y="4" width="18" height="16" rx="2"/>',
                   '<path d="M3 10h18M9 10v10"/>'),
    refresh = paste0('<path d="M20 12a8 8 0 11-2.6-5.9"/><path d="M20 4v5h-5"/>'),
    '<circle cx="12" cy="12" r="9"/>')

  shiny::HTML(sprintf(
    '<svg viewBox="0 0 24 24" width="%d" height="%d" fill="none"
      stroke="currentColor" stroke-width="1.7" stroke-linecap="round"
      stroke-linejoin="round" aria-hidden="true">%s</svg>',
    taille, taille, traces))
}

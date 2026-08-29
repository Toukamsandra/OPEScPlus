#!/usr/bin/env Rscript
# Collecte en ligne de commande.
#
#   Rscript inst/scripts/collecter.R --defaut
#   Rscript inst/scripts/collecter.R --categorie C01
#   Rscript inst/scripts/collecter.R --source "Banque mondiale (WDI)"
#   Rscript inst/scripts/collecter.R --debut 1990 --reprendre

if (!requireNamespace("opescplus", quietly = TRUE)) {
  stop("Le paquet opescplus n'est pas installe. Depuis le projet : devtools::load_all()",
       call. = FALSE)
}

args <- commandArgs(TRUE)
valeur <- function(nom, defaut = NULL) {
  i <- match(nom, args)
  if (is.na(i) || i == length(args)) defaut else args[i + 1L]
}

opescplus::collecter_en_lot(
  categorie = valeur("--categorie"),
  source    = valeur("--source"),
  code      = valeur("--code"),
  defaut    = "--defaut" %in% args,
  reprendre = "--reprendre" %in% args,
  debut     = if (!is.null(v <- valeur("--debut"))) as.integer(v) else NULL,
  fin       = if (!is.null(v <- valeur("--fin"))) as.integer(v) else NULL)

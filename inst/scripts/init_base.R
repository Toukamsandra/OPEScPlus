#!/usr/bin/env Rscript
# Cree le schema, charge le catalogue et la liste des pays.
#
#   Rscript -e 'opescplus::preparer_base()'
# ou, depuis une copie du projet :
#   Rscript inst/scripts/init_base.R
#   Rscript inst/scripts/init_base.R --sans-pays

if (!requireNamespace("opescplus", quietly = TRUE)) {
  stop("Le paquet opescplus n'est pas installe. Depuis le projet : devtools::load_all()",
       call. = FALSE)
}

opescplus::preparer_base(avec_pays = !("--sans-pays" %in% commandArgs(TRUE)))

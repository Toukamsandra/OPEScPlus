# ---------------------------------------------------------------------------
# Mise en route. A executer une seule fois, apres avoir clone le projet.
# ---------------------------------------------------------------------------

# 1. Installer les dependances declarees dans DESCRIPTION.
#    remotes::install_deps(dependencies = TRUE)

# 2. Verifier que le paquet se charge.
#    devtools::load_all()

# 3. Creer la base et charger le catalogue.
#    devtools::load_all()
#    con <- connexion()
#    initialiser_base(con)
#    DBI::dbDisconnect(con)

# 4. Premiere collecte, sur les indicateurs proposes d'emblee.
#    source(app_sys("scripts/collecter.R"))   # ou Rscript, voir README

# 5. Lancer.
#    devtools::load_all(); run_app()

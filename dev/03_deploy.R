# ---------------------------------------------------------------------------
# Deploiement.
#
# Point d'attention commun a toutes les cibles : un paquet installe est en
# lecture seule, la base SQLite ne peut donc pas vivre a l'interieur.
# `chemin_base()` la cherche dans cet ordre : variable d'environnement
# OPESC_BASE, cle `base` de golem-config.yml, base livree dans inst/extdata,
# puis dossier de donnees de l'utilisateur.
# ---------------------------------------------------------------------------

# --- Serveur interne, Shiny Server ou Posit Connect ------------------------
# La base vit hors du paquet, dans un dossier accessible en ecriture par le
# compte qui execute l'application. La collecte planifiee tourne a cote, par
# cron, et non depuis l'application.
#
#   Sys.setenv(OPESC_BASE = "/var/opesc/opesc.sqlite")
#   golem::add_dockerfile_with_renv()

# --- shinyapps.io ---------------------------------------------------------
# Le systeme de fichiers y est ephemere et remis a zero a chaque redemarrage :
# une collecte lancee depuis l'application serait perdue. Livrez donc une base
# deja constituee dans inst/extdata/opesc.sqlite. `base_modifiable()` detectera
# la lecture seule et masquera les commandes de collecte.
#
#   file.copy("~/opesc.sqlite", "inst/extdata/opesc.sqlite")
#   rsconnect::deployApp(appName = "opescplus")

# --- Collecte planifiee, a lancer hors de l'application --------------------
# Exemple de ligne cron, tous les jours a 5 h :
#   0 5 * * * OPESC_BASE=/var/opesc/opesc.sqlite \
#     Rscript -e 'opescplus::collecter_en_lot(categorie = NULL)'

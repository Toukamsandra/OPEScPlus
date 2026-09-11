# ---------------------------------------------------------------------------
# Script de collecte hebdomadaire, destine au Planificateur de taches Windows.
#
# Il s'execute sans interface : toute sortie va dans le fichier journal, et
# aucun message n'attend de reponse. Une tache planifiee qui pose une question
# reste bloquee jusqu'a ce que quelqu'un s'en apercoive, parfois des mois.
#
# Adaptez la premiere ligne au dossier du projet, rien d'autre.
# ---------------------------------------------------------------------------

PROJET <- "C:/Users/user/Documents/OPEScGolem_V2/opescplus"

setwd(PROJET)
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)

collecte_hebdomadaire(publier = TRUE, annee_min = 1990)

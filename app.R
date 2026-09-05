# ---------------------------------------------------------------------------
# Point d'entree pour la mise en ligne.
#
# Posit Connect Cloud cherche ce fichier a la racine du depot. Il charge le
# paquet depuis les sources plutot que de l'installer : `opescplus` n'est
# publie sur aucun depot de paquets, et l'hebergeur ne saurait pas ou le
# prendre.
#
# Les appels a `library()` qui suivent ne servent pas au fonctionnement, le
# code etant prefixe par les espaces de noms. Ils servent a `writeManifest()`,
# qui etablit la liste des paquets a installer en lisant ce fichier : sans
# eux, l'hebergeur deploierait une application a laquelle il manquerait tout.
# ---------------------------------------------------------------------------

library(shiny)
library(bslib)
library(DBI)
library(RSQLite)
library(DT)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(openxlsx)
library(httr2)
library(jsonlite)
library(golem)
library(config)
library(pkgload)

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)

options("golem.app.prod" = TRUE)
run_app()

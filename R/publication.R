# ---------------------------------------------------------------------------
# Preparation de la plateforme pour une mise en ligne.
#
# L'hebergeur retenu, Posit Connect Cloud, deploie depuis un depot GitHub
# public. Deux contraintes en decoulent, qui gouvernent tout ce fichier.
#
# La premiere est la taille. GitHub refuse un fichier de plus de cent
# mega-octets, et la base complete en pese plus du double : les codes
# d'indicateur et de pays y sont repetes en toutes lettres sur chaque ligne,
# soit cent cinquante octets par observation. Remplacer ces textes par des
# entiers renvoyant a deux tables de correspondance ramene la ligne a
# trente-quatre octets, et la base sous la barre des cinquante mega-octets.
#
# La seconde est le caractere public du depot. Rien de confidentiel ne doit y
# figurer : ni clef d'interface, ni fichier d'environnement. Ces valeurs se
# declarent dans la console de l'hebergeur.
#
# Le systeme de fichiers du serveur est par ailleurs en lecture seule. La base
# publiee est donc figee : la collecte et l'import restent des operations
# locales, et l'interface masque leurs commandes en ligne.
# ---------------------------------------------------------------------------

#' Prepare une base compacte pour la mise en ligne
#'
#' Recopie la base de travail dans `inst/extdata/opesc.sqlite`, sous une forme
#' allegee : les codes textuels sont remplaces par des entiers, les index
#' accessoires sont abandonnes, et le fichier est compacte.
#'
#' La base ainsi produite est celle que la plateforme utilisera en ligne, sans
#' aucun reglage : `chemin_base()` la trouve avant de se rabattre sur le
#' dossier de l'utilisateur.
#'
#' @param depuis chemin de la base de travail. Par defaut, celle en usage.
#' @param annee_min ne conserver que les observations a partir de cette annee.
#'   NULL pour tout garder. Reduire la profondeur historique est le dernier
#'   recours si la base reste trop lourde.
#' @param limite_mo taille au-dela de laquelle la fonction avertit. Cent
#'   mega-octets est la limite de GitHub ; on s'arrete a quatre-vingt-dix pour
#'   garder une marge.
#'
#' @return chemin de la base produite, de facon invisible.
#'
#' @examples
#' \dontrun{
#' preparer_publication()
#' preparer_publication(annee_min = 1990)
#' }
#' @export
preparer_publication <- function(depuis = NULL, annee_min = NULL,
                                 limite_mo = 90) {
  if (is.null(depuis)) depuis <- chemin_base()
  if (!file.exists(depuis)) {
    stop("Base introuvable : ", depuis, call. = FALSE)
  }

  cible <- file.path("inst", "extdata", "opesc.sqlite")
  if (!dir.exists(dirname(cible))) {
    stop("Lancez cette fonction depuis la racine du projet.", call. = FALSE)
  }

  source <- connexion(depuis)
  on.exit(DBI::dbDisconnect(source), add = TRUE)

  n <- DBI::dbGetQuery(source, "SELECT COUNT(*) AS n FROM observation")$n
  cat(sprintf("Base de travail : %s observations, %.0f Mo.\n",
              format(n, big.mark = "\u202f"), file.size(depuis) / 1024^2))

  if (file.exists(cible)) unlink(cible)
  publiee <- DBI::dbConnect(RSQLite::SQLite(), cible)
  on.exit(DBI::dbDisconnect(publiee), add = TRUE)

  DBI::dbExecute(publiee, "PRAGMA journal_mode = OFF")
  DBI::dbExecute(publiee, "PRAGMA synchronous = OFF")

  cat("Copie des tables de reference...\n")
  # La table des definitions voyage avec les autres : l'oublier laissait
  # l'interface en ligne interroger une table absente, et la recherche
  # s'interrompait sur une erreur.
  for (table in c("categorie", "pays", "indicateur", "journal_collecte",
                  "definition")) {
    if (!DBI::dbExistsTable(source, table)) next
    DBI::dbWriteTable(publiee, table,
                      DBI::dbReadTable(source, table), overwrite = TRUE)
  }

  # Les correspondances entre code textuel et entier. Elles sont conservees
  # dans la base publiee : sans elles, les observations seraient illisibles.
  indicateurs <- DBI::dbGetQuery(source,
    "SELECT DISTINCT code_interne FROM observation ORDER BY code_interne")
  indicateurs$id_indicateur <- seq_len(nrow(indicateurs))
  pays <- DBI::dbGetQuery(source,
    "SELECT DISTINCT iso3 FROM observation ORDER BY iso3")
  pays$id_pays <- seq_len(nrow(pays))

  DBI::dbWriteTable(publiee, "cle_indicateur", indicateurs, overwrite = TRUE)
  DBI::dbWriteTable(publiee, "cle_pays", pays, overwrite = TRUE)

  cat("Transcription des observations...\n")
  DBI::dbExecute(publiee, "
    CREATE TABLE observation_compacte (
      id_indicateur INTEGER NOT NULL,
      id_pays       INTEGER NOT NULL,
      frequence     TEXT NOT NULL,
      date_periode  TEXT NOT NULL,
      annee         INTEGER,
      valeur        REAL,
      PRIMARY KEY (id_indicateur, id_pays, frequence, date_periode)
    ) WITHOUT ROWID")

  # Les observations sont transferees par tranches : tout charger en memoire
  # demanderait plusieurs centaines de mega-octets.
  requete <- "SELECT code_interne, iso3, frequence, date_periode, annee, valeur
              FROM observation"
  if (!is.null(annee_min)) {
    requete <- paste(requete, "WHERE annee >=", as.integer(annee_min))
  }
  resultat <- DBI::dbSendQuery(source, requete)
  ecrites <- 0L
  while (!DBI::dbHasCompleted(resultat)) {
    lot <- DBI::dbFetch(resultat, n = 100000L)
    if (!nrow(lot)) break
    lot$id_indicateur <- indicateurs$id_indicateur[
      match(lot$code_interne, indicateurs$code_interne)]
    lot$id_pays <- pays$id_pays[match(lot$iso3, pays$iso3)]
    DBI::dbAppendTable(publiee, "observation_compacte",
      lot[c("id_indicateur", "id_pays", "frequence", "date_periode",
            "annee", "valeur")])
    ecrites <- ecrites + nrow(lot)
    cat(sprintf("\r  %s observations", format(ecrites, big.mark = "\u202f")))
  }
  DBI::dbClearResult(resultat)
  cat("\n")

  # La vue rend la table compacte transparente : le reste du code interroge
  # `observation` sans savoir comment elle est rangee.
  DBI::dbExecute(publiee, "
    CREATE VIEW observation AS
    SELECT i.code_interne, p.iso3, o.frequence, o.date_periode, o.annee, o.valeur
    FROM observation_compacte o
    JOIN cle_indicateur i ON i.id_indicateur = o.id_indicateur
    JOIN cle_pays p ON p.id_pays = o.id_pays")

  # Index sur les tables de correspondance. La vue joint trois tables a chaque
  # lecture : sans index, chacune est parcourue entierement. L'effet ne se
  # mesure pas sur une base d'essai, ou SQLite s'en sort seul, mais il devient
  # sensible a plusieurs centaines de milliers de lignes.
  DBI::dbExecute(publiee, "
    CREATE INDEX IF NOT EXISTS idx_cle_ind ON cle_indicateur (code_interne)")
  DBI::dbExecute(publiee, "
    CREATE INDEX IF NOT EXISTS idx_cle_pays ON cle_pays (iso3)")
  DBI::dbExecute(publiee, "
    CREATE INDEX IF NOT EXISTS idx_obs_ind
    ON observation_compacte (id_indicateur, frequence, annee)")

  # ANALYZE renseigne le planificateur de requetes sur la distribution des
  # donnees. Sans ces statistiques, il choisit parfois un plan defavorable.
  DBI::dbExecute(publiee, "ANALYZE")
  DBI::dbExecute(publiee, "VACUUM")

  taille <- file.size(cible) / 1024^2
  cat(sprintf("\nBase publiee : %s, %.0f Mo.\n", cible, taille))

  if (taille > limite_mo) {
    cat(sprintf(
      "\nATTENTION : au-dela de %d Mo, GitHub refusera le fichier.\n", limite_mo))
    cat("Relancez en limitant la profondeur, par exemple annee_min = 1990.\n")
  } else {
    cat("Taille compatible avec un depot GitHub.\n")
  }
  invisible(cible)
}

#' Verifie que le projet est pret a etre publie
#'
#' Passe en revue ce que l'hebergeur attend et ce que le depot ne doit pas
#' contenir. A lancer avant le premier envoi.
#'
#' @examples
#' \dontrun{
#' verifier_publication()
#' }
#' @export
verifier_publication <- function() {
  controle <- function(condition, texte, remede = NULL) {
    cat(if (condition) "  [ok]   " else "  [a faire] ", texte, "\n", sep = "")
    if (!condition && !is.null(remede)) cat("           ", remede, "\n", sep = "")
    invisible(condition)
  }

  cat("Fichiers attendus par l'hebergeur\n")
  controle(file.exists("app.R"), "app.R a la racine",
           "il est livre avec le projet ; verifiez que vous etes a la racine")
  controle(file.exists("manifest.json"), "manifest.json",
           "lancez rsconnect::writeManifest()")
  controle(file.exists("DESCRIPTION"), "DESCRIPTION")

  cat("\nDonnees\n")
  base <- file.path("inst", "extdata", "opesc.sqlite")
  presente <- file.exists(base)
  controle(presente, "base publiee dans inst/extdata",
           "lancez preparer_publication()")
  if (presente) {
    taille <- file.size(base) / 1024^2
    controle(taille <= 90,
             sprintf("taille de la base : %.0f Mo", taille),
             "au-dela de 90 Mo, relancez avec annee_min")
  }

  if (presente) {
    con <- connexion(base)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    n <- tryCatch(
      DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM definition")$n,
      error = function(e) 0L)
    controle(n > 0, sprintf("definitions embarquees : %d", n),
             "lancez collecter_definitions() puis preparer_publication()")
  }

  cat("\nSecurite du depot public\n")
  ignore <- if (file.exists(".gitignore")) readLines(".gitignore", warn = FALSE) else character(0)
  controle(any(grepl("^[.]Renviron", ignore)), ".Renviron ecarte du depot",
           "ajoutez .Renviron au fichier .gitignore")
  controle(!file.exists(".Renviron") || any(grepl("^[.]Renviron", ignore)),
           "aucun fichier d'environnement ne partira",
           "vos clefs se declarent dans la console de l'hebergeur")

  cat("\nUne fois en ligne, la base est en lecture seule :\n")
  cat("  la collecte et l'import restent des operations locales.\n")
  invisible(NULL)
}

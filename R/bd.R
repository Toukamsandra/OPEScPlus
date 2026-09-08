# ---------------------------------------------------------------------------
# Acces a la base. SQLite convient jusqu'a quelques millions d'observations ;
# au-dela, basculer sur PostgreSQL en ne changeant que `connexion()`.
# ---------------------------------------------------------------------------

#' Emplacement du fichier de base de donnees
#'
#' Resolu dans cet ordre, du plus explicite au plus general :
#'
#' 1. la variable d'environnement `OPESC_BASE` ;
#' 2. la cle `base` de `inst/golem-config.yml`, selon le profil actif ;
#' 3. une base livree avec le paquet, si elle existe : c'est le cas d'un
#'    deploiement en lecture seule sur shinyapps.io, ou le systeme de fichiers
#'    est ephemere et ou la collecte n'a pas de sens ;
#' 4. a defaut, le dossier de donnees de l'utilisateur, que `tools::R_user_dir`
#'    situe correctement sur Windows, Linux et macOS.
#'
#' @return chemin du fichier SQLite.
#' @export
chemin_base <- function() {
  depuis_env <- Sys.getenv("OPESC_BASE", "")
  if (nzchar(depuis_env)) return(depuis_env)

  depuis_config <- tryCatch(get_golem_config("base"), error = function(e) NULL)
  if (!is.null(depuis_config) && nzchar(depuis_config)) return(depuis_config)

  # La base de travail de l'utilisateur passe avant celle livree avec le
  # paquet. L'ordre inverse avait une consequence facheuse : des lors que
  # `preparer_publication()` avait ecrit la base compacte dans inst/extdata,
  # la plateforme cessait d'utiliser la base locale et travaillait sur la
  # version publiee, ou `observation` est une vue et non une table.
  #
  # Sur le serveur, ce dossier n'existe pas : la base livree est alors la
  # seule, et elle est retenue.
  dossier <- tools::R_user_dir("opescplus", "data")
  locale <- file.path(dossier, "opesc.sqlite")
  if (file.exists(locale)) return(locale)

  embarquee <- app_sys("extdata/opesc.sqlite")
  if (nzchar(embarquee) && file.exists(embarquee)) return(embarquee)

  dir.create(dossier, showWarnings = FALSE, recursive = TRUE)
  locale
}

#' La base est-elle modifiable ?
#'
#' Sert a masquer les commandes de collecte lorsque la plateforme tourne sur un
#' systeme de fichiers en lecture seule. Afficher un bouton qui echouera
#' toujours vaut moins que ne pas l'afficher du tout.
#'
#' @param chemin chemin du fichier SQLite.
#' @export
base_modifiable <- function(chemin = chemin_base()) {
  cible <- if (file.exists(chemin)) chemin else dirname(chemin)
  dir.exists(dirname(chemin)) && file.access(cible, mode = 2) == 0
}

#' Ouvre une connexion a la base
#'
#' @param base chemin du fichier SQLite.
#' @export
connexion <- function(base = chemin_base()) {
  dir.create(dirname(base), showWarnings = FALSE, recursive = TRUE)
  con <- DBI::dbConnect(RSQLite::SQLite(), base)
  # Par defaut SQLite attend la confirmation du disque a chaque transaction, ce
  # qui divise par cinq a dix le debit d'une collecte de plusieurs millions de
  # lignes. WAL autorise en outre la lecture pendant l'ecriture : la plateforme
  # reste consultable pendant une actualisation.
  DBI::dbExecute(con, "PRAGMA journal_mode = WAL;")
  DBI::dbExecute(con, "PRAGMA synchronous = NORMAL;")
  DBI::dbExecute(con, "PRAGMA cache_size = -65536;")
  DBI::dbExecute(con, "PRAGMA temp_store = MEMORY;")
  con
}

creer_schema <- function(con) {
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS categorie (
      code TEXT PRIMARY KEY, libelle TEXT NOT NULL, ordre INTEGER NOT NULL)")

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS pays (
      iso3 TEXT PRIMARY KEY, nom TEXT NOT NULL, region TEXT,
      groupe_revenu TEXT, est_agregat INTEGER NOT NULL DEFAULT 0)")

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS indicateur (
      code_interne   TEXT PRIMARY KEY,
      categorie      TEXT NOT NULL REFERENCES categorie(code),
      secteur        TEXT,
      libelle        TEXT NOT NULL,
      source         TEXT NOT NULL,
      code_source    TEXT NOT NULL,
      frequences     TEXT NOT NULL,
      unite          TEXT,
      dimension_pays INTEGER NOT NULL DEFAULT 1,
      par_defaut     INTEGER NOT NULL DEFAULT 0,
      actif          INTEGER NOT NULL DEFAULT 1,
      derniere_collecte TEXT,
      nb_observations   INTEGER NOT NULL DEFAULT 0)")

  # La frequence fait partie de la cle : une meme serie peut exister en mensuel
  # et en annuel, et les deux doivent cohabiter sans s'ecraser.
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS observation (
      code_interne TEXT NOT NULL REFERENCES indicateur(code_interne),
      iso3         TEXT NOT NULL,
      frequence    TEXT NOT NULL,
      date_periode TEXT NOT NULL,
      annee        INTEGER NOT NULL,
      valeur       REAL,
      PRIMARY KEY (code_interne, iso3, frequence, date_periode))")

  # Sur une base publiee, `observation` est une vue et SQLite refuse de
  # l'indexer. Le schema doit rester applicable aux deux formes : la
  # verification evite une erreur qui interromprait tout le chargement.
  est_table <- nrow(DBI::dbGetQuery(con, "
    SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'observation'")) > 0
  if (est_table) {
    DBI::dbExecute(con, "
      CREATE INDEX IF NOT EXISTS obs_idx
      ON observation (code_interne, frequence, iso3, date_periode)")
    DBI::dbExecute(con, "
      CREATE INDEX IF NOT EXISTS obs_annee ON observation (code_interne, annee)")
  }

  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS journal_collecte (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debut TEXT NOT NULL, fin TEXT, declencheur TEXT, statut TEXT,
      nb_indicateurs INTEGER DEFAULT 0, nb_creees INTEGER DEFAULT 0,
      nb_modifiees INTEGER DEFAULT 0, message TEXT)")

  # Les definitions ne sont pas redigees ici : elles sont recuperees aupres du
  # fournisseur de chaque indicateur, avec son nom. Une definition sans source
  # ne vaut rien dans un document administratif, et en ecrire trois cents
  # soi-meme reviendrait a se substituer aux institutions qui les publient.
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS definition (
      code_interne TEXT PRIMARY KEY,
      texte        TEXT NOT NULL,
      source       TEXT NOT NULL,
      langue       TEXT NOT NULL DEFAULT 'en',
      recuperee    TEXT)")

  # La colonne de langue a ete ajoutee apres coup : une base anterieure ne la
  # possede pas, et SQLite ne sait pas ajouter une colonne conditionnellement.
  colonnes <- DBI::dbGetQuery(con, "PRAGMA table_info(definition)")$name
  if (!"langue" %in% colonnes) {
    DBI::dbExecute(con,
      "ALTER TABLE definition ADD COLUMN langue TEXT NOT NULL DEFAULT 'en'")
  }
  invisible(TRUE)
}

#' Definition d'un indicateur, avec sa source
#' @noRd
lire_definition <- function(con, code_interne) {
  # Une definition est un complement, jamais une condition d'affichage. Si la
  # table manque, parce que la base date d'avant son introduction ou qu'une
  # publication l'a omise, la fonction rend NULL et l'interface poursuit.
  # Interrompre une recherche entiere faute d'une definition serait hors de
  # proportion.
  d <- tryCatch(
    DBI::dbGetQuery(con,
      "SELECT texte, source, langue FROM definition WHERE code_interne = ?",
      params = list(code_interne)),
    error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)
  list(texte = d$texte[[1]], source = d$source[[1]],
       langue = if ("langue" %in% names(d)) d$langue[[1]] else "en")
}

# --- lectures --------------------------------------------------------------

lire_categories <- function(con) {
  DBI::dbGetQuery(con, "
    SELECT c.code, c.libelle, c.ordre,
           COUNT(i.code_interne) AS nb,
           SUM(CASE WHEN i.nb_observations > 0 THEN 1 ELSE 0 END) AS collectes
    FROM categorie c
    LEFT JOIN indicateur i ON i.categorie = c.code AND i.actif = 1
    GROUP BY c.code, c.libelle, c.ordre
    ORDER BY c.ordre")
}

lire_indicateurs <- function(con, categorie = NULL) {
  if (is.null(categorie)) {
    DBI::dbGetQuery(con, "SELECT * FROM indicateur WHERE actif = 1 ORDER BY libelle")
  } else {
    DBI::dbGetQuery(con,
      "SELECT * FROM indicateur WHERE actif = 1 AND categorie = ? ORDER BY libelle",
      params = list(categorie))
  }
}

lire_pays <- function(con, avec_agregats = TRUE) {
  requete <- "SELECT iso3, nom, region, groupe_revenu, est_agregat FROM pays"
  if (!avec_agregats) requete <- paste(requete, "WHERE est_agregat = 0")
  DBI::dbGetQuery(con, paste(requete, "ORDER BY est_agregat, nom"))
}

#' Frequences reellement disponibles pour un indicateur.
#'
#' On interroge les observations plutot que la colonne `frequences` du
#' catalogue : celle-ci decrit ce que la source publie en theorie, la base dit
#' ce qui a ete effectivement collecte. Proposer un pas absent de la base
#' produirait un graphique vide sans explication.
frequences_disponibles <- function(con, code_interne) {
  if (!length(code_interne)) return(character(0))
  marques <- paste(rep("?", length(code_interne)), collapse = ",")
  reelles <- DBI::dbGetQuery(con, sprintf(
    "SELECT DISTINCT frequence FROM observation WHERE code_interne IN (%s)", marques),
    params = as.list(code_interne))$frequence

  if (length(reelles)) return(reelles)

  # Base pas encore collectee : on retombe sur ce que le catalogue annonce.
  declarees <- DBI::dbGetQuery(con, sprintf(
    "SELECT frequences FROM indicateur WHERE code_interne IN (%s)", marques),
    params = as.list(code_interne))$frequences
  unique(unlist(strsplit(declarees, ",", fixed = TRUE)))
}

#' Bornes temporelles reellement couvertes, pour caler les selecteurs de date.
etendue_periode <- function(con, code_interne, frequence) {
  if (!length(code_interne)) return(NULL)
  marques <- paste(rep("?", length(code_interne)), collapse = ",")
  r <- DBI::dbGetQuery(con, sprintf(
    "SELECT MIN(date_periode) AS mini, MAX(date_periode) AS maxi
     FROM observation WHERE code_interne IN (%s) AND frequence = ?", marques),
    params = c(as.list(code_interne), list(frequence)))
  if (is.na(r$mini[1])) return(NULL)
  list(min = as.Date(r$mini[1]), max = as.Date(r$maxi[1]))
}

lire_series <- function(con, code_interne, frequence, iso3 = NULL,
                        debut = NULL, fin = NULL) {
  requete <- "
    SELECT o.code_interne, o.iso3, o.frequence, o.date_periode, o.annee, o.valeur,
           i.libelle, i.unite, i.source, i.categorie, i.dimension_pays,
           COALESCE(p.nom, o.iso3) AS pays
    FROM observation o
    JOIN indicateur i ON i.code_interne = o.code_interne
    LEFT JOIN pays p ON p.iso3 = o.iso3
    WHERE o.code_interne = ? AND o.frequence = ? AND o.valeur IS NOT NULL"
  args <- list(code_interne, frequence)

  if (length(iso3)) {
    requete <- paste0(requete, " AND o.iso3 IN (",
                      paste(rep("?", length(iso3)), collapse = ","), ")")
    args <- c(args, as.list(iso3))
  }
  if (!is.null(debut)) { requete <- paste(requete, "AND o.date_periode >= ?"); args <- c(args, list(as.character(debut))) }
  if (!is.null(fin))   { requete <- paste(requete, "AND o.date_periode <= ?"); args <- c(args, list(as.character(fin))) }

  d <- DBI::dbGetQuery(con, paste(requete, "ORDER BY o.iso3, o.date_periode"),
                       params = args)
  if (nrow(d)) d$date_periode <- as.Date(d$date_periode)
  d
}

lire_journal <- function(con, n = 60) {
  DBI::dbGetQuery(con,
    "SELECT * FROM journal_collecte ORDER BY id DESC LIMIT ?", params = list(n))
}

#' Etat des frequences reellement presentes en base
#'
#' Repond a la question « pourquoi tout est-il annuel ? ». Tant qu'aucune
#' source infra-annuelle n'a ete collectee, le filtre de frequence n'a rien
#' d'autre a proposer : ce n'est pas un defaut du filtre.
#'
#' @examples
#' \dontrun{
#' diagnostic_frequences()
#' }
#' @export
diagnostic_frequences <- function() {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  d <- DBI::dbGetQuery(con, "
    SELECT o.frequence,
           COUNT(*) AS observations,
           COUNT(DISTINCT o.code_interne) AS indicateurs
    FROM observation o GROUP BY o.frequence ORDER BY observations DESC")
  if (!nrow(d)) {
    message("Aucune observation en base. Lancez d'abord une collecte.")
    return(invisible(NULL))
  }
  d$frequence <- libelle_frequence(d$frequence)

  attendus <- DBI::dbGetQuery(con, "
    SELECT frequences, COUNT(*) AS indicateurs
    FROM indicateur WHERE actif = 1 GROUP BY frequences ORDER BY indicateurs DESC")

  cat("Frequences presentes en base :\n")
  print(d, row.names = FALSE)
  cat("\nFrequences annoncees par le catalogue :\n")
  print(attendus, row.names = FALSE)
  cat("\nSeules les matieres premieres (categorie C15) sont publiees en mensuel.",
      "\nSi elles ne sont pas collectees, tout le reste est annuel par nature :",
      "\nla Banque mondiale ne publie que de l'annuel.\n")
  invisible(d)
}

#' Nombre d'indicateurs actifs
#'
#' Compte lu en base a chaque appel. Ecrire ce chiffre dans un texte le rend
#' faux des la premiere evolution du catalogue, sans que rien ne le signale.
#' @noRd
n_indicateurs <- function(con) {
  DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM indicateur WHERE actif = 1")$n
}

#' Nombre de categories portant au moins un indicateur actif
#' @noRd
n_categories <- function(con) {
  DBI::dbGetQuery(con, "
    SELECT COUNT(DISTINCT categorie) AS n FROM indicateur WHERE actif = 1")$n
}

#' Etat complet de la plateforme
#'
#' Une seule commande pour repondre a la question qui revient : pourquoi
#' l'ecran est-il vide ? Elle dit quelle base est ouverte, ce qu'elle contient,
#' et si l'indicateur affiche au chargement y figure.
#'
#' @examples
#' \dontrun{
#' diagnostic_plateforme()
#' }
#' @export
diagnostic_plateforme <- function() {
  chemin <- chemin_base()
  cat("Base ouverte :", chemin, "\n")
  if (!file.exists(chemin)) {
    cat("\nCe fichier n'existe pas. Lancez preparer_base().\n")
    return(invisible(FALSE))
  }
  cat(sprintf("Taille : %.0f Mo\n", file.size(chemin) / 1024^2))

  con <- connexion(chemin)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  tables <- DBI::dbListTables(con)
  attendues <- c("categorie", "pays", "indicateur", "observation")
  manquantes <- setdiff(attendues, tables)
  if (length(manquantes)) {
    cat("\nTables manquantes :", paste(manquantes, collapse = ", "), "\n")
    cat("Lancez preparer_base().\n")
    return(invisible(FALSE))
  }

  n <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM observation")$n
  cat(sprintf("\nObservations en base : %s\n", format(n, big.mark = "\u202f")))
  if (n == 0) {
    cat("La base est vide. Lancez collecter_manquants().\n")
    return(invisible(FALSE))
  }

  d <- DBI::dbGetQuery(con, "
    SELECT c.code, c.libelle,
           COUNT(i.code_interne) AS indicateurs,
           SUM(CASE WHEN i.nb_observations > 0 THEN 1 ELSE 0 END) AS avec_donnees
    FROM categorie c
    LEFT JOIN indicateur i ON i.categorie = c.code AND i.actif = 1
    GROUP BY c.code, c.libelle, c.ordre ORDER BY c.ordre")
  cat("\nPar categorie :\n")
  for (i in seq_len(nrow(d))) {
    cat(sprintf("  %-4s %-44s %3d / %3d\n", d$code[[i]],
                substr(d$libelle[[i]], 1, 44),
                d$avec_donnees[[i]], d$indicateurs[[i]]))
  }

  # L'indicateur affiche au chargement du tableau de bord.
  cat("\nIndicateur de depart :\n")
  for (code in c("NY.GDP.PCAP.KD.ZG", "NY.GDP.MKTP.KD.ZG")) {
    ind <- DBI::dbGetQuery(con, "
      SELECT code_interne, categorie, actif, nb_observations FROM indicateur
      WHERE code_source = ?", params = list(code))
    if (!nrow(ind)) { cat(sprintf("  %-20s absent du catalogue\n", code)); next }
    pour_cmr <- DBI::dbGetQuery(con, "
      SELECT COUNT(*) AS n FROM observation
      WHERE code_interne = ? AND iso3 = 'CMR' AND frequence = 'A'",
      params = list(ind$code_interne[[1]]))$n
    cat(sprintf("  %-20s categorie %s, %d observations dont %d pour le Cameroun\n",
                code, ind$categorie[[1]], ind$nb_observations[[1]], pour_cmr))
  }

  compteurs <- DBI::dbGetQuery(con, "
    SELECT COUNT(*) AS n FROM indicateur
    WHERE actif = 1 AND nb_observations = 0
      AND code_interne IN (SELECT DISTINCT code_interne FROM observation)")$n
  if (compteurs > 0) {
    cat(sprintf("\n%d indicateurs portent des observations mais affichent un compteur a zero.\n",
                compteurs))
    cat("Lancez rafraichir_compteurs().\n")
  }
  invisible(TRUE)
}

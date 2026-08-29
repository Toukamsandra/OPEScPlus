# ---------------------------------------------------------------------------
# Moteur de collecte.
# ---------------------------------------------------------------------------

#' Collecte un indicateur et l'ecrit en base.
#' @return liste (creees, modifiees)
collecter_indicateur <- function(con, ligne, debut = NULL, fin = NULL) {
  f <- connecteur_pour(ligne$source)
  d <- f(ligne$code_source, debut, fin)
  unite_source <- attr(d, "unite")

  if (!nrow(d)) return(list(creees = 0L, modifiees = 0L))

  # Les valeurs absentes ne sont pas stockees. L'API renvoie une ligne pour
  # chaque couple pays-periode meme quand il n'y a pas de donnee : sur un
  # indicateur a faible couverture, cela represente plus de quatre-vingt-dix
  # pour cent du volume pour aucune information. L'absence de ligne vaut
  # absence de donnee, ce que le graphique sait deja representer.
  d <- d[!is.na(d$valeur) & !is.na(d$date_periode) & !is.na(d$frequence), ]
  if (!nrow(d)) return(list(creees = 0L, modifiees = 0L))

  # Un cours mondial n'a pas de pays. Le flux WEO le renvoie pourtant sous un
  # code geographique, parfois repete a l'identique pour plusieurs economies :
  # on le range sous WLD et on ne garde qu'une observation par periode, sans
  # quoi la cle primaire serait violee et la serie dupliquee.
  if (isTRUE(ligne$dimension_pays == 0)) d$iso3 <- "WLD"

  # Les codes pays inconnus sont ecartes plutot que crees a la volee : une
  # entree fantome fabriquerait un pays sans region ni groupe de revenu, donc
  # invisible dans les filtres.
  connus <- DBI::dbGetQuery(con, "SELECT iso3 FROM pays")$iso3
  d <- d[d$iso3 %in% connus, ]
  if (!nrow(d)) return(list(creees = 0L, modifiees = 0L))

  d$code_interne <- ligne$code_interne
  d$annee <- as.integer(format(d$date_periode, "%Y"))
  d$date_periode <- format(d$date_periode, "%Y-%m-%d")
  d <- d[!duplicated(d[c("code_interne", "iso3", "frequence", "date_periode")]), ]

  avant <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) AS n FROM observation WHERE code_interne = ?",
    params = list(ligne$code_interne))$n

  DBI::dbWithTransaction(con, {
    # Table temporaire puis fusion : bien plus rapide qu'une boucle de UPSERT
    # ligne a ligne, et le compte des creations reste exact.
    DBI::dbWriteTable(con, "obs_tmp",
      d[c("code_interne", "iso3", "frequence", "date_periode", "annee", "valeur")],
      temporary = TRUE, overwrite = TRUE)
    DBI::dbExecute(con, "
      INSERT INTO observation (code_interne, iso3, frequence, date_periode, annee, valeur)
      SELECT code_interne, iso3, frequence, date_periode, annee, valeur FROM obs_tmp
      WHERE 1
      ON CONFLICT (code_interne, iso3, frequence, date_periode)
      DO UPDATE SET valeur = excluded.valeur")
    DBI::dbExecute(con, "DROP TABLE IF EXISTS obs_tmp")
  })

  apres <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) AS n FROM observation WHERE code_interne = ?",
    params = list(ligne$code_interne))$n

  DBI::dbExecute(con, "
    UPDATE indicateur SET derniere_collecte = ?, nb_observations = ?
    WHERE code_interne = ?",
    params = list(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), apres, ligne$code_interne))

  # Certains connecteurs lisent l'unite dans la source elle-meme. Elle fait
  # alors autorite sur celle du catalogue : les nomenclatures n'expriment pas
  # les memes cours dans les memes unites, et une unite fausse sur un axe est
  # pire qu'une unite absente.
  unite <- unite_source
  if (!is.null(unite) && nzchar(unite) && !identical(unite, ligne$unite)) {
    DBI::dbExecute(con, "UPDATE indicateur SET unite = ? WHERE code_interne = ?",
                   params = list(unite, ligne$code_interne))
  }

  creees <- as.integer(apres - avant)
  list(creees = creees, modifiees = as.integer(nrow(d) - creees))
}

#' Collecte un ensemble d'indicateurs en journalisant l'execution.
#'
#' @param avancement fonction optionnelle (rang, total, libelle, erreur), pour
#'   afficher une progression sans que le moteur connaisse la console ni Shiny.
#' @export
collecter <- function(con, indicateurs, declencheur = "manuel",
                      debut = NULL, fin = NULL, avancement = NULL) {
  if (!nrow(indicateurs)) {
    return(list(creees = 0L, modifiees = 0L, erreurs = character(0), statut = "vide"))
  }

  DBI::dbExecute(con, "
    INSERT INTO journal_collecte (debut, declencheur, statut, nb_indicateurs)
    VALUES (?, ?, 'en cours', ?)",
    params = list(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), declencheur, nrow(indicateurs)))
  id <- DBI::dbGetQuery(con, "SELECT last_insert_rowid() AS id")$id

  creees <- 0L; modifiees <- 0L; erreurs <- character(0)
  for (i in seq_len(nrow(indicateurs))) {
    ligne <- indicateurs[i, ]
    message_erreur <- NULL
    res <- tryCatch(collecter_indicateur(con, ligne, debut, fin),
                    error = function(e) {
                      # Une source en panne ne doit pas arreter les autres.
                      message_erreur <<- conditionMessage(e)
                      NULL
                    })
    if (is.null(res)) {
      erreurs <- c(erreurs, sprintf("%s : %s", ligne$code_source, message_erreur))
    } else {
      creees <- creees + res$creees; modifiees <- modifiees + res$modifiees
    }
    if (is.function(avancement)) avancement(i, nrow(indicateurs), ligne$libelle, message_erreur)
  }

  statut <- if (!length(erreurs)) "termine"
            else if (length(erreurs) < nrow(indicateurs)) "termine avec erreurs"
            else "echec"

  DBI::dbExecute(con, "
    UPDATE journal_collecte SET fin = ?, statut = ?, nb_creees = ?,
      nb_modifiees = ?, message = ? WHERE id = ?",
    params = list(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), statut,
                  creees, modifiees,
                  paste(utils::head(erreurs, 50), collapse = "\n"), id))

  list(creees = creees, modifiees = modifiees, erreurs = erreurs, statut = statut)
}

# Codes dont la collecte a echoue lors de la recette et dont la correction
# demande une verification aupres du fournisseur. Ils sont desactives au
# chargement plutot que laisses visibles et muets dans l'interface.
#
#   avg_distance, diversity, avg_ubiquity, eci_rank, growth_proj
#       noms de champs GraphQL refuses par l'Atlas (HTTP 400).
#       explorer_champs_atlas() donne la liste exacte.
#   pci, country_product_year
#       ne sont pas des champs de countryYear : le premier decrit un produit,
#       le second un couple pays-produit. Ils demandent une autre requete et
#       une autre table, hors du schema actuel.
NON_VALIDES <- c("avg_distance", "diversity", "avg_ubiquity", "eci_rank",
                 "growth_proj", "pci", "country_product_year")

#' Charge le catalogue et la liste des pays
#'
#' @param con connexion ouverte.
#' @param avec_pays recharger aussi la liste des pays depuis la Banque mondiale.
#' @export
initialiser_base <- function(con, avec_pays = TRUE) {
  creer_schema(con)

  # Les deux fichiers sont livres avec le paquet, dans inst/extdata.
  categories <- utils::read.csv(app_sys("extdata/categories.csv"),
                                stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  catalogue <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                               stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")

  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "DELETE FROM categorie")
    DBI::dbAppendTable(con, "categorie", categories)

    ancien <- DBI::dbGetQuery(con,
      "SELECT code_interne, derniere_collecte, nb_observations FROM indicateur")

    # Six fournisseurs figurent au catalogue sans connecteur ecrit a ce jour :
    # CNUCED, FAO, OIT, PNUD, OEC et Transparency International. Leurs
    # indicateurs sont desactives plutot que laisses visibles : sans cela ils
    # apparaitraient dans les listes du tableau de bord et ne renverraient
    # jamais rien, ce qui ressemble a une panne. Ils se reactiveront d'eux-memes
    # le jour ou le connecteur correspondant sera ajoute au registre.
    catalogue$actif <- as.integer(catalogue$source %in% names(REGISTRE) &
                                 !catalogue$code_source %in% NON_VALIDES)
    catalogue$derniere_collecte <- NA_character_
    catalogue$nb_observations <- 0L
    if (nrow(ancien)) {
      # Un rechargement du catalogue ne doit pas effacer l'historique de collecte.
      i <- match(catalogue$code_interne, ancien$code_interne)
      ok <- !is.na(i)
      catalogue$derniere_collecte[ok] <- ancien$derniere_collecte[i[ok]]
      catalogue$nb_observations[ok] <- ancien$nb_observations[i[ok]]
    }
    DBI::dbExecute(con, "DELETE FROM indicateur")
    DBI::dbAppendTable(con, "indicateur", catalogue)
  })

  inactifs <- catalogue[catalogue$actif == 0, ]
  if (nrow(inactifs)) {
    sans_connecteur <- inactifs[!inactifs$source %in% names(REGISTRE), ]
    non_valides <- inactifs[inactifs$code_source %in% NON_VALIDES, ]
    if (nrow(sans_connecteur)) {
      message(sprintf("%d indicateurs desactives, faute de connecteur pour : %s",
                      nrow(sans_connecteur),
                      paste(sort(unique(sans_connecteur$source)), collapse = ", ")))
    }
    if (nrow(non_valides)) {
      message(sprintf("%d indicateurs desactives, code non valide a la recette : %s",
                      nrow(non_valides),
                      paste(sort(non_valides$code_source), collapse = ", ")))
    }
  }

  if (avec_pays) charger_pays(con)
  invisible(nrow(catalogue) - nrow(inactifs))
}

#' La liste des pays vient de l'API de la Banque mondiale, qui fournit region,
#' groupe de revenu et code ISO en un seul appel.
charger_pays <- function(con) {
  corps <- jsonlite::fromJSON(
    httr2::resp_body_string(appel("https://api.worldbank.org/v2/country",
                                  list(format = "json", per_page = 400))),
    simplifyVector = TRUE)
  d <- corps[[2]]
  region <- d$region$value
  pays <- data.frame(
    iso3 = toupper(trimws(d$id)),
    nom = d$name,
    region = ifelse(is.na(region), "", region),
    groupe_revenu = ifelse(is.na(d$incomeLevel$value), "", d$incomeLevel$value),
    # La Banque mondiale renvoie "Aggregates" pour ses regroupements. Les
    # marquer evite qu'un classement de pays place le monde en tete.
    est_agregat = as.integer(is.na(region) | region %in% c("", "Aggregates")),
    stringsAsFactors = FALSE)
  pays <- pays[nchar(pays$iso3) == 3, ]

  # Entite technique portant les cours mondiaux de matieres premieres, qui
  # n'ont pas de dimension pays.
  if (!"WLD" %in% pays$iso3) {
    pays <- rbind(pays, data.frame(iso3 = "WLD", nom = "Monde", region = "",
                                   groupe_revenu = "", est_agregat = 1L,
                                   stringsAsFactors = FALSE))
  }
  DBI::dbWithTransaction(con, {
    DBI::dbExecute(con, "DELETE FROM pays")
    DBI::dbAppendTable(con, "pays", pays)
  })
  invisible(nrow(pays))
}

#' Collecte en lot, avec avancement a l'ecran
#'
#' Enveloppe de [collecter()] destinee a la ligne de commande et aux taches
#' planifiees. La logique vit dans le paquet, le script d'appel n'est qu'une
#' facade : c'est ce qui permet de la tester et de l'appeler aussi bien depuis
#' cron que depuis une console R.
#'
#' @param categorie code de categorie, par exemple `"C01"`.
#' @param source libelle exact de la source, par exemple `"Banque mondiale (WDI)"`.
#' @param code code de collecte d'un indicateur precis.
#' @param defaut limiter aux indicateurs proposes d'emblee.
#' @param reprendre sauter les indicateurs deja collectes.
#' @param debut,fin bornes d'annees transmises aux connecteurs.
#' @param silencieux ne rien afficher, pour un appel planifie.
#'
#' @return la liste renvoyee par [collecter()], de facon invisible.
#' @export
collecter_en_lot <- function(categorie = NULL, source = NULL, code = NULL,
                             defaut = FALSE, reprendre = FALSE,
                             debut = NULL, fin = NULL, silencieux = FALSE) {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  d <- lire_indicateurs(con)
  if (!is.null(categorie)) d <- d[d$categorie == categorie, ]
  if (!is.null(source))    d <- d[d$source == source, ]
  if (!is.null(code))      d <- d[d$code_source == code, ]
  if (isTRUE(defaut))      d <- d[d$par_defaut == 1, ]
  if (isTRUE(reprendre))   d <- d[is.na(d$derniere_collecte), ]

  if (!nrow(d)) {
    if (!silencieux) cat("Aucun indicateur ne correspond aux criteres.\n")
    return(invisible(NULL))
  }
  if (!silencieux) cat(sprintf("%d indicateurs a collecter.\n\n", nrow(d)))

  depart <- Sys.time()
  avancement <- if (silencieux) NULL else function(i, n, libelle, erreur) {
    ecoule <- as.numeric(difftime(Sys.time(), depart, units = "secs"))
    entete <- sprintf("[%3d/%d] %s (reste ~%s)", i, n,
                      format(.POSIXct(ecoule, tz = "UTC"), "%H:%M:%S"),
                      format(.POSIXct(ecoule / i * (n - i), tz = "UTC"), "%H:%M:%S"))
    if (is.null(erreur)) {
      cat(sprintf("%s  %s\n", entete, substr(libelle, 1, 55)))
    } else {
      cat(sprintf("%s  %s  ECHEC : %s\n", entete, substr(libelle, 1, 40),
                  substr(erreur, 1, 90)))
    }
  }

  res <- collecter(con, d, declencheur = "commande", debut = debut, fin = fin,
                   avancement = avancement)

  if (!silencieux) {
    cat(sprintf("\nTermine (%s) : %d valeurs ajoutees, %d revisees.\n",
                res$statut, res$creees, res$modifiees))
    if (length(res$erreurs)) {
      cat("\nErreurs :\n", paste(res$erreurs, collapse = "\n"), "\n", sep = "")
    }
  }
  invisible(res)
}

#' Prepare une base neuve
#'
#' Cree le schema, charge le catalogue et la liste des pays. Enveloppe destinee
#' a l'appel depuis un script ou une console.
#'
#' @param avec_pays recharger la liste des pays depuis la Banque mondiale.
#' @export
preparer_base <- function(avec_pays = TRUE) {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  n <- initialiser_base(con, avec_pays = avec_pays)
  cat(sprintf("%d indicateurs actifs charges dans %s\n", n, chemin_base()))
  cat(sprintf("%d entites geographiques\n",
              DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM pays")$n))
  invisible(n)
}

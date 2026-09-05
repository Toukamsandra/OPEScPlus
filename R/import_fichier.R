# ---------------------------------------------------------------------------
# Import d'un fichier telecharge a la main.
#
# Six tentatives automatiques ont echoue sur les cours de produits de base, et
# le bouton de telechargement du portail est pilote par du JavaScript : son
# adresse n'apparait pas dans la page. Cette voie contourne le probleme.
#
# Vous telechargez le fichier une fois depuis
# https://data.imf.org/en/datasets/IMF.RES:PCPS, bouton DOWNLOAD, puis vous
# le passez a `importer_produits_de_base()`. La lecture est volontairement
# tolerante : elle repere les colonnes par leur contenu et non par leur nom,
# de facon a accepter aussi bien un export du FMI qu'un classeur Pink Sheet.
# ---------------------------------------------------------------------------

#' Lit un fichier de donnees, quel que soit son format
#' @noRd
lire_fichier <- function(chemin) {
  if (!file.exists(chemin)) {
    stop("Fichier introuvable : ", chemin, call. = FALSE)
  }
  ext <- tolower(tools::file_ext(chemin))

  if (ext %in% c("xlsx", "xlsm", "xls")) {
    feuilles <- openxlsx::getSheetNames(chemin)
    # On garde la feuille qui contient le plus de lignes exploitables.
    meilleure <- NULL
    for (f in feuilles) {
      d <- tryCatch(openxlsx::read.xlsx(chemin, sheet = f, colNames = FALSE,
                                        skipEmptyRows = FALSE),
                    error = function(e) NULL)
      if (!is.null(d) && (is.null(meilleure) || nrow(d) > nrow(meilleure))) {
        meilleure <- d
      }
    }
    return(meilleure)
  }

  # CSV : le separateur varie selon la provenance du fichier.
  for (sep in c(",", ";", "\t")) {
    d <- tryCatch(utils::read.csv(chemin, sep = sep, stringsAsFactors = FALSE,
                                  check.names = FALSE, header = TRUE),
                  error = function(e) NULL)
    if (!is.null(d) && ncol(d) > 2) return(d)
  }
  stop("Format non reconnu : ", chemin, call. = FALSE)
}

#' Repere une colonne par le contenu de ses valeurs
#' @noRd
colonne_par_contenu <- function(d, motif, proportion = 0.5) {
  scores <- vapply(d, function(x) {
    v <- trimws(as.character(x))
    v <- v[!is.na(v) & nzchar(v)]
    if (!length(v)) return(0)
    mean(grepl(motif, v))
  }, numeric(1))
  if (max(scores) < proportion) return(NA_character_)
  names(d)[[which.max(scores)]]
}

#' Importe les cours de produits de base depuis un fichier telecharge
#'
#' Telechargez le fichier depuis la page du jeu de donnees PCPS
#' (https://data.imf.org/en/datasets/IMF.RES:PCPS, bouton DOWNLOAD), puis
#' passez son chemin a cette fonction. Elle repere seule les colonnes de
#' produit, de periode et de valeur, puis ecrit en base les indicateurs du
#' catalogue qu'elle y trouve.
#'
#' @param chemin chemin du fichier telecharge, csv ou xlsx.
#' @param apercu si TRUE, n'ecrit rien et se contente d'afficher ce qui serait
#'   importe. A utiliser au premier essai.
#'
#' @return de facon invisible, le nombre d'observations ecrites.
#'
#' @examples
#' \dontrun{
#' importer_produits_de_base("C:/Users/user/Downloads/PCPS.csv", apercu = TRUE)
#' importer_produits_de_base("C:/Users/user/Downloads/PCPS.csv")
#' }
#' @export
importer_produits_de_base <- function(chemin, apercu = FALSE) {
  d <- lire_fichier(chemin)
  if (is.null(d) || !nrow(d)) stop("Fichier vide.", call. = FALSE)

  # Certains exports placent les vrais en-tetes plus bas. On cherche alors la
  # ligne qui porte le plus de codes de produit et on l'utilise comme en-tete.
  if (is.na(colonne_par_contenu(d, "^P[A-Z]{2,}", 0.3))) {
    hauteur <- min(30L, nrow(d))
    scores <- vapply(seq_len(hauteur), function(i) {
      sum(grepl("^P[A-Z]{2,}", trimws(as.character(unlist(d[i, ])))))
    }, integer(1))
    if (max(scores) >= 3L) {
      h <- which.max(scores)
      entetes <- trimws(as.character(unlist(d[h, ])))
      d <- d[seq.int(h + 1L, nrow(d)), , drop = FALSE]
      names(d) <- ifelse(is.na(entetes) | !nzchar(entetes),
                         paste0("col", seq_along(entetes)), entetes)
    }
  }

  col_produit <- colonne_par_contenu(d, "^P[A-Z]{2,}", 0.3)
  col_periode <- colonne_par_contenu(d, "^\\d{4}([-]?[MmQq]?\\d{0,2})?$", 0.6)
  col_valeur <- colonne_par_contenu(d, "^-?[0-9][0-9.,eE+-]*$", 0.6)

  if (is.na(col_produit) || is.na(col_periode) || is.na(col_valeur)) {
    stop("Colonnes non reconnues. Produit : ", col_produit,
         ", periode : ", col_periode, ", valeur : ", col_valeur,
         ". Colonnes du fichier : ", paste(names(d), collapse = ", "),
         call. = FALSE)
  }

  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  catalogue <- DBI::dbGetQuery(con,
    "SELECT code_interne, code_source, libelle FROM indicateur
     WHERE categorie = 'C01'")

  col_transfo <- intersect(c("DATA_TRANSFORMATION", "UNIT_MEASURE", "UNIT",
                             "TRANSFORMATION"), names(d))

  total <- 0L; trouves <- character(0); absents <- character(0)
  for (i in seq_len(nrow(catalogue))) {
    code <- catalogue$code_source[[i]]
    part <- d[as.character(d[[col_produit]]) == code, , drop = FALSE]
    if (!nrow(part)) { absents <- c(absents, code); next }

    # Une seule transformation, sans quoi un niveau de prix et un taux de
    # variation se retrouveraient dans la meme serie.
    if (length(col_transfo)) {
      modalites <- table(as.character(part[[col_transfo[[1]]]]))
      if (length(modalites) > 1) {
        part <- part[as.character(part[[col_transfo[[1]]]]) ==
                       names(which.max(modalites)), , drop = FALSE]
      }
    }

    periodes <- trimws(as.character(part[[col_periode]]))
    dates <- periodes_vers_dates(periodes)
    r <- data.frame(
      iso3 = "WLD", date_periode = dates$date_periode,
      frequence = dates$frequence,
      valeur = suppressWarnings(as.numeric(
        gsub("[^0-9.eE+-]", "", as.character(part[[col_valeur]])))),
      stringsAsFactors = FALSE)
    r <- r[!is.na(r$date_periode) & !is.na(r$valeur), ]
    r <- r[!duplicated(r[c("frequence", "date_periode")]), ]
    if (!nrow(r)) { absents <- c(absents, code); next }
    if (nrow(r)) r <- rbind(r, agreger_en_annuel(r))

    trouves <- c(trouves, code)
    total <- total + nrow(r)

    if (!apercu) {
      r$code_interne <- catalogue$code_interne[[i]]
      r$annee <- as.integer(format(r$date_periode, "%Y"))
      r$date_periode <- format(r$date_periode, "%Y-%m-%d")
      DBI::dbWithTransaction(con, {
        DBI::dbWriteTable(con, "obs_tmp",
          r[c("code_interne", "iso3", "frequence", "date_periode", "annee", "valeur")],
          temporary = TRUE, overwrite = TRUE)
        DBI::dbExecute(con, "
          INSERT INTO observation (code_interne, iso3, frequence, date_periode, annee, valeur)
          SELECT code_interne, iso3, frequence, date_periode, annee, valeur FROM obs_tmp
          WHERE 1
          ON CONFLICT (code_interne, iso3, frequence, date_periode)
          DO UPDATE SET valeur = excluded.valeur")
        DBI::dbExecute(con, "DROP TABLE IF EXISTS obs_tmp")
        DBI::dbExecute(con, "
          UPDATE indicateur SET derniere_collecte = ?,
            nb_observations = (SELECT COUNT(*) FROM observation WHERE code_interne = ?)
          WHERE code_interne = ?",
          params = list(format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                        catalogue$code_interne[[i]], catalogue$code_interne[[i]]))
      })
    }
  }

  cat(sprintf("Colonnes reperees : produit = %s, periode = %s, valeur = %s\n",
              col_produit, col_periode, col_valeur))
  cat(sprintf("%d produits trouves sur %d : %s\n", length(trouves),
              nrow(catalogue), paste(trouves, collapse = ", ")))
  if (length(absents)) {
    cat(sprintf("%d absents du fichier : %s\n", length(absents),
                paste(absents, collapse = ", ")))
    codes_fichier <- sort(unique(as.character(d[[col_produit]])))
    cat("Codes presents dans le fichier : ",
        paste(utils::head(codes_fichier, 40), collapse = ", "), "\n", sep = "")
  }
  cat(sprintf("%s : %d observations\n",
              if (apercu) "Apercu, rien n'a ete ecrit" else "Ecrites en base",
              total))
  invisible(total)
}

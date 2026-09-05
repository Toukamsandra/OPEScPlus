# ---------------------------------------------------------------------------
# Import d'un fichier de cours telecharge depuis data.imf.org.
#
# Le bouton DOWNLOAD de la page du jeu de donnees est construit en JavaScript :
# aucune adresse ne figure dans le HTML, elle ne peut donc pas etre trouvee par
# programme. Le fichier se telecharge a la main, une fois, et cette fonction
# l'integre.
#
# Le format du fichier est large : une ligne par serie, une colonne par
# periode, et le nom de la colonne porte la periode elle-meme. Ce n'est pas le
# format long que produit une interface de programmation ; il faut donc le
# retourner avant toute chose.
#
# Deux particularites de ce fichier, apprises en le lisant :
#
#   - la colonne INDICATOR contient un libelle, pas un code. Le code du produit
#     est le deuxieme element de SERIES_CODE, par exemple PCOCO dans
#     G001.PCOCO.INDEX.Q ;
#   - chaque produit est publie sous quatre transformations, dont deux taux de
#     variation. Retenir la mauvaise donnerait une serie de pourcentages la ou
#     l'on attend un cours en dollars.
# ---------------------------------------------------------------------------

# Ordre de preference des transformations. Le niveau en dollars d'abord, car
# c'est un cours ; l'indice ensuite, pour les series qui n'existent que sous
# cette forme, comme les indices de prix des produits de base. Les variations
# sont ecartees : ce sont des grandeurs derivees, que la plateforme sait
# calculer elle-meme a partir du niveau.
TRANSFORMATIONS <- c("US dollars", "US Dollars", "Index")

#' Importe un fichier de cours telecharge a la main
#'
#' @param chemin chemin du fichier, CSV ou classeur Excel.
#' @param categorie code de la categorie a alimenter, "C15" pour les matieres
#'   premieres. Les codes du fichier sont rapproches des codes de collecte des
#'   indicateurs de cette categorie.
#' @param iso3 entite geographique a laquelle rattacher les observations.
#'   "WLD" pour un cours mondial, un code pays pour une serie nationale.
#' @param remplacer si TRUE, efface les observations existantes de chaque
#'   serie avant d'ecrire. A utiliser quand le nouveau fichier fait autorite
#'   sur l'ancien ; sinon, les deux se completent.
#' @param creer si TRUE, cree dans la categorie les indicateurs presents dans
#'   le fichier mais absents du catalogue. C'est ce qui permet d'accueillir une
#'   base externe entiere sans avoir a la decrire au prealable.
#' @param apercu si TRUE, affiche ce qui serait importe sans rien ecrire.
#'   A lancer en premier.
#'
#' @return nombre d'observations ecrites, de facon invisible.
#'
#' @examples
#' \dontrun{
#' importer_produits_local("C:/Users/user/Downloads/matierespremieres.csv",
#'                         apercu = TRUE)
#' importer_produits_local("C:/Users/user/Downloads/matierespremieres.csv")
#' }
#' @export
importer_produits_local <- function(chemin, categorie = "C15", iso3 = "WLD",
                                    creer = FALSE, apercu = FALSE,
                                    mode = c("completer", "remplacer")) {
  mode <- match.arg(mode)
  if (!file.exists(chemin)) stop("Fichier introuvable : ", chemin, call. = FALSE)

  d <- if (grepl("[.]xlsx?$", chemin, ignore.case = TRUE)) {
    openxlsx::read.xlsx(chemin, sheet = 1, check.names = FALSE)
  } else {
    utils::read.csv(chemin, stringsAsFactors = FALSE, check.names = FALSE,
                    fileEncoding = "UTF-8-BOM")
  }
  if (is.null(d) || !nrow(d)) stop("Le fichier est vide.", call. = FALSE)

  colonnes_periode <- names(d)[grepl("^[0-9]{4}(-[MQ][0-9]{1,2})?$", names(d))]
  if (!length(colonnes_periode)) {
    stop("Aucune colonne de periode reconnue. Colonnes du fichier : ",
         paste(utils::head(names(d), 15), collapse = ", "), call. = FALSE)
  }

  d$CODE_PRODUIT <- extraire_code_produit(d)
  if (all(is.na(d$CODE_PRODUIT))) {
    stop("Code de produit introuvable. La colonne SERIES_CODE est attendue.",
         call. = FALSE)
  }

  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  catalogue <- DBI::dbGetQuery(con, "
    SELECT code_interne, code_source, libelle, unite FROM indicateur
    WHERE categorie = ?", params = list(categorie))
  if (!nrow(catalogue)) {
    stop("Categorie inconnue ou vide : ", categorie,
         ". Voir codes_categories().", call. = FALSE)
  }
  if (!iso3 %in% DBI::dbGetQuery(con, "SELECT iso3 FROM pays")$iso3) {
    stop("Entite geographique inconnue : ", iso3, call. = FALSE)
  }

  presents <- intersect(catalogue$code_source, unique(d$CODE_PRODUIT))
  cat(sprintf("Fichier : %d series, %d colonnes de periode (%s a %s).\n",
              nrow(d), length(colonnes_periode),
              colonnes_periode[[1]], utils::tail(colonnes_periode, 1)))
  cat(sprintf("%d des %d cours du catalogue y figurent.\n",
              length(presents), nrow(catalogue)))

  absents <- setdiff(catalogue$code_source, presents)
  if (length(absents)) {
    cat("Au catalogue mais absents du fichier : ",
        paste(utils::head(absents, 20), collapse = ", "), "\n", sep = "")
  }

  # Series du fichier que le catalogue ne connait pas encore.
  inconnus <- setdiff(stats::na.omit(unique(d$CODE_PRODUIT)), catalogue$code_source)
  if (length(inconnus)) {
    cat(sprintf("%d s\u00e9ries du fichier ne figurent pas au catalogue%s.\n",
                length(inconnus),
                if (creer) ", elles y seront ajout\u00e9es" else
                  " (relancez avec creer = TRUE pour les ajouter)"))
  }
  if (identical(mode, "remplacer") && !apercu) {
    supprimer_donnees(categorie = categorie, con = con, confirmer = TRUE)
  }
  if (creer && length(inconnus) && !apercu) {
    creer_indicateurs(con, d, inconnus, categorie)
    catalogue <- DBI::dbGetQuery(con, "
      SELECT code_interne, code_source, libelle, unite FROM indicateur
      WHERE categorie = ?", params = list(categorie))
    presents <- intersect(catalogue$code_source, unique(d$CODE_PRODUIT))
  }
  if (apercu) {
    cat("\nApercu seulement : rien n'a ete ecrit. ",
        "Relancez sans apercu = TRUE.\n", sep = "")
    return(invisible(0L))
  }
  if (!length(presents)) {
    cat("\nAucun code du catalogue reconnu : rien a importer.\n")
    return(invisible(0L))
  }

  total <- 0L
  for (code in presents) {
    lignes <- d[!is.na(d$CODE_PRODUIT) & d$CODE_PRODUIT == code, , drop = FALSE]
    lignes <- retenir_transformation(lignes)
    if (!nrow(lignes)) next

    r <- deplier(lignes, colonnes_periode, iso3)
    if (!nrow(r)) next

    ligne <- catalogue[catalogue$code_source == code, ][1, ]
    # L'effacement en mode remplacement a deja eu lieu plus haut, pour toute
    # la categorie. Le repeter ici invoquait une variable inexistante : cette
    # fonction a un argument `mode`, non `remplacer`.
    ecrire_observations(con, ligne$code_interne, r)

    # L'unite est reprise du fichier plutot que du catalogue : la source fait
    # foi, et les nomenclatures n'expriment pas les memes cours dans les memes
    # unites.
    unite <- attr(lignes, "unite")
    if (!is.null(unite) && nzchar(unite) && !identical(unite, ligne$unite)) {
      DBI::dbExecute(con, "UPDATE indicateur SET unite = ? WHERE code_interne = ?",
                     params = list(unite, ligne$code_interne))
    }

    total <- total + nrow(r)
    pas <- paste(sort(unique(libelle_frequence(r$frequence))), collapse = ", ")
    cat(sprintf("  %-10s %6d observations  (%s)\n", code, nrow(r), pas))
  }

  # Remise en accord des compteurs avec les observations : sans elle, un cours
  # importe pouvait rester affiche comme non collecte.
  rafraichir_compteurs(con)

  cat(sprintf("\n%d observations ecrites. Relancez l'application pour les voir.\n",
              total))
  invisible(total)
}

#' Code du produit, extrait de SERIES_CODE
#'
#' La colonne INDICATOR ne contient qu'un libelle. Le code utile est le
#' deuxieme element de SERIES_CODE : G001.PCOCO.INDEX.Q donne PCOCO.
#' @noRd
extraire_code_produit <- function(d) {
  colonne <- intersect(c("SERIES_CODE", "SERIES", "KEY"), names(d))
  if (length(colonne)) {
    morceaux <- strsplit(as.character(d[[colonne[[1]]]]), ".", fixed = TRUE)
    return(vapply(morceaux, function(x) if (length(x) >= 2) x[[2]] else NA_character_,
                  character(1)))
  }
  # A defaut, une colonne dont les valeurs ressemblent a des codes de produit.
  for (c_ in names(d)) {
    v <- as.character(d[[c_]])
    if (mean(grepl("^P[A-Z]{2,}$", v), na.rm = TRUE) > 0.5) return(v)
  }
  rep(NA_character_, nrow(d))
}

#' Ne garde qu'une transformation, la plus proche d'un cours
#' @noRd
retenir_transformation <- function(lignes) {
  colonne <- intersect(c("DATA_TRANSFORMATION", "TRANSFORMATION", "UNIT_MEASURE"),
                       names(lignes))
  if (!length(colonne)) return(lignes)

  valeurs <- as.character(lignes[[colonne[[1]]]])
  for (souhaitee in TRANSFORMATIONS) {
    garde <- !is.na(valeurs) & valeurs == souhaitee
    if (any(garde)) {
      r <- lignes[garde, , drop = FALSE]
      attr(r, "unite") <- souhaitee
      return(r)
    }
  }
  # Aucune transformation connue : on ecarte explicitement les variations,
  # qui donneraient des pourcentages la ou l'on attend un niveau.
  garde <- !grepl("percent|change|variation", valeurs, ignore.case = TRUE)
  r <- lignes[garde, , drop = FALSE]
  attr(r, "unite") <- if (nrow(r)) valeurs[garde][[1]] else ""
  r
}

#' Retourne le tableau large en observations
#'
#' La frequence est deduite du nom de la colonne et non de la colonne
#' FREQUENCY : une meme serie annuelle et mensuelle occupe des colonnes
#' distinctes, et le nom de la colonne est la seule information fiable sur la
#' periode qu'elle couvre.
#' @noRd
deplier <- function(lignes, colonnes_periode, iso3 = "WLD") {
  morceaux <- lapply(colonnes_periode, function(p) {
    valeurs <- suppressWarnings(as.numeric(
      gsub("[^0-9.eE+-]", "", as.character(lignes[[p]]))))
    valeurs <- valeurs[!is.na(valeurs)]
    if (!length(valeurs)) return(NULL)
    converti <- periode_vers_date(p)
    if (is.na(converti[[1]])) return(NULL)
    data.frame(iso3 = iso3, date_periode = converti[[1]],
               frequence = converti[[2]], valeur = valeurs[[1]],
               stringsAsFactors = FALSE)
  })
  morceaux <- Filter(Negate(is.null), morceaux)
  if (!length(morceaux)) {
    return(data.frame(iso3 = character(), date_periode = as.Date(character()),
                      frequence = character(), valeur = numeric(),
                      stringsAsFactors = FALSE))
  }
  r <- do.call(rbind, morceaux)
  r[!duplicated(r[c("frequence", "date_periode")]), ]
}

#' Liste les categories et leur etat de collecte
#'
#' A consulter avant un import, pour connaitre le code de la categorie a
#' alimenter et voir ce qui y figure deja.
#'
#' @examples
#' \dontrun{
#' codes_categories()
#' }
#' @export
codes_categories <- function() {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  DBI::dbGetQuery(con, "
    SELECT c.code, c.libelle,
           COUNT(i.code_interne) AS indicateurs,
           SUM(CASE WHEN i.nb_observations > 0 THEN 1 ELSE 0 END) AS collectes,
           COALESCE(SUM(i.nb_observations), 0) AS observations
    FROM categorie c
    LEFT JOIN indicateur i ON i.categorie = c.code AND i.actif = 1
    GROUP BY c.code, c.libelle, c.ordre ORDER BY c.ordre")
}

#' Cree les indicateurs manquants d'une categorie a partir du fichier
#'
#' Le libelle est repris de la colonne INDICATOR du fichier, dont on ne garde
#' que le premier segment : la source y accole l'unite et le type de prix, ce
#' qui ferait des libelles interminables dans les listes.
#' @noRd
creer_indicateurs <- function(con, d, codes, categorie) {
  colonne_libelle <- intersect(c("INDICATOR", "LABEL", "NAME"), names(d))
  nouveaux <- lapply(codes, function(code) {
    lignes <- d[!is.na(d$CODE_PRODUIT) & d$CODE_PRODUIT == code, , drop = FALSE]
    libelle <- if (length(colonne_libelle)) {
      trimws(strsplit(as.character(lignes[[colonne_libelle[[1]]]])[1], ",")[[1]][1])
    } else code
    if (is.na(libelle) || !nzchar(libelle)) libelle <- code

    data.frame(
      code_interne = paste(categorie, code, sep = "."),
      categorie = categorie, secteur = NA_character_, libelle = libelle,
      source = "Import local", code_source = code, frequences = "M,T,A",
      unite = "", dimension_pays = 0L, par_defaut = 0L, actif = 1L,
      derniere_collecte = NA_character_, nb_observations = 0L,
      stringsAsFactors = FALSE)
  })
  DBI::dbAppendTable(con, "indicateur", do.call(rbind, nouveaux))
  cat(sprintf("  %d indicateurs cr\u00e9\u00e9s dans %s.\n", length(codes), categorie))
  invisible(length(codes))
}

#' Charge un fichier de cours dans la categorie C15, sans affichage
#'
#' Meme traitement que `importer_produits_local()`, mais silencieux et
#' creant les indicateurs manquants. Sert au chargement automatique du fichier
#' livre et au depot d'un fichier depuis l'interface.
#'
#' @param con connexion ouverte.
#' @param chemin fichier a charger.
#' @param categorie categorie a alimenter.
#'
#' @return nombre d'observations ecrites.
#' @noRd
charger_cours_livres <- function(con, chemin, categorie = "C15",
                                 mode = c("completer", "remplacer")) {
  mode <- match.arg(mode)

  # En mode remplacement, les observations de la categorie sont effacees avant
  # ecriture. C'est le seul moyen qu'une serie retiree du fichier disparaisse
  # aussi de la base : une simple reecriture met a jour ce qui existe encore,
  # mais laisse en place ce qui a ete supprime a la source.
  if (identical(mode, "remplacer")) {
    supprimer_donnees(categorie = categorie, con = con, confirmer = TRUE)
  }

  d <- lire_fichier_cours(chemin)
  colonnes_periode <- colonnes_de_periode(d)
  d$CODE_PRODUIT <- extraire_code_produit(d)

  # Les taux de change livres avec les cours sont ecartes : leur code commence
  # par T et ils n'ont rien a faire dans une categorie de produits.
  d <- d[!is.na(d$CODE_PRODUIT) & !grepl("^T[0-9]", d$CODE_PRODUIT), , drop = FALSE]
  if (!nrow(d)) return(0L)

  catalogue <- DBI::dbGetQuery(con,
    "SELECT code_interne, code_source FROM indicateur WHERE categorie = ?",
    params = list(categorie))
  inconnus <- setdiff(unique(d$CODE_PRODUIT), catalogue$code_source)
  if (length(inconnus)) {
    creer_indicateurs(con, d, inconnus, categorie)
    catalogue <- DBI::dbGetQuery(con,
      "SELECT code_interne, code_source FROM indicateur WHERE categorie = ?",
      params = list(categorie))
  }

  total <- 0L
  for (code in intersect(catalogue$code_source, unique(d$CODE_PRODUIT))) {
    lignes <- retenir_transformation(
      d[d$CODE_PRODUIT == code, , drop = FALSE])
    if (!nrow(lignes)) next
    r <- deplier(lignes, colonnes_periode, "WLD")
    if (!nrow(r)) next

    code_interne <- catalogue$code_interne[catalogue$code_source == code][1]

    # L'effacement en mode remplacement a deja eu lieu, pour toute la
    # categorie, avant la lecture du fichier. Le repeter ici invoquait une
    # variable qui n'existe pas dans cette fonction, dont l'argument s'appelle
    # `mode` : c'est l'erreur « objet 'remplacer' introuvable ».
    ecrire_observations(con, code_interne, r)

    unite <- attr(lignes, "unite")
    if (!is.null(unite) && nzchar(unite)) {
      DBI::dbExecute(con, "UPDATE indicateur SET unite = ? WHERE code_interne = ?",
                     params = list(unite, code_interne))
    }
    total <- total + nrow(r)
  }
  rafraichir_compteurs(con)
  message(sprintf("  %d observations charg\u00e9es dans %s.", total, categorie))
  total
}

#' Lit un fichier de cours, CSV ou classeur
#' @noRd
lire_fichier_cours <- function(chemin) {
  if (!file.exists(chemin)) stop("Fichier introuvable : ", chemin, call. = FALSE)
  d <- if (grepl("[.]xlsx?$", chemin, ignore.case = TRUE)) {
    openxlsx::read.xlsx(chemin, sheet = 1, check.names = FALSE)
  } else {
    utils::read.csv(chemin, stringsAsFactors = FALSE, check.names = FALSE,
                    fileEncoding = "UTF-8-BOM")
  }
  if (is.null(d) || !nrow(d)) stop("Le fichier est vide.", call. = FALSE)
  d
}

#' Colonnes dont le nom est une periode
#' @noRd
colonnes_de_periode <- function(d) {
  colonnes <- names(d)[grepl("^[0-9]{4}(-[MQ][0-9]{1,2})?$", names(d))]
  if (!length(colonnes)) {
    stop("Aucune colonne de periode reconnue. Colonnes : ",
         paste(utils::head(names(d), 12), collapse = ", "), call. = FALSE)
  }
  colonnes
}

# --- Suppression -----------------------------------------------------------
#
# Deux niveaux, volontairement distincts. Effacer les observations laisse les
# indicateurs en place, prets a etre realimentes : c'est ce qu'on veut avant de
# recharger un fichier corrige. Retirer les indicateurs va plus loin et n'a de
# sens que pour ceux qu'un import a crees, qui ne figurent dans aucun
# catalogue de reference.
#
# Les deux demandent une confirmation explicite. Une suppression est
# irreversible, et la base n'est pas versionnee.

#' Efface les observations d'une categorie ou d'un indicateur
#'
#' @param categorie code de categorie, "C15" par exemple. Ignore si `code` est
#'   fourni.
#' @param code code interne d'un indicateur precis.
#' @param confirmer doit valoir TRUE. Sans cela, la fonction se contente
#'   d'annoncer ce qu'elle effacerait.
#' @param con connexion ouverte, ou NULL pour en ouvrir une.
#'
#' @return nombre d'observations effacees, de facon invisible.
#'
#' @examples
#' \dontrun{
#' supprimer_donnees(categorie = "C15")
#' supprimer_donnees(categorie = "C15", confirmer = TRUE)
#' }
#' @export
supprimer_donnees <- function(categorie = NULL, code = NULL, confirmer = FALSE,
                              con = NULL) {
  ferme <- FALSE
  if (is.null(con)) { con <- connexion(); ferme <- TRUE }
  if (ferme) on.exit(DBI::dbDisconnect(con), add = TRUE)

  if (is.null(categorie) && is.null(code)) {
    stop("Precisez une categorie ou un indicateur.", call. = FALSE)
  }

  # La condition ne porte aucun alias de table : SQLite refuse un alias dans
  # un DELETE, d'ou l'erreur « near "o": syntax error ». La meme condition sert
  # au comptage et a l'effacement, ce qui garantit qu'ils portent sur les
  # memes lignes.
  if (!is.null(code)) {
    ou <- "code_interne = ?"; params <- list(code)
  } else {
    ou <- "code_interne IN (SELECT code_interne FROM indicateur WHERE categorie = ?)"
    params <- list(categorie)
  }

  n <- DBI::dbGetQuery(con, sprintf(
    "SELECT COUNT(*) AS n FROM observation WHERE %s", ou), params = params)$n

  if (!isTRUE(confirmer)) {
    message(sprintf("%d observations seraient effacees. Relancez avec confirmer = TRUE.", n))
    return(invisible(0L))
  }
  if (!n) { message("Aucune observation a effacer."); return(invisible(0L)) }

  DBI::dbExecute(con, sprintf("DELETE FROM observation WHERE %s", ou),
                 params = params)
  rafraichir_compteurs(con)
  message(sprintf("%d observations effacees.", n))
  invisible(n)
}

#' Retire les indicateurs crees par un import
#'
#' Ne touche qu'aux indicateurs dont la source est un import : ceux du
#' catalogue de reference restent en place, car les retirer les ferait
#' reapparaitre au prochain `preparer_base()` et laisserait la base
#' incoherente entre-temps.
#'
#' @param categorie code de la categorie a nettoyer.
#' @param confirmer doit valoir TRUE.
#' @param con connexion ouverte, ou NULL.
#'
#' @examples
#' \dontrun{
#' supprimer_indicateurs_importes("C15")
#' supprimer_indicateurs_importes("C15", confirmer = TRUE)
#' }
#' @export
supprimer_indicateurs_importes <- function(categorie, confirmer = FALSE,
                                           con = NULL) {
  ferme <- FALSE
  if (is.null(con)) { con <- connexion(); ferme <- TRUE }
  if (ferme) on.exit(DBI::dbDisconnect(con), add = TRUE)

  d <- DBI::dbGetQuery(con, "
    SELECT code_interne, libelle FROM indicateur
    WHERE categorie = ? AND source LIKE 'Import%'", params = list(categorie))

  if (!nrow(d)) {
    message("Aucun indicateur issu d'un import dans ", categorie, ".")
    return(invisible(0L))
  }
  if (!isTRUE(confirmer)) {
    message(sprintf("%d indicateurs seraient retires de %s, avec leurs donnees.",
                    nrow(d), categorie))
    message("Relancez avec confirmer = TRUE.")
    return(invisible(0L))
  }

  DBI::dbExecute(con, "
    DELETE FROM observation WHERE code_interne IN
      (SELECT code_interne FROM indicateur WHERE categorie = ? AND source LIKE 'Import%')",
    params = list(categorie))
  DBI::dbExecute(con, "
    DELETE FROM indicateur WHERE categorie = ? AND source LIKE 'Import%'",
    params = list(categorie))

  message(sprintf("%d indicateurs retires de %s.", nrow(d), categorie))
  invisible(nrow(d))
}

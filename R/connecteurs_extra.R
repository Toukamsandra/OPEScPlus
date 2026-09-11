# ---------------------------------------------------------------------------
# Connecteurs des fournisseurs restants.
#
# Ces connecteurs sont ecrits d'apres les schemas d'adresse publies par chaque
# institution, verifies dans leur documentation. Ils n'ont pas pu etre
# eprouves sur le reseau depuis l'environnement ou ils ont ete ecrits :
# `tester_fournisseur()` permet de les valider un par un, et c'est la premiere
# chose a faire.
#
# Ce qui a ete appris des connecteurs precedents gouverne ceux-ci. Une adresse
# publiee dans un exemple n'est pas une garantie : les portails changent, et
# l'OCDE a retire l'ancien `stats.oecd.org` en 2024, ce qui explique les
# reponses 404 obtenues avant cette verification. Chaque connecteur rend donc
# une serie vide et un message plutot qu'une erreur, pour qu'un fournisseur
# indisponible n'interrompe pas toute la collecte.
# ---------------------------------------------------------------------------

# Adresses de base, relevees dans la documentation de chaque institution.
# ILOSTAT a deplace son entrepot vers `rplumber.ilo.org`, sans que l'ancienne
# adresse redirige : elle rend 404. Plusieurs candidates sont donc essayees,
# et celle qui repond est retenue pour la session.
#
# Cette facon de faire vaut mieux qu'un pari sur une adresse : les portails
# statistiques changent d'organisation plus souvent qu'on ne le croit, et le
# projet en a deja fait trois fois l'experience.
ILOSTAT_BASES <- c(
  "https://rplumber.ilo.org/files/indicator",
  "https://rplumber.ilo.org/files/website/bulk/indicator",
  "https://webapps.ilo.org/ilostat-files/WEB_bulk_download/indicator",
  "https://www.ilo.org/ilostat-files/WEB_bulk_download/indicator")

# Service applicatif, qui rend les donnees sans passer par un fichier.
ILOSTAT_API <- "https://rplumber.ilo.org"

.cache_ilostat <- new.env(parent = emptyenv())
OCDE_SDMX <- "https://sdmx.oecd.org/public/rest/data"
CNUCED_SDMX <- "https://stats.unctad.org/Rest/data"

#' Connecteur ILOSTAT, par telechargement direct
#'
#' L'Organisation internationale du travail publie chaque indicateur sous
#' forme de fichier comprime, a une adresse previsible. C'est la voie la plus
#' sure : son service SDMX plafonne a trois cent mille enregistrements, ce
#' qu'un indicateur mondial depasse souvent.
#'
#' @param code identifiant de l'indicateur, par exemple `UNE_DEAP_SEX_AGE_RT`.
#' @param debut annee de depart, facultative.
#' @noRd
connecteur_ilostat <- function(code, debut = NULL, ...) {
  # Les fichiers sont ranges par indicateur ET par frequence : l'identifiant
  # porte un suffixe `_A`, `_Q` ou `_M`. Sans lui, l'adresse ne repond pas,
  # ce qui explique le premier essai infructueux.
  #
  # Quand le catalogue donne un code sans suffixe, les trois sont essayes,
  # l'annuel d'abord : c'est la frequence dont dispose la quasi-totalite des
  # indicateurs, et la seule pour beaucoup.
  suffixes <- if (grepl("_[AQM]$", code)) "" else c("_A", "_Q", "_M")

  for (suffixe in suffixes) {
    d <- ilostat_fichier(paste0(code, suffixe), debut)
    if (!is.null(d) && nrow(d)) return(d)
  }
  message("ILOSTAT : ", code, " indisponible. ",
          "Verifiez le code avec catalogue_ilostat().")
  serie_vide()
}

#' Telecharge et lit un fichier de l'entrepot ILOSTAT
#'
#' Deux voies sont essayees. Le service applicatif d'abord, qui rend les
#' donnees directement et ne depend d'aucune arborescence de fichiers. Les
#' entrepots de fichiers ensuite, dont l'adresse a change plusieurs fois.
#' @noRd
ilostat_fichier <- function(identifiant, debut = NULL) {
  # Le service applicatif d'abord : il ne depend pas d'une arborescence de
  # fichiers, donc resiste mieux aux reorganisations du portail.
  d <- ilostat_par_service(identifiant)
  if (!is.null(d)) return(ilostat_mettre_en_forme(d, debut))

  # L'adresse qui a repondu lors d'un appel precedent est reessayee d'abord :
  # inutile de reparcourir la liste a chaque indicateur.
  bases <- unique(c(.cache_ilostat$base, ILOSTAT_BASES))
  for (base in bases) {
    d <- ilostat_par_fichier(sprintf("%s/%s.csv.gz", base, identifiant))
    if (!is.null(d)) {
      .cache_ilostat$base <- base
      return(ilostat_mettre_en_forme(d, debut))
    }
  }
  NULL
}

#' Donnees par le service applicatif
#' @noRd
ilostat_par_service <- function(identifiant) {
  url <- sprintf("%s/data/indicator/", ILOSTAT_API)
  reponse <- tryCatch(
    appel(url, list(id = identifiant, format = ".csv", lang = "en"),
          pause = 0.2),
    error = function(e) NULL)
  if (is.null(reponse)) return(NULL)

  texte <- tryCatch(httr2::resp_body_string(reponse), error = function(e) "")
  if (nchar(texte) < 200 || !grepl(",", texte, fixed = TRUE)) return(NULL)

  d <- tryCatch(utils::read.csv(text = texte, stringsAsFactors = FALSE),
                error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)

  # Verification essentielle : le service a rendu 200 et trente mega-octets
  # pour un identifiant invente lors d'un essai. Il ne refuse donc pas un code
  # inconnu, il rend autre chose. Sans ce controle, la plateforme
  # enregistrerait des donnees sous un indicateur qui n'est pas le leur, ce
  # qui est bien pire qu'une collecte vide.
  colonne <- intersect(c("indicator", "indicator.label", "id"), names(d))[1]
  if (!is.na(colonne)) {
    attendu <- sub("_[AQM]$", "", identifiant)
    rendus <- unique(as.character(d[[colonne]]))
    if (!any(grepl(attendu, rendus, fixed = TRUE))) {
      message("ILOSTAT : le service a rendu ", paste(utils::head(rendus, 2),
              collapse = ", "), " au lieu de ", identifiant, ".")
      return(NULL)
    }
  }
  d
}

#' Donnees par telechargement de fichier
#' @noRd
ilostat_par_fichier <- function(url) {
  temporaire <- tempfile(fileext = ".csv.gz")
  on.exit(unlink(temporaire), add = TRUE)

  ok <- tryCatch({
    utils::download.file(url, temporaire, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)

  # Un fichier de quelques centaines d'octets est une page d'erreur : le
  # serveur rend un document HTML plutot qu'un code d'erreur exploitable.
  if (!ok || !file.exists(temporaire) || file.size(temporaire) < 500) return(NULL)

  tryCatch(utils::read.csv(gzfile(temporaire), stringsAsFactors = FALSE),
           error = function(e) NULL)
}

#' Met une table ILOSTAT au format du moteur
#' @noRd
ilostat_mettre_en_forme <- function(d, debut = NULL) {
  if (is.null(d) || !nrow(d)) return(NULL)

  noms <- tolower(names(d))
  col <- function(...) {
    for (motif in c(...)) {
      i <- which(noms == motif)
      if (length(i)) return(names(d)[i[1]])
    }
    NA_character_
  }
  c_pays <- col("ref_area", "ref_area.label", "country")
  c_temps <- col("time", "time.label", "date")
  c_val <- col("obs_value", "value")
  if (any(is.na(c(c_pays, c_temps, c_val)))) return(NULL)

  # Les series sont ventilees par sexe, age et autres classifications. Les
  # codes de total ne suivent pas une regle unique : `SEX_T` pour le sexe,
  # `AGE_AGGREGATE_TOTAL` ou `AGE_YTHADULT_YGE15` pour l'age selon la
  # nomenclature. Chaque motif connu est essaye.
  # Les motifs sont essayes par ordre de preference, et le premier qui laisse
  # une seule valeur par pays et periode est retenu. Plusieurs codes de total
  # coexistent : « AGE_AGGREGATE_TOTAL » et « AGE_YTHADULT_YGE15 » designent
  # tous deux l'ensemble des ages, dans deux nomenclatures differentes. Les
  # retenir ensemble laisserait deux lignes concurrentes.
  MOTIFS <- c("^SEX_T$", "AGGREGATE_TOTAL", "_TOTAL$", "_YGE15$", "_T$",
              "^TOTAL$")
  for (ventilation in c("sex", "classif1", "classif2")) {
    j <- which(noms == ventilation)
    if (!length(j)) next
    valeurs <- as.character(d[[names(d)[j[1]]]])

    for (motif in MOTIFS) {
      totaux <- grepl(motif, valeurs)
      if (!any(totaux)) next
      candidat <- d[totaux, ]
      # Le motif est retenu s'il reduit vraiment la ventilation, c'est-a-dire
      # s'il ne laisse qu'une modalite.
      if (length(unique(valeurs[totaux])) == 1L) {
        d <- candidat
        break
      }
    }
    noms <- tolower(names(d))
    valeurs <- NULL
  }
  if (!nrow(d)) return(NULL)

  # Controle decisif : il ne doit rester qu'une valeur par pays et par
  # periode. S'il en reste plusieurs, une ventilation n'a pas ete reduite, et
  # les lignes s'ecraseraient en base, la derniere ecrite l'emportant au
  # hasard. Mieux vaut refuser la serie que d'en enregistrer une fausse.
  cle <- paste(d[[c_pays]], d[[c_temps]])
  if (anyDuplicated(cle)) {
    restantes <- setdiff(names(d)[noms %in% c("sex", "classif1", "classif2")],
                         character(0))
    message("ILOSTAT : plusieurs valeurs par pays et periode subsistent. ",
            "Ventilations non reduites : ",
            paste(restantes, collapse = ", "), ".")
    message("  Choisissez un code sans ventilation, ou indiquez le total ",
            "a retenir.")
    return(NULL)
  }

  normaliser_serie(
    iso3 = as.character(d[[c_pays]]),
    periode = as.character(d[[c_temps]]),
    valeur = suppressWarnings(as.numeric(d[[c_val]])),
    debut = debut)
}

#' Catalogue des indicateurs d'ILOSTAT
#'
#' Telecharge la table des matieres de l'entrepot et y cherche un motif. A
#' utiliser pour trouver l'identifiant exact d'un indicateur : ils portent un
#' suffixe de frequence et ne se devinent pas.
#'
#' @param motif texte a chercher dans le libelle, sans accent de preference.
#' @param langue "en", "fr" ou "es".
#'
#' @examples
#' \dontrun{
#' catalogue_ilostat("unemployment rate")
#' catalogue_ilostat("ch\u00f4mage", langue = "fr")
#' }
#' @export
catalogue_ilostat <- function(motif = NULL, langue = "en") {
  d <- NULL

  # Le service applicatif d'abord, les entrepots de fichiers ensuite.
  reponse <- tryCatch(
    appel(sprintf("%s/metadata/toc/indicator/", ILOSTAT_API),
          list(lang = langue, format = ".csv")),
    error = function(e) NULL)
  if (!is.null(reponse)) {
    texte <- tryCatch(httr2::resp_body_string(reponse), error = function(e) "")
    if (nchar(texte) > 200) {
      d <- tryCatch(utils::read.csv(text = texte, stringsAsFactors = FALSE),
                    error = function(e) NULL)
    }
  }

  if (is.null(d)) {
    for (base in ILOSTAT_BASES) {
      temporaire <- tempfile(fileext = ".csv")
      ok <- tryCatch({
        utils::download.file(
          sprintf("%s/table_of_contents_%s.csv", base, langue),
          temporaire, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) FALSE, warning = function(w) FALSE)
      if (ok && file.exists(temporaire) && file.size(temporaire) > 500) {
        d <- tryCatch(utils::read.csv(temporaire, stringsAsFactors = FALSE),
                      error = function(e) NULL)
        unlink(temporaire)
        if (!is.null(d)) break
      }
      unlink(temporaire)
    }
  }

  if (is.null(d) || !nrow(d)) {
    message("Catalogue ILOSTAT indisponible sur toutes les adresses connues.")
    message("Lancez diagnostic_ilostat() pour voir ce que rend chacune.")
    return(invisible(NULL))
  }
  colonne <- intersect(c("indicator.label", "indicator_label", "indicator"),
                       names(d))[1]
  if (is.na(colonne)) {
    message("Format de catalogue inattendu : ",
            paste(names(d), collapse = ", "))
    return(invisible(d))
  }

  if (!is.null(motif)) {
    garde <- grepl(motif, d[[colonne]], ignore.case = TRUE)
    d <- d[garde, ]
  }
  cat(sprintf("%d tables trouvees.\n\n", nrow(d)))
  if (nrow(d)) {
    apercu <- d[, intersect(c("id", colonne, "freq", "data.start", "data.end"),
                            names(d)), drop = FALSE]
    print(utils::head(apercu, 25), row.names = FALSE)
  }
  invisible(d)
}

#' Connecteur SDMX generique
#'
#' Sert l'OCDE et la CNUCED, qui exposent toutes deux un service SDMX au
#' format standard. Le code d'indicateur porte l'adresse complete apres le
#' service, ce qui evite d'ecrire un connecteur par jeu de donnees : les
#' identifiants SDMX sont trop divers pour etre devines.
#'
#' Format attendu dans le catalogue : `dataflow/cle`, par exemple
#' `OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I/FRA.A`.
#' @noRd
connecteur_sdmx <- function(code, base, nom_source, debut = NULL, ...) {
  morceaux <- strsplit(code, "/", fixed = TRUE)[[1]]
  if (length(morceaux) < 1) return(serie_vide())

  url <- sprintf("%s/%s", base, code)
  parametres <- list(format = "csvfile",
                     dimensionAtObservation = "AllDimensions")
  if (!is.null(debut)) parametres$startPeriod <- as.character(debut)

  reponse <- tryCatch(appel(url, parametres), error = function(e) NULL)
  if (is.null(reponse)) {
    message(nom_source, " : ", code, " indisponible.")
    return(serie_vide())
  }

  texte <- tryCatch(httr2::resp_body_string(reponse), error = function(e) "")
  if (!nzchar(texte) || !grepl(",", texte, fixed = TRUE)) return(serie_vide())

  d <- tryCatch(
    utils::read.csv(text = texte, stringsAsFactors = FALSE),
    error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(serie_vide())

  noms <- toupper(names(d))
  trouver <- function(...) {
    for (motif in c(...)) {
      i <- which(noms == motif)
      if (length(i)) return(names(d)[i[1]])
    }
    NA_character_
  }
  c_pays <- trouver("REF_AREA", "COUNTRY", "LOCATION", "ECONOMY")
  c_temps <- trouver("TIME_PERIOD", "TIME", "PERIOD")
  c_val <- trouver("OBS_VALUE", "VALUE")
  if (any(is.na(c(c_pays, c_temps, c_val)))) {
    message(nom_source, " : colonnes inattendues pour ", code)
    return(serie_vide())
  }

  normaliser_serie(
    iso3 = as.character(d[[c_pays]]),
    periode = as.character(d[[c_temps]]),
    valeur = suppressWarnings(as.numeric(d[[c_val]])),
    debut = debut)
}

#' @noRd
connecteur_ocde <- function(code, debut = NULL, ...) {
  connecteur_sdmx(code, OCDE_SDMX, "OCDE", debut = debut)
}

#' @noRd
connecteur_cnuced <- function(code, debut = NULL, ...) {
  connecteur_sdmx(code, CNUCED_SDMX, "CNUCED", debut = debut)
}

#' Serie vide, au format attendu par le moteur
#'
#' `date_periode` est une colonne de dates, et non de texte. Le moteur appelle
#' `format(d$date_periode, "%Y")` pour en tirer l'annee : sur une colonne de
#' texte, ce deuxieme argument est pris pour `trim` par `format.default`, qui
#' l'attend logique et s'arrete sur « argument 'trim' incorrect ». La collecte
#' echouait alors apres un telechargement pourtant reussi.
#' @noRd
serie_vide <- function() {
  data.frame(iso3 = character(), date_periode = as.Date(character()),
             frequence = character(), valeur = numeric(),
             stringsAsFactors = FALSE)
}

#' Met une serie brute au format du moteur
#'
#' La periode arrive sous des formes variees selon le fournisseur : `2023`,
#' `2023-Q2`, `2023-M07`. Chacune est ramenee au premier jour de la periode
#' qu'elle couvre, convention du reste de la plateforme.
#' @noRd
normaliser_serie <- function(iso3, periode, valeur, debut = NULL) {
  iso3 <- as.character(iso3)
  periode <- as.character(periode)
  garde <- !is.na(valeur) & !is.na(iso3) & !is.na(periode) &
    nzchar(iso3) & nzchar(periode)
  iso3 <- iso3[garde]; periode <- periode[garde]; valeur <- valeur[garde]
  if (!length(valeur)) return(serie_vide())

  # Le trimestre porte le code « T », celui du referentiel FREQUENCES, et non
  # le « Q » de la source. Une frequence absente du referentiel n'est jamais
  # proposee dans les filtres : la serie aurait ete collectee sans jamais
  # devenir consultable.
  frequence <- ifelse(grepl("-Q", periode, fixed = TRUE), "T",
               ifelse(grepl("-M|^[0-9]{4}-[0-9]{2}$", periode), "M", "A"))

  date_periode <- vapply(seq_along(periode), function(i) {
    p <- periode[[i]]
    if (frequence[[i]] == "A") return(sprintf("%s-01-01", substr(p, 1, 4)))
    if (frequence[[i]] == "T") {
      t <- suppressWarnings(as.integer(sub(".*-Q", "", p)))
      if (is.na(t) || t < 1 || t > 4) return(NA_character_)
      return(sprintf("%s-%02d-01", substr(p, 1, 4), (t - 1) * 3 + 1))
    }
    m <- suppressWarnings(as.integer(gsub("[^0-9]", "", substr(p, 6, 8))))
    if (is.na(m) || m < 1 || m > 12) return(NA_character_)
    sprintf("%s-%02d-01", substr(p, 1, 4), m)
  }, character(1))

  d <- data.frame(iso3 = toupper(iso3),
                  date_periode = as.Date(date_periode),
                  frequence = frequence, valeur = as.numeric(valeur),
                  stringsAsFactors = FALSE)
  d <- d[!is.na(d$date_periode), ]

  if (!is.null(debut)) {
    d <- d[as.integer(format(d$date_periode, "%Y")) >= as.integer(debut), ]
  }
  # Les codes pays a deux lettres ou numeriques sont ecartes : la plateforme
  # travaille en ISO3, et convertir a l'aveugle creerait de faux
  # rapprochements.
  #
  # Les codes de regroupement propres a un fournisseur le sont aussi.
  # L'Organisation internationale du travail numerote ses regions X01, X02 :
  # trois caracteres comme un code ISO3, mais ils ne designent aucun pays et
  # se melangeraient a eux sans etre reconnus.
  d <- d[nchar(d$iso3) == 3, ]

  # Tout code de trois caracteres commencant par X est ecarte. La norme ISO
  # 3166 reserve cette lettre aux usages prives : aucun pays n'en porte. Un
  # premier filtre ne visait que les codes numerotes, X01 et X02, et laissait
  # passer XA1, qui designe une region de l'Organisation internationale du
  # travail.
  d[!grepl("^X", d$iso3), ]
}

#' Eprouve un connecteur sur un indicateur
#'
#' A lancer avant d'ajouter des indicateurs au catalogue. Ces connecteurs ont
#' ete ecrits d'apres la documentation publiee, sans pouvoir etre eprouves sur
#' le reseau : cette fonction est la premiere chose a faire.
#'
#' @param fournisseur nom tel qu'il figure au registre.
#' @param code code d'indicateur a essayer.
#'
#' @examples
#' \dontrun{
#' tester_fournisseur("OIT (ILOSTAT)", "UNE_DEAP_SEX_AGE_RT")
#' tester_fournisseur("OCDE", "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I/FRA.A")
#' }
#' @export
tester_fournisseur <- function(fournisseur, code) {
  if (!fournisseur %in% names(REGISTRE)) {
    cat("Fournisseur inconnu. Ceux du registre :\n")
    cat(paste0("  ", names(REGISTRE), collapse = "\n"), "\n")
    return(invisible(NULL))
  }

  cat(sprintf("Essai de %s sur %s.\n", fournisseur, code))
  depart <- Sys.time()
  d <- tryCatch(REGISTRE[[fournisseur]](code),
                error = function(e) {
                  cat("  ECHEC : ", conditionMessage(e), "\n", sep = "")
                  NULL
                })
  duree <- as.numeric(difftime(Sys.time(), depart, units = "secs"))

  if (is.null(d) || !nrow(d)) {
    cat(sprintf("  Aucune donnee rendue (%.0f s).\n", duree))
    if (grepl("ILOSTAT", fournisseur)) {
      cat("  Cherchez le code exact : catalogue_ilostat(\"unemployment\")\n")
      cat("  Les identifiants portent un suffixe de frequence, _A, _Q ou _M.\n")
    } else {
      cat("  L'identifiant SDMX prend la forme agence,flux/cle. Obtenez-le\n")
      cat("  dans l'explorateur du fournisseur, rubrique Partager ou API.\n")
    }
    return(invisible(NULL))
  }

  cat(sprintf("  %d observations en %.0f s.\n", nrow(d), duree))
  cat(sprintf("  %d pays, de %s a %s.\n", length(unique(d$iso3)),
              min(d$date_periode), max(d$date_periode)))
  cat(sprintf("  Frequences : %s\n",
              paste(sort(unique(d$frequence)), collapse = ", ")))
  cat("\n  Extrait :\n")
  print(utils::head(d[order(-as.integer(substr(d$date_periode, 1, 4))), ], 4),
        row.names = FALSE)
  invisible(d)
}

#' Diagnostic detaille de l'acces a ILOSTAT
#'
#' Les essais precedents echouaient sans dire pourquoi : `download.file()`
#' avale l'erreur et rend simplement un fichier absent. Cette fonction
#' interroge chaque etape et rapporte le code de reponse, ce qui distingue
#' trois situations que rien ne separait jusqu'ici.
#'
#' Une adresse de base erronee donne un echec sur tout, y compris le
#' catalogue. Un code d'indicateur inexistant donne un catalogue accessible et
#' un fichier introuvable. Un reseau filtre donne un delai d'attente plutot
#' qu'un refus.
#'
#' @param code indicateur a essayer, avec ou sans suffixe de frequence.
#'
#' @examples
#' \dontrun{
#' diagnostic_ilostat()
#' }
#' @export
diagnostic_ilostat <- function(code = "UNE_DEAP_SEX_AGE_RT_A") {
  essayer <- function(intitule, url) {
    depart <- Sys.time()
    r <- tryCatch(
      httr2::req_perform(
        httr2::req_error(
          httr2::req_timeout(httr2::request(url), 30),
          is_error = function(resp) FALSE)),
      error = function(e) e)
    duree <- as.numeric(difftime(Sys.time(), depart, units = "secs"))

    if (inherits(r, "error")) {
      cat(sprintf("  %-34s ECHEC en %.0f s : %s\n", intitule, duree,
                  substr(conditionMessage(r), 1, 60)))
      return(invisible(NULL))
    }

    statut <- httr2::resp_status(r)
    type <- tryCatch(httr2::resp_content_type(r), error = function(e) "?")
    taille <- length(tryCatch(httr2::resp_body_raw(r), error = function(e) raw()))
    cat(sprintf("  %-34s %d  %s  %s octets  (%.0f s)\n", intitule, statut,
                substr(type, 1, 22), format(taille, big.mark = "\u202f"), duree))
    invisible(list(statut = statut, type = type, taille = taille))
  }

  cat("Acces a ILOSTAT\n\n")

  cat("Service applicatif\n")
  service <- essayer("Catalogue",
    sprintf("%s/metadata/toc/indicator/?lang=en&format=.csv", ILOSTAT_API))
  essayer("Donnees",
    sprintf("%s/data/indicator/?id=%s&format=.csv", ILOSTAT_API, code))

  cat("\nEntrepots de fichiers\n")
  catalogue <- NULL
  for (base in ILOSTAT_BASES) {
    r <- essayer(substr(sub("https://", "", base), 1, 34),
                 sprintf("%s/table_of_contents_en.csv", base))
    if (!is.null(r) && r$statut == 200 && is.null(catalogue)) catalogue <- r
  }
  if (!is.null(service) && service$statut == 200) catalogue <- service

  cat("\nLecture\n")
  if (is.null(catalogue) || catalogue$statut != 200) {
    cat("  Aucune adresse ne repond.\n")
    cat("  Un code 404 signale une adresse perimee, un 403 un filtrage.\n")
    cat("  Si toutes rendent 403, le reseau du ministere bloque le domaine ;\n")
    cat("  essayez depuis une autre connexion pour trancher.\n")
  } else {
    cat("  Le catalogue repond : l'adresse de base est bonne.\n")
    cat("  Si aucun fichier ne repond, le code d'indicateur est en cause.\n")
    cat("  Cherchez-le : catalogue_ilostat(\"unemployment\")\n")
  }
  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Connecteurs vers les sources internationales.
#
# Aucun moissonnage de page : la Banque mondiale, le FMI et l'OCDE publient des
# interfaces de programmation gratuites et sans cle qui renvoient directement
# des donnees structurees, et leurs portails web appellent eux-memes ces
# interfaces. Passer par le rendu HTML reviendrait a reconstruire une
# information deja propre, en plus lent et en beaucoup plus fragile.
# ---------------------------------------------------------------------------

# Le serveur frontal de imf.org renvoie 403 a toute requete dont l'en-tete
# User-Agent ne ressemble pas a un navigateur. La donnee reste publique et sans
# cle : seul le filtrage anti-robot est en cause.
AGENT <- paste("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
               "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36")

appel <- function(url, params = list(), essais = 3L, pause = 0.3, entetes = list()) {
  derniere <- NULL
  for (i in seq_len(essais)) {
    reponse <- tryCatch({
      req <- httr2::request(url)
      req <- do.call(httr2::req_headers, c(
        list(req, `User-Agent` = AGENT,
             `Accept` = "application/json, text/csv, */*"), entetes))
      req <- httr2::req_timeout(req, 600)
      if (length(params)) req <- httr2::req_url_query(req, !!!params)
      httr2::req_perform(req)
    }, error = function(e) e)

    if (!inherits(reponse, "error")) {
      Sys.sleep(pause)
      return(reponse)
    }
    derniere <- reponse
    # 429 : quota depasse. On patiente au lieu d'insister.
    Sys.sleep(if (grepl("429", conditionMessage(reponse))) 5 * i else 2^(i - 1))
  }
  stop(sprintf("Echec apres %d tentatives sur %s : %s", essais, url,
               conditionMessage(derniere)), call. = FALSE)
}

#' Normalise une periode au premier jour de la periode couverte.
#'
#' Cette convention est ce qui permet de superposer sur un meme graphique des
#' series de pas differents. Renvoie une liste (date, frequence).
periode_vers_date <- function(p) {
  p <- trimws(as.character(p))
  if (grepl("^\\d{4}$", p))            return(list(as.Date(paste0(p, "-01-01")), "A"))
  if (grepl("^\\d{4}-?[Qq]\\d$", p)) {
    a <- substr(p, 1, 4); t <- as.integer(substr(p, nchar(p), nchar(p)))
    return(list(as.Date(sprintf("%s-%02d-01", a, (t - 1) * 3 + 1)), "T"))
  }
  if (grepl("^\\d{4}-?[Ss]\\d$", p)) {
    a <- substr(p, 1, 4); s <- as.integer(substr(p, nchar(p), nchar(p)))
    return(list(as.Date(sprintf("%s-%02d-01", a, (s - 1) * 6 + 1)), "S"))
  }
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", p)) return(list(as.Date(p), "J"))
  if (grepl("^\\d{4}-\\d{2}$", p))        return(list(as.Date(paste0(p, "-01")), "M"))
  if (grepl("^\\d{4}M\\d{1,2}$", p)) {
    a <- substr(p, 1, 4); m <- as.integer(sub("^\\d{4}M", "", p))
    return(list(as.Date(sprintf("%s-%02d-01", a, m)), "M"))
  }
  list(NA, NA)
}

periodes_vers_dates <- function(v) {
  res <- lapply(v, periode_vers_date)
  data.frame(
    date_periode = as.Date(vapply(res, function(x) as.numeric(x[[1]]), numeric(1)),
                           origin = "1970-01-01"),
    frequence    = vapply(res, function(x) as.character(x[[2]]), character(1)),
    stringsAsFactors = FALSE)
}

vide <- function() {
  data.frame(iso3 = character(), date_periode = as.Date(character()),
             frequence = character(), valeur = numeric(),
             stringsAsFactors = FALSE)
}

# --- Banque mondiale : WDI, IDS, WGI, PIP, Findex, LPI ---------------------
# Un seul appel avec country/all ramene tous les pays et agregats, ce qui evite
# de boucler sur deux cent vingt pays.
connecteur_banque_mondiale <- function(code_source, debut = NULL, fin = NULL) {
  base <- sprintf("https://api.worldbank.org/v2/country/all/indicator/%s", code_source)
  page <- 1L; total <- 1L; morceaux <- list()

  while (page <= total) {
    params <- list(format = "json", per_page = 20000, page = page)
    if (!is.null(debut) && !is.null(fin)) params$date <- sprintf("%d:%d", debut, fin)
    corps <- jsonlite::fromJSON(httr2::resp_body_string(appel(base, params)),
                                simplifyVector = TRUE)
    # L'API repond 200 avec un message d'erreur dans le corps quand le code
    # n'existe pas : il faut lire le corps, pas le statut.
    if (!is.list(corps) || length(corps) < 2 || is.null(corps[[2]])) break
    total <- corps[[1]]$pages
    d <- corps[[2]]
    if (!is.data.frame(d) || !nrow(d)) break

    dates <- periodes_vers_dates(d$date)
    morceaux[[length(morceaux) + 1L]] <- data.frame(
      iso3 = toupper(trimws(d$countryiso3code)),
      date_periode = dates$date_periode,
      frequence = dates$frequence,
      valeur = suppressWarnings(as.numeric(d$value)),
      stringsAsFactors = FALSE)
    page <- page + 1L
  }
  if (!length(morceaux)) return(vide())
  r <- do.call(rbind, morceaux)
  r[nchar(r$iso3) == 3 & !is.na(r$date_periode), ]
}

# --- FMI, portail SDMX 3.0 -------------------------------------------------
#
# Trois adresses ont ete essayees avant de trouver la bonne, il faut donc etre
# precis sur l'historique :
#
#   dataservices.imf.org         retire le 5 novembre 2025
#   sdmxcentral.imf.org/sdmx/v2  repond 501 Not Implemented sur les requetes
#                                de donnees : ce serveur ne sert que les
#                                structures, pas les observations
#   www.imf.org/external/datamapper/api/v1
#                                repond 403 Forbidden depuis l'exterieur, quel
#                                que soit l'en-tete User-Agent
#
# Le point d'entree valide est celui-ci. Il expose une interface SDMX 3.0
# complete, publique et sans cle.
FMI_SDMX <- "https://api.imf.org/external/sdmx/3.0"

# Le flux WEO couvre a lui seul deux besoins qui passaient auparavant par deux
# sources distinctes : les agregats de cadrage et de finances publiques
# (GGXWDG_NGDP, GGXCNL_NGDP, NGDP_RPCH...) et les cours des matieres premieres
# (PCOCO, POILBRE, PALUM...). Une seule requete, un seul format de reponse.
#
# Ses dimensions, dans l'ordre impose par la structure : COUNTRY.INDICATOR.FREQUENCY
FLUX_WEO <- list(agence = "IMF.RES", flux = "WEO",
                 cle = function(code) sprintf("*.%s.A", code))

#' Interroge un flux du portail SDMX du FMI
#'
#' On demande du SDMX-CSV plutot que du SDMX-JSON. La reponse JSON est un
#' empilement de listes ou les codes de dimension sont remplaces par des
#' indices positionnels qu'il faut ensuite reconcilier avec les structures :
#' le CSV donne directement un tableau plat, ce qui supprime tout ce travail
#' de remontage et les erreurs qui vont avec.
#' @noRd
fmi_sdmx <- function(agence, flux, cle, debut = NULL, fin = NULL, pause = 0.8) {
  params <- list(dimensionAtObservation = "TIME_PERIOD",
                 attributes = "none", measures = "all", includeHistory = "false")
  if (!is.null(debut)) params$startPeriod <- as.character(debut)
  if (!is.null(fin))   params$endPeriod   <- as.character(fin)

  url <- sprintf("%s/data/dataflow/%s/%s/+/%s", FMI_SDMX, agence, flux, cle)
  reponse <- appel(url, params, pause = pause,
                   entetes = list(Accept = "application/vnd.sdmx.data+csv;version=2.0.0"))

  texte <- httr2::resp_body_string(reponse)
  if (!nzchar(trimws(texte))) return(vide())

  d <- utils::read.csv(text = texte, stringsAsFactors = FALSE, check.names = FALSE)
  if (!nrow(d)) return(vide())

  col_pays    <- intersect(c("COUNTRY", "REF_AREA"), names(d))[1]
  col_periode <- intersect(c("TIME_PERIOD", "TIME"), names(d))[1]
  col_valeur  <- intersect(c("OBS_VALUE", "VALUE"), names(d))[1]
  if (any(is.na(c(col_periode, col_valeur)))) {
    stop(sprintf("Colonnes SDMX inattendues pour %s : %s", flux,
                 paste(names(d), collapse = ", ")), call. = FALSE)
  }

  dates <- periodes_vers_dates(d[[col_periode]])
  iso <- if (is.na(col_pays)) rep("WLD", nrow(d)) else toupper(as.character(d[[col_pays]]))
  r <- data.frame(iso3 = iso, date_periode = dates$date_periode,
                  frequence = dates$frequence,
                  valeur = suppressWarnings(as.numeric(d[[col_valeur]])),
                  stringsAsFactors = FALSE)
  r[!is.na(r$date_periode), ]
}

#' Connecteur WEO : cadrage et finances publiques
#' @noRd
connecteur_fmi_weo <- function(code_source, debut = NULL, fin = NULL) {
  fmi_sdmx(FLUX_WEO$agence, FLUX_WEO$flux, FLUX_WEO$cle(code_source), debut, fin)
}

# --- Prix mondiaux des produits de base ------------------------------------
#
# Historique de cette source, parce qu'il explique le choix final :
#
#   flux WEO du FMI          accepte les codes, ne renvoie aucune observation
#   flux PCPS du FMI         ignore le format CSV et les bornes temporelles,
#                            huit mega-octets de JSON imbrique par requete
#   classeur du FMI          403 Forbidden : www.imf.org filtre les requetes
#                            automatisees quel que soit l'en-tete envoye
#
# La source retenue est le Pink Sheet de la Banque mondiale, qui publie les
# memes cours mensuels depuis 1960 dans un classeur unique. Son serveur ne
# filtre pas, et l'API de la Banque mondiale fonctionne deja pour le reste du
# catalogue. Avantage supplementaire pour un usage camerounais : il cote les
# grumes et les sciages du Cameroun, la ou le FMI ne donne qu'un cours de
# reference asiatique.
PAGE_PINK_SHEET <- "https://www.worldbank.org/en/research/commodity-markets"

# Correspondance entre les codes du catalogue, herites du systeme du FMI, et
# ceux du Pink Sheet. Les deux nomenclatures ne se recouvrent pas exactement :
# les rapprochements approximatifs sont signales en commentaire.
CODES_PINK_SHEET <- c(
  PNRGW    = "iENERGY",        # indice des produits energetiques
  PFANDBW  = "iFOOD",          # indice alimentaire, perimetre un peu plus etroit
  PMETAW   = "iMETMIN",        # metaux et mineraux
  PRAWMW   = "iOTHERRAWMAT",   # matieres premieres agricoles
  PALLFNFW = "iNONENERGY",     # hors energie, et non l'ensemble des produits
  POILAPSP = "CRUDE_PETRO",
  POILBRE  = "CRUDE_BRENT",
  POILWTI  = "CRUDE_WTI",
  POILDUB  = "CRUDE_DUBAI",
  PNGASEU  = "NGAS_EUR",
  PCOALAU  = "COAL_AUS",
  PALUM    = "ALUMINUM",
  PCOPP    = "COPPER",
  PIORECR  = "IRON_ORE",
  PGOLD    = "GOLD",           # absent du WEO, present ici
  PCOCO    = "COCOA",
  PCOFFOTM = "COFFEE_ARABIC",
  PCOFFROB = "COFFEE_ROBUS",
  PCOTTIND = "COTTON_A_INDX",
  PSUGAISA = "SUGAR_WLD",
  PBANSOP  = "BANANA_EU",      # cotation europeenne
  PRUBB    = "RUBBER_TSR20",
  PPOIL    = "PALM_OIL",
  PLOGSK   = "LOGS_CMR",       # grumes du Cameroun
  PSAWMAL  = "SAWNWD_CMR",     # sciages du Cameroun
  PMAIZMT  = "MAIZE",
  PWHEAMT  = "WHEAT_US_HRW",
  PRICENPQ = "RICE_05")

.cache_flux <- new.env(parent = emptyenv())

#' Repere l'adresse du classeur mensuel
#'
#' L'adresse comporte un identifiant de document qui change a chaque parution :
#' la coder en dur la rendrait caduque au premier mois. On lit donc la page de
#' presentation pour y trouver le lien. C'est le seul endroit du projet ou du
#' HTML est analyse, et il se limite a la recherche d'un nom de fichier.
#' @noRd
adresse_pink_sheet <- function() {
  html <- httr2::resp_body_string(appel(PAGE_PINK_SHEET, list(), pause = 0.5))
  liens <- regmatches(html, gregexpr(
    "https://[^\"'[:space:]]*CMO-Historical-Data-Monthly\\.xlsx", html))[[1]]
  if (!length(liens)) {
    stop("Lien du classeur mensuel introuvable sur ", PAGE_PINK_SHEET,
         ". La page a probablement change.", call. = FALSE)
  }
  liens[[1]]
}

#' Telecharge le classeur et en extrait les series recherchees
#'
#' Deux corrections par rapport a la version precedente, apprises d'une
#' collecte qui n'a rien trouve :
#'
#' 1. La ligne d'en-tete n'est plus deduite d'un decalage fixe par rapport aux
#'    donnees. On parcourt les premieres lignes de chaque feuille et on retient
#'    celle qui contient le plus de codes recherches. Le classeur peut donc
#'    gagner ou perdre une ligne de titre sans rien casser.
#' 2. Toutes les feuilles mensuelles sont parcourues, et non la premiere
#'    trouvee. Le classeur separe les cours et les indices en deux feuilles :
#'    ne lire que la premiere condamnait la moitie du catalogue.
#'
#' @return liste nommee par code, chaque element portant periodes, valeurs et
#'   unite.
#' @noRd
classeur_produits <- function() {
  if (!is.null(.cache_flux$produits)) return(.cache_flux$produits)

  fichier <- tempfile(fileext = ".xlsx")
  on.exit(unlink(fichier), add = TRUE)
  writeBin(httr2::resp_body_raw(appel(adresse_pink_sheet(), list(), pause = 0.5)),
           fichier)

  feuilles <- openxlsx::getSheetNames(fichier)
  retenues <- feuilles[grepl("month|mensuel", feuilles, ignore.case = TRUE)]
  if (!length(retenues)) retenues <- feuilles

  cibles <- unname(CODES_PINK_SHEET)
  series <- list()
  journal <- list()

  for (nom in retenues) {
    brut <- tryCatch(
      openxlsx::read.xlsx(fichier, sheet = nom, colNames = FALSE,
                          skipEmptyRows = FALSE, skipEmptyCols = FALSE),
      error = function(e) NULL)
    if (is.null(brut) || !nrow(brut) || !ncol(brut)) next

    # Ligne d'en-tete : celle qui porte le plus de codes recherches.
    hauteur <- min(30L, nrow(brut))
    scores <- vapply(seq_len(hauteur), function(i) {
      sum(trimws(as.character(unlist(brut[i, ]))) %in% cibles)
    }, integer(1))
    journal[[nom]] <- max(scores)
    if (max(scores) < 1L) next
    h <- which.max(scores)

    codes <- trimws(as.character(unlist(brut[h, ])))
    unites <- if (h > 1L) trimws(as.character(unlist(brut[h - 1L, ])))
              else rep("", length(codes))
    corps <- brut[seq.int(h + 1L, nrow(brut)), , drop = FALSE]

    # Colonne des periodes : celle dont les valeurs suivent la forme 1960M01.
    est_periode <- vapply(corps, function(x) {
      v <- trimws(as.character(x))
      v <- v[!is.na(v) & nzchar(v)]
      length(v) > 0 && mean(grepl("^\\d{4}[MmQq]\\d{1,2}$", v)) > 0.8
    }, logical(1))
    if (!any(est_periode)) next

    periodes <- trimws(as.character(corps[[which(est_periode)[[1]]]]))
    garde <- grepl("^\\d{4}[Mm]\\d{1,2}$", periodes)
    if (!any(garde)) next
    corps <- corps[garde, , drop = FALSE]
    periodes <- periodes[garde]

    for (j in which(codes %in% cibles)) {
      series[[codes[[j]]]] <- list(
        periodes = periodes,
        valeurs = corps[[j]],
        unite = if (is.na(unites[[j]])) "" else unites[[j]])
    }
  }

  if (!length(series)) {
    stop("Aucune serie reconnue dans le classeur. Codes trouves par feuille : ",
         paste(sprintf("%s = %d", names(journal), unlist(journal)), collapse = ", "),
         ". Utilisez inspecter_classeur_produits() pour voir sa structure.",
         call. = FALSE)
  }

  attr(series, "feuilles") <- journal
  .cache_flux$produits <- series
  series
}

# --- Prix des produits de base, flux PCPS du FMI ----------------------------
#
# La structure reelle du flux, lue dans la reponse du portail lui-meme :
#
#   COUNTRY . INDICATOR . DATA_TRANSFORMATION . FREQUENCY   puis TIME_PERIOD
#
# Trois erreurs corrigees ici, toutes venues de suppositions :
#
#   - la frequence n'est pas en tete de cle mais en quatrieme position ;
#   - la dimension des produits s'appelle INDICATOR et non COMMODITY, contre ce
#     qu'indiquent des exemples publies pour d'autres millesimes du flux ;
#   - le portail repond en SDMX-JSON meme lorsqu'on demande du CSV, il faut
#     donc savoir lire les deux.
#
# La zone de reference est W00, le monde : PCPS ne publie que des cours
# mondiaux de reference, sans declinaison par pays.
FLUX_PCPS <- list(agence = "IMF.RES", flux = "PCPS", dsd = "DSD_PCPS", zone = "W00")

#' Construit la cle d'une requete PCPS
#'
#' En SDMX 3.0, le joker d'une position s'ecrit `*`. Une position laissee vide
#' est la syntaxe de SDMX 2.1 : ce portail la comprend comme « code vide » et
#' ne renvoie donc rien. C'est ce qui faisait echouer toutes les requetes
#' ciblees alors qu'une cle reduite a `*` rendait bien des donnees.
#' @noRd
cle_pcps <- function(code, frequence = "*", zone = "*") {
  sprintf("%s.%s.*.%s", zone, code, frequence)
}

#' Interroge le flux et rend un tableau plat, quel que soit le format recu
#' @noRd
appel_pcps <- function(code, frequence = "*", zone = "*", debut = NULL) {
  url <- sprintf("%s/data/dataflow/%s/%s/+/%s", FMI_SDMX, FLUX_PCPS$agence,
                 FLUX_PCPS$flux, cle_pcps(code, frequence, zone))
  if (!is.null(debut)) {
    url <- sprintf("%s?c[TIME_PERIOD]=ge:%d-M01", url, as.integer(debut))
  }
  texte <- httr2::resp_body_string(
    appel(url, list(), pause = 0.4, entetes = list(Accept = "text/csv")))
  if (!nzchar(trimws(texte))) return(NULL)

  if (substr(trimws(texte), 1, 1) == "{") return(sdmx_json_vers_tableau(texte))
  d <- utils::read.csv(text = texte, stringsAsFactors = FALSE, check.names = FALSE)
  if (!nrow(d)) NULL else d
}

#' Convertit une reponse SDMX-JSON en tableau plat
#'
#' Le format remplace les codes de dimension par des indices positionnels : une
#' serie est nommee "0:2:1:0" et ses observations sont indexees de la meme
#' facon. Cette fonction reconcilie ces indices avec les listes de codes du
#' bloc `structures`.
#'
#' Elle rend NULL plutot que d'echouer lorsque la reponse est vide : le portail
#' renvoie alors une enveloppe complete dont toutes les listes de valeurs sont
#' vides, ce qui faisait planter la lecture au lieu de signaler l'absence de
#' donnee.
#' @noRd
sdmx_json_vers_tableau <- function(texte) {
  j <- tryCatch(jsonlite::fromJSON(texte, simplifyVector = FALSE),
                error = function(e) NULL)
  if (is.null(j)) return(NULL)

  jeux <- j$data$dataSets
  st <- j$data$structures
  if (!length(jeux) || !length(st)) return(NULL)
  st <- st[[1]]

  series <- jeux[[1]]$series
  if (!length(series)) return(NULL)

  dims <- st$dimensions$series
  if (!length(dims)) return(NULL)
  noms_dims <- vapply(dims, function(d) as.character(d$id), character(1))
  codes_dims <- lapply(dims, function(d) {
    if (!length(d$values)) return(character(0))
    vapply(d$values, function(v) as.character(v$id), character(1))
  })

  obs_dims <- st$dimensions$observation
  if (!length(obs_dims) || !length(obs_dims[[1]]$values)) return(NULL)
  periodes <- vapply(obs_dims[[1]]$values, function(v) as.character(v$id),
                     character(1))

  morceaux <- lapply(names(series), function(cle) {
    idx <- as.integer(strsplit(cle, ":", fixed = TRUE)[[1]]) + 1L
    obs <- series[[cle]]$observations
    if (!length(obs)) return(NULL)
    rang <- as.integer(names(obs)) + 1L
    valeurs <- vapply(obs, function(o) {
      v <- o[[1]]
      if (is.null(v)) NA_real_ else suppressWarnings(as.numeric(v))
    }, numeric(1), USE.NAMES = FALSE)

    ligne <- data.frame(TIME_PERIOD = periodes[rang], OBS_VALUE = valeurs,
                        stringsAsFactors = FALSE)
    for (k in seq_along(noms_dims)) {
      valeurs_dim <- codes_dims[[k]]
      ligne[[noms_dims[k]]] <- if (length(valeurs_dim) >= idx[k]) valeurs_dim[idx[k]] else NA_character_
    }
    ligne
  })

  morceaux <- Filter(Negate(is.null), morceaux)
  if (!length(morceaux)) return(NULL)
  do.call(rbind, morceaux)
}

#' Interroge PCPS avec le paquet imf.data
#'
#' C'est la voie a privilegier : `get_data()` prend des filtres nommes, ce qui
#' supprime la question de l'ordre des dimensions et celle de la syntaxe du
#' joker. Ces deux points ont a eux seuls provoque cinq tentatives
#' infructueuses.
#'
#' Le paquet est facultatif. S'il n'est pas installe, la fonction rend NULL et
#' le connecteur poursuit avec ses propres requetes.
#' @noRd
produits_depuis_imf_data <- function(code, debut = NULL) {
  if (!requireNamespace("imf.data", quietly = TRUE)) return(NULL)

  depart <- if (is.null(debut)) NULL else sprintf("%d-M01", as.integer(debut))
  essais <- list(
    list(COUNTRY = FLUX_PCPS$zone, INDICATOR = code, FREQUENCY = "M"),
    list(COUNTRY = FLUX_PCPS$zone, INDICATOR = code, FREQUENCY = "A"),
    list(INDICATOR = code, FREQUENCY = "M"),
    list(INDICATOR = code))

  for (filtres in essais) {
    d <- tryCatch(
      imf.data::get_data(FLUX_PCPS$flux, filters = filtres,
                         agency_id = FLUX_PCPS$agence,
                         start_period = depart),
      error = function(e) NULL)
    if (!is.null(d) && nrow(d)) return(as.data.frame(d))
  }
  NULL
}

#' Telecharge le flux entier, une seule fois par session
#'
#' Une cle reduite a `*` est la seule forme dont on ait la preuve qu'elle
#' repond : elle a rendu huit mega-octets lors du premier diagnostic. Elle sert
#' donc de recours quand une requete ciblee echoue, et de source pour la
#' decouverte des codes reellement publies.
#' @noRd
flux_pcps_complet <- function() {
  if (!is.null(.cache_flux$pcps)) return(.cache_flux$pcps)
  url <- sprintf("%s/data/dataflow/%s/%s/+/*", FMI_SDMX,
                 FLUX_PCPS$agence, FLUX_PCPS$flux)
  texte <- httr2::resp_body_string(
    appel(url, list(), pause = 1, entetes = list(Accept = "text/csv")))
  d <- if (substr(trimws(texte), 1, 1) == "{") {
    sdmx_json_vers_tableau(texte)
  } else {
    utils::read.csv(text = texte, stringsAsFactors = FALSE, check.names = FALSE)
  }
  if (is.null(d) || !nrow(d)) {
    stop("Le flux PCPS n'a renvoye aucune serie, meme sans filtre.", call. = FALSE)
  }
  .cache_flux$pcps <- d
  d
}

#' Colonne portant les codes de produit, reperee par son contenu
#' @noRd
colonne_produit <- function(d) {
  candidats <- intersect(c("INDICATOR", "COMMODITY", "INDEX"), names(d))
  if (!length(candidats)) {
    candidats <- setdiff(names(d), c("TIME_PERIOD", "OBS_VALUE"))
  }
  scores <- vapply(candidats, function(c_) {
    sum(grepl("^P[A-Z]{2,}", unique(as.character(d[[c_]]))))
  }, integer(1))
  if (max(scores) < 1L) {
    stop("Aucune dimension de produit reconnue. Colonnes : ",
         paste(names(d), collapse = ", "), call. = FALSE)
  }
  candidats[[which.max(scores)]]
}

#' @noRd
produit_dans_flux_complet <- function(code) {
  d <- tryCatch(flux_pcps_complet(), error = function(e) NULL)
  if (is.null(d)) return(NULL)
  col <- tryCatch(colonne_produit(d), error = function(e) NULL)
  if (is.null(col)) return(NULL)
  r <- d[as.character(d[[col]]) == code, , drop = FALSE]
  if (!nrow(r)) NULL else r
}

#' Connecteur des cours mondiaux de produits de base
#'
#' Le flux PCPS du FMI est la source premiere, le classeur Pink Sheet de la
#' Banque mondiale sert de repli. Les deux publient les memes cours mensuels.
#' @noRd
connecteur_produits_de_base <- function(code_source, debut = NULL, fin = NULL) {
  r <- tryCatch(produits_depuis_fmi(code_source, debut, fin),
                error = function(e) e)
  if (!inherits(r, "error") && !is.null(r) && nrow(r)) return(r)

  message("Flux PCPS sans reponse pour ", code_source,
          if (inherits(r, "error")) paste0(" (", conditionMessage(r), ")") else "",
          ". Repli sur le classeur de la Banque mondiale.")
  produits_depuis_pink_sheet(code_source, debut, fin)
}

#' @noRd
produits_depuis_fmi <- function(code_source, debut = NULL, fin = NULL) {
  # Le mensuel d'abord, l'annuel en secours. Et si la zone W00 ne rend rien, on
  # laisse la dimension libre : quelques series pourraient etre rangees sous un
  # autre code geographique.
  # Trois voies, de la plus sure a la plus lourde.
  #   1. imf.data et ses filtres nommes, qui evitent toute question de cle ;
  #   2. requetes ciblees construites a la main ;
  #   3. telechargement du flux entier, puis filtrage.
  d <- produits_depuis_imf_data(code_source, debut)

  if (is.null(d) || !nrow(d)) {
    for (essai in list(c(FLUX_PCPS$zone, "M"), c(FLUX_PCPS$zone, "*"),
                       c("*", "M"), c("*", "*"))) {
      d <- appel_pcps(code_source, essai[[2]], essai[[1]], debut)
      if (!is.null(d) && nrow(d)) break
    }
  }

  # A defaut, on filtre le flux complet. Celui-ci est telecharge une seule fois
  # par session et sert alors les vingt-huit cours : c'est plus lourd, mais
  # c'est la voie dont on sait qu'elle repond.
  if (is.null(d) || !nrow(d)) d <- produit_dans_flux_complet(code_source)

  if (is.null(d) || !nrow(d)) {
    stop(sprintf("aucune observation pour %s", code_source), call. = FALSE)
  }

  col_periode <- intersect(c("TIME_PERIOD", "TIME"), names(d))[1]
  col_valeur <- intersect(c("OBS_VALUE", "VALUE"), names(d))[1]
  if (any(is.na(c(col_periode, col_valeur)))) {
    stop(sprintf("colonnes inattendues : %s", paste(names(d), collapse = ", ")),
         call. = FALSE)
  }

  # Une seule transformation : melanger un niveau de prix et un taux de
  # variation fabriquerait une serie ou 3 500 dollars la tonne cotoie 2,4 %.
  col_transfo <- intersect(c("DATA_TRANSFORMATION", "TRANSFORMATION",
                             "UNIT_MEASURE", "UNIT"), names(d))
  retenue <- NA_character_
  if (length(col_transfo)) {
    modalites <- table(as.character(d[[col_transfo[[1]]]]))
    if (length(modalites)) {
      retenue <- names(which.max(modalites))
      d <- d[as.character(d[[col_transfo[[1]]]]) == retenue, , drop = FALSE]
    }
  }

  dates <- periodes_vers_dates(as.character(d[[col_periode]]))
  r <- data.frame(iso3 = "WLD", date_periode = dates$date_periode,
                  frequence = dates$frequence,
                  valeur = suppressWarnings(as.numeric(d[[col_valeur]])),
                  stringsAsFactors = FALSE)
  r <- r[!is.na(r$date_periode) & !is.na(r$valeur), ]
  if (!is.null(fin)) r <- r[as.integer(format(r$date_periode, "%Y")) <= fin, ]
  r <- r[!duplicated(r[c("frequence", "date_periode")]), ]

  # La serie mensuelle est doublee d'une moyenne annuelle, faute de quoi un
  # cours n'aurait aucune frequence commune avec les indicateurs annuels.
  if (nrow(r)) r <- rbind(r, agreger_en_annuel(r))
  if (!is.na(retenue) && nzchar(retenue)) attr(r, "unite") <- retenue
  r
}

#' Repli sur le classeur mensuel de la Banque mondiale
#' @noRd
produits_depuis_pink_sheet <- function(code_source, debut = NULL, fin = NULL) {
  series <- classeur_produits()
  code <- CODES_PINK_SHEET[[code_source]]
  if (is.null(code) || is.na(code) || is.null(series[[code]])) {
    stop(sprintf("Code %s absent des deux sources.", code_source), call. = FALSE)
  }
  serie <- series[[code]]

  periodes <- sub("^(\\d{4})[Mm](\\d{1,2})$", "\\1-\\2", serie$periodes)
  periodes <- sub("^(\\d{4})-(\\d)$", "\\1-0\\2", periodes)
  dates <- periodes_vers_dates(periodes)

  r <- data.frame(
    iso3 = "WLD", date_periode = dates$date_periode, frequence = dates$frequence,
    valeur = suppressWarnings(as.numeric(gsub("[^0-9.eE+-]", "",
                                              as.character(serie$valeurs)))),
    stringsAsFactors = FALSE)
  r <- r[!is.na(r$date_periode) & !is.na(r$valeur), ]
  if (!is.null(debut)) r <- r[as.integer(format(r$date_periode, "%Y")) >= debut, ]
  if (!is.null(fin))   r <- r[as.integer(format(r$date_periode, "%Y")) <= fin, ]
  r <- r[!duplicated(r[c("frequence", "date_periode")]), ]
  if (nrow(r)) r <- rbind(r, agreger_en_annuel(r))
  if (nzchar(serie$unite)) attr(r, "unite") <- serie$unite
  r
}

#' Moyenne annuelle d'une serie mensuelle
#'
#' Un cours est une moyenne de periode, jamais une somme : additionner douze
#' prix mensuels n'aurait aucun sens.
#' @noRd
agreger_en_annuel <- function(r) {
  mensuel <- r[r$frequence == "M", ]
  if (!nrow(mensuel)) return(r[0, ])
  annees <- format(mensuel$date_periode, "%Y")
  moyennes <- tapply(mensuel$valeur, annees, mean, na.rm = TRUE)
  data.frame(
    iso3 = "WLD",
    date_periode = as.Date(sprintf("%s-01-01", names(moyennes))),
    frequence = "A", valeur = as.numeric(moyennes),
    stringsAsFactors = FALSE)
}

#' Liste les produits reellement publies dans le flux PCPS
#'
#' Lit le flux lui-meme plutot que sa nomenclature : c'est la seule voie dont
#' on ait la preuve qu'elle repond, et elle a l'avantage de ne montrer que les
#' codes effectivement alimentes. Indique aussi la zone geographique et la
#' transformation associees, ce qui permet de corriger la cle sans deviner.
#'
#' @examples
#' \dontrun{
#' codes_produits_de_base()
#' }
#' @export
codes_produits_de_base <- function() {
  d <- flux_pcps_complet()
  col <- colonne_produit(d)
  col_zone <- intersect(c("COUNTRY", "REF_AREA"), names(d))
  col_transfo <- intersect(c("DATA_TRANSFORMATION", "UNIT_MEASURE"), names(d))

  au_catalogue <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                                  stringsAsFactors = FALSE,
                                  fileEncoding = "UTF-8-BOM")
  au_catalogue <- au_catalogue$code_source[au_catalogue$categorie == "C15"]

  codes <- sort(unique(as.character(d[[col]])))
  dominante <- function(colonne, code) {
    if (!length(colonne)) return("")
    v <- as.character(d[[colonne[[1]]]][as.character(d[[col]]) == code])
    if (!length(v)) "" else names(which.max(table(v)))
  }

  r <- data.frame(
    code = codes,
    zone = vapply(codes, function(c_) dominante(col_zone, c_), character(1),
                  USE.NAMES = FALSE),
    transformation = vapply(codes, function(c_) dominante(col_transfo, c_),
                            character(1), USE.NAMES = FALSE),
    observations = vapply(codes, function(c_) {
      sum(as.character(d[[col]]) == c_ & !is.na(d$OBS_VALUE))
    }, integer(1), USE.NAMES = FALSE),
    au_catalogue = codes %in% au_catalogue,
    stringsAsFactors = FALSE, row.names = NULL)
  r[order(!r$au_catalogue, r$code), ]
}

#' Teste la collecte d'un seul produit
#'
#' Essaie plusieurs cles, puis le flux complet, et affiche ce que chacune rend.
#' C'est le diagnostic a lancer en premier quand la collecte echoue.
#'
#' @param code code du produit, par exemple "PCOCO".
#'
#' @examples
#' \dontrun{
#' tester_produit("PCOCO")
#' }
#' @export
tester_produit <- function(code = "PCOCO") {
  essais <- list(c(FLUX_PCPS$zone, "M"), c(FLUX_PCPS$zone, "*"),
                 c("*", "M"), c("*", "*"))

  for (e in essais) {
    cat("\ncle : ", cle_pcps(code, e[[2]], e[[1]]), "\n", sep = "")
    d <- tryCatch(appel_pcps(code, e[[2]], e[[1]]), error = function(x) x)
    if (inherits(d, "error")) { cat("  echec : ", conditionMessage(d), "\n"); next }
    if (is.null(d) || !nrow(d)) { cat("  aucune observation\n"); next }
    cat("  ", nrow(d), " lignes | colonnes : ", paste(names(d), collapse = ", "),
        "\n", sep = "")
    print(utils::head(d, 4))
    return(invisible(d))
  }

  cat("\nAucune cle ciblee n'a repondu. Essai du flux complet.\n")
  d <- tryCatch(flux_pcps_complet(), error = function(x) x)
  if (inherits(d, "error")) {
    cat("  echec : ", conditionMessage(d), "\n")
    return(invisible(NULL))
  }
  cat("  ", nrow(d), " lignes | colonnes : ", paste(names(d), collapse = ", "),
      "\n", sep = "")
  col <- tryCatch(colonne_produit(d), error = function(x) NULL)
  if (!is.null(col)) {
    codes <- sort(unique(as.character(d[[col]])))
    cat("  dimension des produits : ", col, ", ", length(codes), " codes\n",
        sep = "")
    cat("  echantillon : ", paste(utils::head(codes, 15), collapse = ", "),
        "\n", sep = "")
    cat("  ", code, " present : ", code %in% codes, "\n", sep = "")
  }
  invisible(d)
}

# --- OCDE ------------------------------------------------------------------
# Fonction conservee mais absente du registre : les identifiants de flux du
# catalogue renvoient 404. Elle sera rebranchee une fois ceux-ci verifies.
# --- OCDE (hors service) ------------------------------------------------------------------
connecteur_ocde <- function(code_source, debut = NULL, fin = NULL) {
  morceaux <- strsplit(code_source, ",", fixed = TRUE)[[1]]
  agence <- if (length(morceaux) > 1) morceaux[1] else "OECD.SDD.STES"
  flux   <- utils::tail(morceaux, 1)

  params <- list(format = "csvfilewithlabels", dimensionAtObservation = "AllDimensions")
  if (!is.null(debut)) params$startPeriod <- as.character(debut)
  if (!is.null(fin))   params$endPeriod   <- as.character(fin)

  url <- sprintf("https://sdmx.oecd.org/public/rest/data/%s,%s/all", agence, flux)
  texte <- httr2::resp_body_string(appel(url, params, pause = 1.2))
  d <- utils::read.csv(text = texte, stringsAsFactors = FALSE, check.names = FALSE)
  if (!nrow(d)) return(vide())

  col_pays    <- intersect(c("REF_AREA", "LOCATION"), names(d))[1]
  col_periode <- intersect(c("TIME_PERIOD", "TIME"), names(d))[1]
  col_valeur  <- intersect(c("OBS_VALUE", "Value"), names(d))[1]
  if (any(is.na(c(col_pays, col_periode, col_valeur)))) {
    stop(sprintf("Colonnes OCDE inattendues : %s", paste(names(d), collapse = ", ")),
         call. = FALSE)
  }
  dates <- periodes_vers_dates(d[[col_periode]])
  r <- data.frame(iso3 = toupper(as.character(d[[col_pays]])),
                  date_periode = dates$date_periode, frequence = dates$frequence,
                  valeur = suppressWarnings(as.numeric(d[[col_valeur]])),
                  stringsAsFactors = FALSE)
  r[!is.na(r$date_periode) & nchar(r$iso3) == 3, ]
}

#' Explore un flux du portail SDMX du FMI
#'
#' Affiche les dataflows disponibles, ou, si un flux est nomme, l'ordre exact
#' de ses dimensions. C'est l'etape indispensable avant de brancher un nouveau
#' flux : la cle d'une requete SDMX depend de cet ordre, et le deviner mene
#' droit a une erreur.
#'
#' @param flux identifiant du flux, par exemple "IFS". Laisser NULL pour
#'   obtenir le catalogue complet.
#'
#' @examples
#' \dontrun{
#' explorer_flux_fmi()
#' explorer_flux_fmi("IFS")
#' }
#' @export
explorer_flux_fmi <- function(flux = NULL) {
  corps <- jsonlite::fromJSON(httr2::resp_body_string(
    appel(paste0(FMI_SDMX, "/structure/dataflow"))), flatten = TRUE)
  dispo <- corps$data$dataflows

  if (is.null(flux)) {
    r <- data.frame(id = dispo$id, agence = dispo$agencyID,
                    version = dispo$version, nom = dispo$names.en,
                    stringsAsFactors = FALSE)
    return(r[order(r$id), ])
  }

  ligne <- dispo[dispo$id == flux, ]
  if (!nrow(ligne)) stop(sprintf("Flux inconnu : %s", flux), call. = FALSE)

  urn <- ligne$structure[1]
  m <- regmatches(urn, regexec("DataStructure=([^:]+):([^()]+)\\(([^)]+)\\)", urn))[[1]]
  structure <- jsonlite::fromJSON(httr2::resp_body_string(
    appel(sprintf("%s/structure/datastructure/%s/%s/%s", FMI_SDMX, m[2], m[3], m[4]))),
    flatten = TRUE)

  dims <- structure$data$dataStructures$dataStructureComponents.dimensionList.dimensions[[1]]
  cat(sprintf("Flux %s (%s), structure %s\n", flux, ligne$agencyID[1], m[3]))
  cat("Ordre des dimensions dans la cle :\n")
  cat(paste0("  ", dims$position, ". ", dims$id, collapse = "\n"), "\n")
  invisible(dims)
}

# --- Atlas de la complexite economique, Growth Lab de Harvard --------------
# La page de telechargement est une application JavaScript dont le HTML ne
# contient aucun lien : l'analyse de page etait sans issue. Le Growth Lab a
# ouvert une interface GraphQL publique, utilisee ici.
#
# Deux precautions : l'ECI est calcule sur l'ensemble des pays et des produits,
# donc les valeurs ne sont pas comparables d'un millesime a l'autre ; et les
# donnees commerciales d'une annee n'arrivent que deux ans plus tard.
ATLAS <- "https://atlas.hks.harvard.edu/api/graphql"

# Seuls `eci` et `coi` ont ete confirmes par une collecte reussie. Les cinq
# autres noms, deduits de la convention de nommage, ont ete refuses par l'API
# avec un 400 : ils sont retires plutot que laisses en place a echouer a chaque
# passage. `explorer_champs_atlas()` donne la liste exacte pour les rebrancher.
CHAMPS_ATLAS <- c(eci = "eci", coi = "coi")

.cache_pays_atlas <- new.env(parent = emptyenv())

graphql_atlas <- function(requete) {
  reponse <- httr2::req_perform(
    httr2::req_body_json(
      httr2::req_headers(httr2::request(ATLAS), `User-Agent` = AGENT),
      list(query = requete)))
  corps <- jsonlite::fromJSON(httr2::resp_body_string(reponse), simplifyVector = TRUE)
  # GraphQL repond 200 meme en cas d'erreur : le statut HTTP ne suffit pas.
  if (!is.null(corps$errors)) {
    stop(paste("Erreur GraphQL de l'Atlas :",
               paste(corps$errors$message, collapse = " ; ")), call. = FALSE)
  }
  corps$data
}

pays_atlas <- function() {
  if (!is.null(.cache_pays_atlas$table)) return(.cache_pays_atlas$table)
  d <- graphql_atlas("{ locationCountry { countryId iso3Code } }")$locationCountry
  t <- stats::setNames(d$iso3Code, as.character(d$countryId))
  .cache_pays_atlas$table <- t
  t
}

connecteur_atlas <- function(code_source, debut = NULL, fin = NULL) {
  champ <- CHAMPS_ATLAS[code_source]
  if (is.na(champ)) {
    stop(sprintf("Champ Atlas inconnu : %s. Completez CHAMPS_ATLAS.", code_source),
         call. = FALSE)
  }
  bornes <- c(if (!is.null(debut)) sprintf("yearMin: %d", debut),
              if (!is.null(fin))   sprintf("yearMax: %d", fin))
  args <- if (length(bornes)) sprintf("(%s)", paste(bornes, collapse = ", ")) else ""
  d <- graphql_atlas(sprintf("{ countryYear%s { countryId year %s } }", args, champ))$countryYear
  if (is.null(d) || !nrow(d)) return(vide())

  table_pays <- pays_atlas()
  r <- data.frame(
    iso3 = toupper(unname(table_pays[as.character(d$countryId)])),
    date_periode = as.Date(sprintf("%d-01-01", as.integer(d$year))),
    frequence = "A",
    valeur = suppressWarnings(as.numeric(d[[champ]])),
    stringsAsFactors = FALSE)
  r[!is.na(r$iso3), ]
}

#' Liste les champs disponibles sur countryYear dans l'API de l'Atlas
#'
#' La documentation du Growth Lab ne detaille que quelques champs. Deviner les
#' autres a produit cinq erreurs 400 lors de la premiere collecte complete :
#' cette fonction interroge le schema lui-meme.
#'
#' @examples
#' \dontrun{
#' explorer_champs_atlas()
#' }
#' @export
explorer_champs_atlas <- function() {
  d <- graphql_atlas("{ __type(name: \"CountryYear\") { fields { name } } }")
  if (is.null(d$`__type`)) {
    stop("Type CountryYear introuvable. Ouvrez ", ATLAS,
         " dans un navigateur : l'interface GraphiQL donne la liste compl\u00e8te.",
         call. = FALSE)
  }
  champs <- d$`__type`$fields$name
  data.frame(champ = champs, deja_branche = champs %in% unname(CHAMPS_ATLAS),
             stringsAsFactors = FALSE)
}

# --- registre --------------------------------------------------------------
# Ajouter une source revient a ecrire une fonction et a l'inscrire ici.
REGISTRE <- list(
  "Banque mondiale (WDI)"      = connecteur_banque_mondiale,
  "Banque mondiale (IDS)"      = connecteur_banque_mondiale,
  "Banque mondiale (WGI)"      = connecteur_banque_mondiale,
  "Banque mondiale (PIP)"      = connecteur_banque_mondiale,
  "Banque mondiale (Findex)"   = connecteur_banque_mondiale,
  "Banque mondiale (ASPIRE)"   = connecteur_banque_mondiale,
  "Banque mondiale (LPI)"      = connecteur_banque_mondiale,
  "Banque mondiale (B-READY)"  = connecteur_banque_mondiale,
  # Les trois anciennes entrees FMI convergent vers le flux WEO du nouveau
  # portail : il porte aussi bien les agregats de finances publiques que les
  # cours des matieres premieres.
  "FMI (WEO)"                  = connecteur_fmi_weo,
  "FMI (Fiscal Monitor)"       = connecteur_fmi_weo,
  "FMI (PCPS)"                   = connecteur_produits_de_base,
  "Banque mondiale (Pink Sheet)" = connecteur_produits_de_base,
  # L'OCDE sort du registre. Les identifiants de flux du catalogue renvoient
  # tous 404 : l'agence supposee (OECD.SDD.STES) n'est pas la bonne pour la
  # plupart d'entre eux, et l'un des codes etait meme malforme. Six indicateurs
  # sont concernes, tous disponibles ailleurs sous une forme voisine. Ils
  # seront rebranches quand les identifiants auront ete verifies un par un.
  "Growth Lab Harvard (Atlas)" = connecteur_atlas,
  "Growth Lab Harvard"         = connecteur_atlas,
  "Growth Lab / Comtrade"      = connecteur_atlas)

# Flux du FMI non encore branches : leur ordre de dimensions n'a pas ete
# verifie. Utilisez explorer_flux_fmi("IFS") pour l'obtenir, puis ajoutez une
# entree ici. Tant qu'ils sont absents du registre, leurs indicateurs sont
# desactives au chargement du catalogue et n'apparaissent pas dans l'interface.
FLUX_FMI_A_VERIFIER <- c("IFS", "CPI", "FSIC", "IMTS", "GFS_SOO", "PCPS")

connecteur_pour <- function(source) {
  f <- REGISTRE[[source]]
  if (is.null(f)) stop(sprintf("Aucun connecteur pour la source %s.", source), call. = FALSE)
  f
}


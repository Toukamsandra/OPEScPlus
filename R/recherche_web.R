# ---------------------------------------------------------------------------
# Recherche sur le web, restreinte a des sources choisies.
#
# Pourquoi un service tiers plutot qu'un moissonnage maison. Interroger
# directement un moteur de recherche depuis un script est bloque par tous les
# grands moteurs, et le peu qui passe casse a la premiere refonte de page. Un
# moissonnage des sites un par un demanderait autant d'analyseurs que de sites,
# chacun a refaire a chaque changement de maquette. Aucune des deux voies ne
# tient dans la duree.
#
# Le moteur de recherche programmable de Google resout exactement ce probleme :
# il permet de definir un ensemble ferme de sites et de n'y chercher que la.
# Les resultats sont ceux d'un vrai moteur, titre et extrait compris, mais
# l'index est restreint aux sources retenues. C'est « comme Google, mais
# specifique », au sens propre.
#
# La clef est facultative. Sans elle, la plateforme retombe sur les liens de
# recherche vers chaque site, qui fonctionnent sans configuration.
# ---------------------------------------------------------------------------

API_RECHERCHE <- "https://www.googleapis.com/customsearch/v1"

.cache_web <- new.env(parent = emptyenv())

#' Identifiants du moteur de recherche
#'
#' Lus dans les variables d'environnement `OPESC_CSE_CLE` et `OPESC_CSE_ID`,
#' ou dans le fichier de configuration. Les garder hors du code est une
#' precaution ordinaire : une clef versionnee finit par circuler.
#' @noRd
identifiants_recherche <- function() {
  cle <- Sys.getenv("OPESC_CSE_CLE", "")
  id <- Sys.getenv("OPESC_CSE_ID", "")
  if (!nzchar(cle)) {
    cle <- tryCatch(get_golem_config("cse_cle") %||% "", error = function(e) "")
  }
  if (!nzchar(id)) {
    id <- tryCatch(get_golem_config("cse_id") %||% "", error = function(e) "")
  }
  list(cle = as.character(cle), id = as.character(id))
}

#' Mode de recherche disponible
#'
#' Trois etats, selon ce qui est configure.
#'
#'   "aucun"    ni clef ni identifiant : seuls les acces aux sources sont
#'              proposes ;
#'   "widget"   identifiant seul : le moteur de Google est integre a la page.
#'              Il apporte sa propre barre et ses propres onglets, sans clef ni
#'              quota, mais son affichage lui appartient ;
#'   "api"      clef et identifiant : la plateforme interroge le service et
#'              met en forme les resultats elle-meme, avec ses onglets, sa
#'              definition et ses indicateurs.
#'
#' Le mode widget est le plus rapide a mettre en place : il ne demande que
#' l'identifiant, obtenu des la creation du moteur.
#' @export
mode_recherche <- function() {
  ids <- identifiants_recherche()
  if (nzchar(ids$cle) && nzchar(ids$id)) return("api")
  if (nzchar(ids$id)) return("widget")
  "aucun"
}

#' La recherche sur le web est-elle configuree ?
#' @export
recherche_web_active <- function() {
  identical(mode_recherche(), "api")
}

#' Le moteur de Google est-il integre a la page ?
#' @export
widget_recherche_actif <- function() {
  identical(mode_recherche(), "widget")
}

#' Balises du moteur de recherche integre
#'
#' Le script est charge une seule fois et rend lui-meme le bloc `gcse-search`
#' present dans la page. Le bloc est donc statique et non produit par un
#' `renderUI` : un element insere apres coup ne serait pas rendu, faute d'etre
#' present au chargement du script.
#' @noRd
balises_widget <- function() {
  id <- identifiants_recherche()$id
  if (!nzchar(id)) return(NULL)
  shiny::tagList(
    shiny::tags$script(async = NA,
      src = sprintf("https://cse.google.com/cse.js?cx=%s", id)),
    shiny::div(class = "gcse-search"))
}

#' Domaines des sources retenues
#'
#' Extraits des adresses de la table des sources : la liste des sites fiables
#' sert donc a la fois a construire les liens et a filtrer les resultats, sans
#' risque de divergence entre les deux.
#' @noRd
domaines_fiables <- function() {
  if (!is.null(.cache_web$domaines)) return(.cache_web$domaines)
  urls <- sites_fiables()$gabarit
  d <- sub("^https?://", "", urls)
  d <- sub("/.*$", "", d)
  d <- unique(sub("^www\\.", "", tolower(d)))
  .cache_web$domaines <- d
  d
}

#' Liste des domaines a declarer dans le moteur de recherche
#'
#' A copier dans la console du moteur programmable, rubrique des sites a
#' inclure. C'est cette liste qui garantit qu'aucun resultat ne vient d'ailleurs.
#'
#' @examples
#' \dontrun{
#' domaines_pour_moteur()
#' }
#' @export
domaines_pour_moteur <- function() {
  d <- sort(domaines_fiables())
  cat("Declarez ces", length(d), "domaines dans le moteur de recherche,\n")
  cat("en mode « rechercher uniquement sur les sites inclus » :\n\n")
  cat(paste0("  ", d, "/*", collapse = "\n"), "\n")
  invisible(d)
}

#' Un domaine fait-il partie des sources retenues ?
#'
#' Les sous-domaines sont acceptes : `documents.worldbank.org` releve bien de
#' `worldbank.org`. Le controle est fait meme quand le moteur est deja restreint
#' aux sites inclus, par simple prudence : une erreur de configuration ne doit
#' pas suffire a faire entrer une source quelconque.
#' @noRd
domaine_retenu <- function(domaine, domaines = domaines_fiables()) {
  d <- tolower(sub("^www\\.", "", domaine))
  any(d == domaines | endsWith(d, paste0(".", domaines)))
}

#' Interroge le web sur un terme
#'
#' @param requete texte recherche.
#' @param nombre nombre de resultats souhaites, dix au maximum par appel.
#' @param onglet "tout", "images", "actualite" ou "videos". Chacun se traduit
#'   par des parametres differents envoyes au moteur : les images par un type
#'   de recherche dedie, l'actualite par une restriction de date et un filtrage
#'   sur les sources de presse, les videos par les pages qui en hebergent.
#'
#' @return un tableau (titre, extrait, url, domaine, vignette), ou NULL si la
#'   recherche n'est pas configuree ou n'a rien rendu.
#' @export
rechercher_web <- function(requete, nombre = 10L, onglet = "tout") {
  requete <- trimws(requete)
  if (!nzchar(requete) || !recherche_web_active()) return(NULL)

  # Le service est limite en nombre d'appels par jour : une meme recherche
  # relancee dans la session ne consomme pas un second appel.
  cle_cache <- paste(tolower(requete), nombre, onglet, sep = "|")
  if (!is.null(.cache_web[[cle_cache]])) return(.cache_web[[cle_cache]])

  ids <- identifiants_recherche()
  params <- list(key = ids$cle, cx = ids$id, q = requete,
                 num = min(as.integer(nombre), 10L), hl = langue_courante())

  if (identical(onglet, "images")) {
    params$searchType <- "image"
  } else if (identical(onglet, "actualite")) {
    # Restriction aux douze derniers mois et tri par date : sans cela, une
    # recherche d'actualite remonte des pages de fond, parfois anciennes.
    params$dateRestrict <- "y1"
    params$sort <- "date"
  } else if (identical(onglet, "videos")) {
    # Le moteur n'a pas de type video. On cible les pages qui en hebergent en
    # ajoutant le terme a la requete, puis on filtre sur l'adresse.
    params$q <- paste(requete, "video")
  }

  reponse <- tryCatch(appel(API_RECHERCHE, params), error = function(e) e)
  if (inherits(reponse, "error")) return(NULL)

  corps <- tryCatch(
    jsonlite::fromJSON(httr2::resp_body_string(reponse), flatten = TRUE),
    error = function(e) NULL)
  items <- corps$items
  if (is.null(items) || !NROW(items)) return(NULL)

  vignette <- rep("", NROW(items))
  if (identical(onglet, "images")) {
    if (!is.null(items$image.thumbnailLink)) vignette <- as.character(items$image.thumbnailLink)
    else vignette <- as.character(items$link)
  } else if (!is.null(items$pagemap.cse_thumbnail)) {
    vignette <- vapply(items$pagemap.cse_thumbnail, function(x) {
      if (is.null(x) || !NROW(x)) "" else as.character(x$src[[1]])
    }, character(1))
  }

  r <- data.frame(
    titre = as.character(items$title),
    extrait = as.character(if (!is.null(items$snippet)) items$snippet else ""),
    url = as.character(if (identical(onglet, "images") && !is.null(items$image.contextLink))
                         items$image.contextLink else items$link),
    domaine = as.character(if (!is.null(items$displayLink)) items$displayLink
                           else sub("^https?://([^/]+).*$", "\\1", items$link)),
    vignette = vignette,
    stringsAsFactors = FALSE)

  r <- r[vapply(r$domaine, domaine_retenu, logical(1)), , drop = FALSE]

  # L'actualite se limite aux sources de presse et de communiques : un rapport
  # de fond bien classe n'est pas une actualite.
  if (identical(onglet, "actualite") && nrow(r)) {
    presse <- domaines_par_type("actualite")
    r <- r[vapply(r$domaine, domaine_retenu, logical(1), presse), , drop = FALSE]
  }
  if (identical(onglet, "videos") && nrow(r)) {
    r <- r[grepl("video|watch|multimedia|webcast|replay", r$url, ignore.case = TRUE), ,
           drop = FALSE]
  }

  r$extrait <- gsub("\\s+", " ", r$extrait)
  if (!nrow(r)) return(NULL)

  .cache_web[[cle_cache]] <- r
  r
}

#' Organisme correspondant a un domaine, quand il est connu
#' @noRd
organisme_du_domaine <- function(domaine) {
  s <- sites_fiables()
  hotes <- sub("^https?://", "", s$gabarit)
  hotes <- sub("^www\\.", "", tolower(sub("/.*$", "", hotes)))
  d <- tolower(sub("^www\\.", "", domaine))
  i <- which(d == hotes | endsWith(d, paste0(".", hotes)))
  if (!length(i)) return("")
  s$organisme[[i[[1]]]]
}

#' Domaines des sources d'un type donne
#' @noRd
domaines_par_type <- function(type) {
  s <- sites_fiables()
  urls <- s$gabarit[s$type %in% type]
  d <- sub("/.*$", "", sub("^https?://", "", urls))
  unique(sub("^www\\.", "", tolower(d)))
}

#' Definition d'une notion economique
#'
#' Le glossaire est maintenu dans le projet plutot que tire d'une encyclopedie
#' generaliste : la definition est ainsi verifiable, stable dans le temps, et
#' formulee dans le vocabulaire des comptes nationaux.
#'
#' La correspondance est souple : « croissance » retrouve « Croissance
#' economique », et « PIB » retrouve « Produit interieur brut » par ses
#' initiales.
#'
#' @param requete terme recherche.
#' @return liste (terme, definition, categorie) ou NULL.
#' @noRd
definir <- function(requete) {
  d <- glossaire()
  if (!nrow(d)) return(NULL)

  q <- normaliser(requete)
  termes <- normaliser(d$terme)

  # Correspondance exacte, puis inclusion, puis initiales.
  i <- which(termes == q)
  if (!length(i)) i <- which(vapply(termes, function(t) grepl(t, q, fixed = TRUE),
                                    logical(1)))
  if (!length(i)) i <- which(vapply(termes, function(t) grepl(q, t, fixed = TRUE),
                                    logical(1)) & nchar(q) >= 4)
  if (!length(i)) {
    initiales <- vapply(strsplit(termes, " "), function(m) {
      paste(substr(m[nchar(m) > 2], 1, 1), collapse = "")
    }, character(1))
    i <- which(initiales == gsub(" ", "", q))
  }
  if (!length(i)) return(NULL)

  # Le terme le plus proche en longueur : « croissance » doit rendre
  # « Croissance economique » et non une notion qui la contient.
  i <- i[which.min(abs(nchar(termes[i]) - nchar(q)))]
  colonne <- if (langue_courante() == "en") "definition_en" else "definition_fr"
  # La source est celle du manuel dont la definition est tiree, non le nom de
  # la plateforme : « Glossaire OPESc+ » n'apprenait rien et laissait croire a
  # une definition maison, alors qu'elles reprennent toutes un texte de
  # reference.
  # `source` peut manquer d'un glossaire ancien, et la valeur peut etre vide.
  # Elle est ramenee a une chaine dans tous les cas : une condition posee plus
  # loin sur une valeur nulle interrompait l'affichage de toute la recherche,
  # `nzchar(NULL)` rendant un vecteur vide dont `if` ne sait que faire.
  source <- if ("source" %in% names(d)) as.character(d$source[[i]]) else ""
  if (is.na(source) || !nzchar(trimws(source))) source <- "Glossaire OPESc+"
  list(terme = d$terme[[i]], definition = d[[colonne]][[i]],
       categorie = d$categorie[[i]], source = source)
}

.cache_glossaire <- new.env(parent = emptyenv())

#' @noRd
glossaire <- function() {
  if (!is.null(.cache_glossaire$d)) return(.cache_glossaire$d)
  chemin <- app_sys("extdata/definitions.csv")
  d <- if (nzchar(chemin) && file.exists(chemin)) {
    utils::read.csv(chemin, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  } else {
    data.frame(terme = character(), categorie = character(),
               definition_fr = character(), definition_en = character(),
               stringsAsFactors = FALSE)
  }
  .cache_glossaire$d <- d
  d
}

#' Propositions de recherche a partir des premieres lettres saisies
#'
#' Tirees du glossaire, des categories et des libelles d'indicateurs : les
#' propositions portent donc sur ce que la plateforme sait effectivement
#' traiter, et non sur un dictionnaire general.
#'
#' @param debut texte deja saisi.
#' @param con connexion, pour puiser dans le catalogue.
#' @param limite nombre de propositions.
#' @noRd
propositions <- function(debut, con = NULL, limite = 8L) {
  debut <- trimws(debut)
  if (nchar(debut) < 2) return(character(0))
  q <- normaliser(debut)

  candidats <- glossaire()$terme
  if (!is.null(con)) {
    candidats <- c(candidats,
      DBI::dbGetQuery(con, "SELECT libelle FROM categorie")$libelle,
      DBI::dbGetQuery(con,
        "SELECT DISTINCT libelle FROM indicateur WHERE actif = 1")$libelle)
  }
  candidats <- unique(candidats[nzchar(candidats)])
  normalises <- normaliser(candidats)

  # Ceux qui commencent par la saisie d'abord, ceux qui la contiennent ensuite.
  debut_ok <- startsWith(normalises, q)
  contient <- grepl(q, normalises, fixed = TRUE) & !debut_ok
  ordonnes <- c(candidats[debut_ok][order(nchar(candidats[debut_ok]))],
                candidats[contient][order(nchar(candidats[contient]))])
  utils::head(ordonnes, limite)
}

#' Enregistre les identifiants du moteur de recherche
#'
#' Les ecrit dans le fichier `.Renviron` de l'utilisateur, que R lit au
#' demarrage, et les active immediatement pour la session en cours. Cela evite
#' d'editer un fichier a la main et de se tromper de nom de variable.
#'
#' Le fichier `.Renviron` est prefere au code : une clef versionnee finit
#' toujours par circuler.
#'
#' @param cle clef d'API obtenue dans la console Google Cloud.
#' @param id identifiant du moteur de recherche programmable.
#'
#' @examples
#' \dontrun{
#' configurer_recherche("AIza...", "a1b2c3d4e5f6g7h8i")
#' }
#' @export
configurer_recherche <- function(cle = "", id) {
  cle <- trimws(as.character(cle))
  id <- trimws(as.character(id))
  if (!nzchar(id)) {
    stop("L'identifiant du moteur est requis.", call. = FALSE)
  }

  Sys.setenv(OPESC_CSE_CLE = cle, OPESC_CSE_ID = id)

  chemin <- file.path(Sys.getenv("HOME", path.expand("~")), ".Renviron")
  lignes <- if (file.exists(chemin)) readLines(chemin, warn = FALSE) else character(0)
  # Les anciennes valeurs sont retirees plutot que doublees : R retient la
  # premiere occurrence, une ligne ajoutee a la suite resterait sans effet.
  lignes <- lignes[!grepl("^OPESC_CSE_(CLE|ID)=", lignes)]
  lignes <- c(lignes, sprintf("OPESC_CSE_CLE=%s", cle), sprintf("OPESC_CSE_ID=%s", id))
  writeLines(lignes, chemin)

  message("Identifiants enregistres dans ", chemin, ".")
  message("Ils sont actifs des maintenant, et le resteront aux prochains demarrages.")
  if (!nzchar(cle)) {
    message("\nClef absente : le moteur sera integre a la page, avec sa propre ",
            "barre\net ses propres onglets. Ajoutez une clef pour que la ",
            "plateforme mette\nelle-meme les resultats en forme.")
  }
  invisible(verifier_recherche())
}

#' Verifie que la recherche sur le web fonctionne
#'
#' Lance une requete d'essai et rend compte de ce qui se passe. A utiliser
#' apres configuration, ou quand l'onglet ne renvoie rien.
#'
#' @examples
#' \dontrun{
#' verifier_recherche()
#' }
#' @export
verifier_recherche <- function() {
  ids <- identifiants_recherche()
  cat("Clef      :", if (nzchar(ids$cle))
      paste0("presente (", substr(ids$cle, 1, 6), "...)") else "ABSENTE", "\n")
  cat("Moteur    :", if (nzchar(ids$id)) ids$id else "ABSENT", "\n")

  cat("Mode      :", mode_recherche(), "\n")

  if (identical(mode_recherche(), "aucun")) {
    cat("\nLa recherche n'est pas configuree.\n")
    cat("Lancez configurer_recherche(id = \"votre_identifiant\") pour integrer\n")
    cat("le moteur a la page, ou configurer_recherche(cle, id) pour que la\n")
    cat("plateforme mette elle-meme les resultats en forme.\n")
    return(invisible(FALSE))
  }
  if (identical(mode_recherche(), "widget")) {
    cat("\nLe moteur est integre a la page : il apporte sa barre et ses\n")
    cat("onglets. Rien d'autre a verifier ici, ouvrez l'onglet GoogleOPESc+.\n")
    cat("Ajoutez une clef d'API pour l'affichage integre a la plateforme.\n")
    return(invisible(TRUE))
  }

  cat("\nRequete d'essai sur « inflation »...\n")
  # Le cache est vide de force : un essai doit interroger le service, non
  # rendre un resultat garde d'une tentative precedente.
  rm(list = ls(.cache_web), envir = .cache_web)
  r <- rechercher_web("inflation", 5L)

  if (is.null(r) || !nrow(r)) {
    cat("Aucun resultat. Causes possibles, dans l'ordre de frequence :\n")
    cat("  - le moteur n'a aucun domaine declare, ou n'est pas en mode\n")
    cat("    « rechercher uniquement sur les sites inclus » ;\n")
    cat("  - l'API Custom Search n'est pas activee dans le projet Google Cloud ;\n")
    cat("  - la clef est restreinte a une autre API ou a un autre domaine ;\n")
    cat("  - le quota de cent recherches par jour est atteint.\n")
    return(invisible(FALSE))
  }

  cat(nrow(r), "resultats, sur ces sources :\n")
  for (d in unique(r$domaine)) cat("  ", d, "\n")
  invisible(TRUE)
}


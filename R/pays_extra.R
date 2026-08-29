# ---------------------------------------------------------------------------
# Complements sur les pays : code a deux lettres et langues officielles.
#
# Ces informations ne viennent d'aucune des sources statistiques : elles sont
# maintenues a la main dans inst/extdata/pays_extra.csv, qui se corrige sans
# toucher au code. Le code a deux lettres sert a retrouver le drapeau, les
# langues a renseigner la fiche affichee au clic sur la carte.
# ---------------------------------------------------------------------------

.cache_pays_extra <- new.env(parent = emptyenv())

#' Table des complements, chargee une seule fois
#' @noRd
table_pays_extra <- function() {
  if (!is.null(.cache_pays_extra$t)) return(.cache_pays_extra$t)
  chemin <- app_sys("extdata/pays_extra.csv")
  t <- if (nzchar(chemin) && file.exists(chemin)) {
    utils::read.csv(chemin, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  } else {
    data.frame(iso3 = character(), iso2 = character(), langues = character(),
               stringsAsFactors = FALSE)
  }
  .cache_pays_extra$t <- t
  t
}

#' Complements pour un pays
#'
#' @return liste (iso2, langues), avec des valeurs vides si le pays n'est pas
#'   dans la table plutot qu'une erreur : un territoire manquant ne doit pas
#'   faire echouer l'affichage de la carte.
#' @noRd
infos_pays <- function(iso3) {
  t <- table_pays_extra()
  i <- match(toupper(iso3), t$iso3)
  if (is.na(i)) return(list(iso2 = "", langues = ""))
  list(iso2 = t$iso2[[i]], langues = t$langues[[i]])
}

#' Adresse du drapeau d'un pays
#'
#' Les drapeaux sont servis par flagcdn.com, qui les expose par code a deux
#' lettres. Aucun fichier n'est donc distribue avec le paquet.
#' @noRd
url_drapeau <- function(iso2, largeur = 80) {
  if (!nzchar(iso2)) return("")
  sprintf("https://flagcdn.com/w%d/%s.png", largeur, tolower(iso2))
}

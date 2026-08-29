#' Chemin vers un fichier installe avec le paquet
#'
#' Remplace les chemins relatifs de la version precedente : une fois installe,
#' un paquet n'est plus lu depuis le dossier de travail.
#'
#' @param ... elements du chemin, passes a `system.file()`.
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "opescplus")
}

#' Lit une valeur du fichier de configuration
#'
#' @param value cle recherchee.
#' @param config profil actif.
#' @param use_parent remonter aux dossiers parents.
#' @param file fichier de configuration.
#' @noRd
get_golem_config <- function(value,
                             config = Sys.getenv("GOLEM_CONFIG_ACTIVE",
                                                 Sys.getenv("R_CONFIG_ACTIVE", "default")),
                             use_parent = TRUE,
                             file = app_sys("golem-config.yml")) {
  if (is.null(file) || !nzchar(file)) return(NULL)
  config::get(value = value, config = config, file = file, use_parent = use_parent)
}

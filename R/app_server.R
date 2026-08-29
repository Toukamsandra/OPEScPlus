#' Serveur de l'application
#'
#' @param input,output,session objets Shiny.
#' @noRd
app_server <- function(input, output, session) {
  fixer_langue_session(session)

  # Une connexion par session, refermee a la deconnexion. SQLite en mode WAL
  # autorise plusieurs lecteurs simultanes.
  con <- connexion()
  session$onSessionEnded(function() DBI::dbDisconnect(con))

  # `session` est transmis pour que les boutons de l'accueil puissent changer
  # d'onglet : la navigation reste celle de la barre, sans duplication.
  mod_accueil_server("accueil", con, parent = session)
  mod_tableau_bord_server("tdb", con)
  mod_base_donnees_server("base", con)
  mod_collectes_server("collectes", con)
}

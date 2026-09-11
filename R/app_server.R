#' Serveur de l'application
#'
#' @param input,output,session objets Shiny.
#' @noRd
app_server <- function(input, output, session) {
  fixer_langue_session(session)

  # Reprise de session apres une coupure passagere : sans elle, la moindre
  # interruption reseau laisse la page voilee de gris jusqu'a rechargement
  # manuel. Le battement envoye par le navigateur est simplement absorbe ici,
  # il n'a d'autre role que d'empecher la connexion de s'endormir.
  session$allowReconnect(TRUE)
  shiny::observeEvent(input$opesc_pouls, invisible(NULL), ignoreInit = TRUE)

  # Une connexion par session, refermee a la deconnexion. SQLite en mode WAL
  # autorise plusieurs lecteurs simultanes.
  con <- connexion()
  session$onSessionEnded(function() DBI::dbDisconnect(con))

  # `session` est transmis pour que les boutons de l'accueil puissent changer
  # d'onglet : la navigation reste celle de la barre, sans duplication.
  output$bandeau_fraicheur <- shiny::renderUI(bandeau_fraicheur(con))

  mod_accueil_server("accueil", con, parent = session)
  mod_tableau_bord_server("tdb", con)
  mod_base_donnees_server("base", con)
  mod_recherche_server("recherche", con, parent = session)
  mod_collectes_server("collectes", con)
}

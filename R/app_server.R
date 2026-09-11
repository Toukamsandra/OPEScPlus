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

  # Signal partage entre les modules. Une collecte ou un import lance depuis
  # l'onglet Collectes change la base, mais `renderUI` ne se recalcule que si
  # une valeur reactive qu'il lit a change. Sans ce signal, les chiffres de
  # l'accueil restaient ceux de l'ouverture de la session, et il fallait
  # recharger la page pour les voir bouger : de quoi croire que la collecte
  # n'a rien ecrit.
  rafraichir <- shiny::reactiveVal(0)

  # `session` est transmis pour que les boutons de l'accueil puissent changer
  # d'onglet : la navigation reste celle de la barre, sans duplication.
  output$bandeau_fraicheur <- shiny::renderUI({
    rafraichir()
    bandeau_fraicheur(con)
  })

  mod_accueil_server("accueil", con, parent = session, rafraichir = rafraichir)
  mod_tableau_bord_server("tdb", con)
  mod_base_donnees_server("base", con)
  mod_recherche_server("recherche", con, parent = session)
  mod_collectes_server("collectes", con, rafraichir = rafraichir)
}

# ---------------------------------------------------------------------------
# Module Collectes : journal et actualisation par source ou par categorie.
# ---------------------------------------------------------------------------

mod_collectes_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::div(class = "cadre",
    shiny::div(class = "entete-graphique",
      shiny::div(
        shiny::h3(tr("Journal des collectes")),
        shiny::p(class = "meta",
          "Chaque exécution est tracée : sans journal, une collecte silencieusement vide passe inaperçue pendant des mois.")),
      shiny::uiOutput(ns("commandes"))),
    shiny::p(class = "note",
      "Une actualisation complète représente plusieurs centaines d'appels et peut durer une trentaine de minutes. Préférez une catégorie à la fois."),
    DT::DTOutput(ns("journal")))
}

mod_collectes_server <- function(id, con) {
  shiny::moduleServer(id, function(input, output, session) {

    ns <- session$ns
    categories <- lire_categories(con)

    # Sur un deploiement en lecture seule, afficher un bouton qui echouera
    # toujours vaut moins que ne pas l'afficher du tout.
    #
    # Les choix sont poses directement dans le selectInput et non par un
    # updateSelectInput : celui-ci s'executerait avant que renderUI n'ait cree
    # le champ, et n'aurait donc aucun effet. La liste resterait vide.
    output$commandes <- shiny::renderUI({
      if (!base_modifiable()) {
        return(shiny::div(class = "alerte",
          shiny::p("La base est en lecture seule : la collecte n'est pas disponible sur ce déploiement.")))
      }
      shiny::div(class = "outils",
        shiny::selectInput(ns("portee"), NULL, width = "260px",
          choices = c("Tout le catalogue" = "",
                      stats::setNames(categories$code,
                                      paste("Catégorie :", categories$libelle)))),
        shiny::actionButton(ns("lancer"), tr("Actualiser"), class = "btn-opesc",
                            icon = shiny::icon("rotate")))
    })

    rafraichir <- shiny::reactiveVal(0)

    shiny::observeEvent(input$lancer, {
      lignes <- if (is.null(input$portee) || input$portee == "")
        lire_indicateurs(con) else lire_indicateurs(con, input$portee)
      if (!nrow(lignes)) {
        shiny::showNotification("Aucun indicateur dans cette portée.", type = "warning")
        return()
      }
      shiny::withProgress(message = "Collecte en cours", value = 0, {
        res <- collecter(con, lignes, declencheur = "interface",
          avancement = function(i, n, libelle, erreur) {
            shiny::incProgress(1 / n, detail = sprintf("%d/%d : %s", i, n, libelle))
          })
        shiny::showNotification(sprintf("%s : %d ajoutées, %d révisées, %d erreur(s).",
          res$statut, res$creees, res$modifiees, length(res$erreurs)),
          type = if (length(res$erreurs)) "warning" else "message", duration = 12)
      })
      rafraichir(rafraichir() + 1)
    })

    output$journal <- DT::renderDT({
      rafraichir()
      d <- lire_journal(con)
      shiny::validate(shiny::need(nrow(d) > 0, "Aucune collecte enregistrée."))
      affichage <- data.frame(
        Début = d$debut, Fin = d$fin, Déclenchement = d$declencheur,
        Statut = d$statut, Indicateurs = d$nb_indicateurs,
        Ajoutées = d$nb_creees, Révisées = d$nb_modifiees,
        Erreurs = ifelse(is.na(d$message) | d$message == "", "",
                         substr(d$message, 1, 300)),
        stringsAsFactors = FALSE)
      DT::datatable(affichage, rownames = FALSE,
                    options = list(pageLength = 15, scrollX = TRUE, dom = "tip"))
    })
  })
}

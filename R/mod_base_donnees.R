# ---------------------------------------------------------------------------
# Module Base de donnees : consultation et telechargement.
# ---------------------------------------------------------------------------

mod_base_donnees_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "cadre",
      shiny::div(class = "entete-graphique",
        shiny::div(
          shiny::h3(tr("Base de données")),
          shiny::p(class = "meta",
            "Le format tableur est le seul format de téléchargement proposé.")),
        shiny::div(class = "outils",
          shiny::downloadButton(ns("long"), tr("Format long"), class = "btn-opesc"),
          shiny::downloadButton(ns("large"), tr("Tableau croisé"), class = "btn-opesc-clair"))),

      shiny::div(class = "barre-filtres",
        shiny::div(class = "champ",
          shiny::selectInput(ns("categorie"), tr("Catégorie"), choices = NULL, width = "100%")),
        shiny::div(class = "champ champ-large",
          shiny::selectizeInput(ns("indicateurs"), tr("Indicateurs"), choices = NULL,
            multiple = TRUE, width = "100%",
            options = list(placeholder = "Toute la catégorie",
                           plugins = list("remove_button")))),
        shiny::div(class = "champ champ-large",
          shiny::selectizeInput(ns("pays"), tr("Pays"), choices = NULL, multiple = TRUE,
            width = "100%",
            options = list(placeholder = "Tous les pays",
                           plugins = list("remove_button")))),
        shiny::div(class = "champ",
          shiny::selectInput(ns("frequence"), tr("Fréquence"), choices = NULL, width = "100%")),
        shiny::div(class = "champ champ-periode",
          shiny::numericInput(ns("debut"), tr("De"), value = 2000, min = 1950, max = 2100),
          shiny::numericInput(ns("fin"), tr("à"), value = as.integer(format(Sys.Date(), "%Y")),
                              min = 1950, max = 2100))),

      shiny::p(class = "note", shiny::textOutput(ns("compte"), inline = TRUE)),
      DT::DTOutput(ns("tableau"))))
}

mod_base_donnees_server <- function(id, con) {
  shiny::moduleServer(id, function(input, output, session) {

    categories <- lire_categories(con)
    shiny::updateSelectInput(session, "categorie",
      choices = c("Toutes les catégories" = "",
                  stats::setNames(categories$code, categories$libelle)))

    shiny::observe({
      d <- if (is.null(input$categorie) || input$categorie == "")
             lire_indicateurs(con) else lire_indicateurs(con, input$categorie)
      shiny::updateSelectizeInput(session, "indicateurs",
        choices = stats::setNames(d$code_interne, tr(d$libelle)), server = TRUE)
    })

    shiny::observe({
      p <- lire_pays(con)
      shiny::updateSelectizeInput(session, "pays",
        choices = stats::setNames(p$iso3, ifelse(p$est_agregat == 1,
                                                 paste0(p$nom, " (agrégat)"), p$nom)),
        server = TRUE)
    })

    shiny::observe({
      codes <- if (length(input$indicateurs)) input$indicateurs else NULL
      dispo <- if (is.null(codes))
        DBI::dbGetQuery(con, "SELECT DISTINCT frequence FROM observation")$frequence
      else frequences_disponibles(con, codes)
      shiny::updateSelectInput(session, "frequence",
        choices = c(stats::setNames("", tr("Toutes")), choix_frequences(dispo)))
    })

    # La requete est bornee : afficher deux millions de lignes dans un tableau
    # web ne sert personne, et le telechargement porte de toute facon sur la
    # selection complete.
    donnees <- shiny::reactive({
      conditions <- "o.valeur IS NOT NULL"; args <- list()

      if (length(input$indicateurs)) {
        conditions <- paste0(conditions, " AND o.code_interne IN (",
          paste(rep("?", length(input$indicateurs)), collapse = ","), ")")
        args <- c(args, as.list(input$indicateurs))
      } else if (!is.null(input$categorie) && input$categorie != "") {
        conditions <- paste(conditions, "AND i.categorie = ?")
        args <- c(args, list(input$categorie))
      }
      if (length(input$pays)) {
        conditions <- paste0(conditions, " AND o.iso3 IN (",
          paste(rep("?", length(input$pays)), collapse = ","), ")")
        args <- c(args, as.list(input$pays))
      }
      if (!is.null(input$frequence) && input$frequence != "") {
        conditions <- paste(conditions, "AND o.frequence = ?")
        args <- c(args, list(input$frequence))
      }
      if (!is.na(input$debut)) { conditions <- paste(conditions, "AND o.annee >= ?"); args <- c(args, list(input$debut)) }
      if (!is.na(input$fin))   { conditions <- paste(conditions, "AND o.annee <= ?"); args <- c(args, list(input$fin)) }

      requete <- sprintf("
        SELECT COALESCE(p.nom, o.iso3) AS pays, o.iso3, i.libelle, i.unite,
               o.frequence, o.date_periode, o.annee, o.valeur, i.source
        FROM observation o
        JOIN indicateur i ON i.code_interne = o.code_interne
        LEFT JOIN pays p ON p.iso3 = o.iso3
        WHERE %s
        ORDER BY i.libelle, pays, o.date_periode
        LIMIT 200000", conditions)
      DBI::dbGetQuery(con, requete, params = args)
    })

    output$compte <- shiny::renderText({
      n <- nrow(donnees())
      if (!n) return("Aucune observation ne correspond aux filtres. La base est peut-être encore vide.")
      sprintf("%s observations correspondent aux filtres. Les mille premières sont affichées ; le téléchargement porte sur la sélection complète.",
              format(n, big.mark = " "))
    })

    output$tableau <- DT::renderDT({
      d <- utils::head(donnees(), 1000)
      shiny::validate(shiny::need(nrow(d) > 0, "Aucune donnée."))
      affichage <- d[c("pays", "libelle", "frequence", "date_periode", "valeur", "unite", "source")]
      affichage$frequence <- libelle_frequence(affichage$frequence)
      names(affichage) <- c("Pays", "Indicateur", "Fréquence", "Période", "Valeur", "Unité", "Source")
      DT::datatable(affichage, rownames = FALSE, filter = "top",
        options = list(pageLength = 25, scrollX = TRUE, dom = "tip",
                       language = list(url = NULL,
                         paginate = list(previous = "Précédent", `next` = "Suivant"),
                         info = "_START_ à _END_ sur _TOTAL_",
                         emptyTable = "Aucune donnée"))) |>
        DT::formatRound("Valeur", digits = 3)
    })

    output$long <- shiny::downloadHandler(
      filename = function() sprintf("opesc_base_%s.xlsx", horodatage()),
      content = function(f) {
        d <- donnees(); shiny::req(nrow(d) > 0)
        ecrire_classeur(f, d, format_large = FALSE)
      })

    output$large <- shiny::downloadHandler(
      filename = function() sprintf("opesc_base_croise_%s.xlsx", horodatage()),
      content = function(f) {
        d <- donnees(); shiny::req(nrow(d) > 0)
        ecrire_classeur(f, d, format_large = TRUE)
      })
  })
}

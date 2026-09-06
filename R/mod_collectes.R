# ---------------------------------------------------------------------------
# Module Collectes : journal et actualisation par source ou par categorie.
# ---------------------------------------------------------------------------

mod_collectes_ui <- function(id) {
  ns <- shiny::NS(id)

  # Les cadres d'import et de suppression ecrivent en base. En ligne, le
  # systeme de fichiers est en lecture seule : les afficher promettrait une
  # action impossible. Ils sont donc assembles a part, et remplaces par une
  # explication quand la base n'accepte pas l'ecriture.
  modifiable <- base_modifiable()

  journal <- shiny::div(class = "cadre",
    shiny::div(class = "entete-graphique",
      shiny::div(
        shiny::h3(tr("Journal des collectes")),
        shiny::p(class = "meta", tr(paste(
          "Chaque ex\u00e9cution est trac\u00e9e : sans journal, une collecte",
          "silencieusement vide passe inaper\u00e7ue pendant des mois.")))),
      shiny::uiOutput(ns("commandes"))),
    if (modifiable) {
      shiny::p(class = "note", tr(paste(
        "Une actualisation compl\u00e8te repr\u00e9sente plusieurs centaines d'appels et",
        "peut durer une trentaine de minutes. Pr\u00e9f\u00e9rez une cat\u00e9gorie \u00e0 la fois.")))
    } else {
      shiny::p(class = "note", tr(paste(
        "Cette plateforme est publi\u00e9e en lecture seule. Les donn\u00e9es y sont",
        "fig\u00e9es \u00e0 la date de publication : la collecte et l'import restent des",
        "op\u00e9rations locales, men\u00e9es sur le poste qui alimente la base.")))
    },
    DT::DTOutput(ns("journal")))

  if (!modifiable) return(journal)

  shiny::tagList(
    # --- depot d'un fichier ----------------------------------------------
    # Toute source ne se laisse pas interroger par programme : celle des cours
    # de produits de base construit son lien de telechargement en JavaScript.
    # Le depot manuel est donc la seule voie pour ces jeux de donnees, et il a
    # sa place dans l'interface plutot que dans une commande a taper.
    shiny::div(class = "cadre",
      shiny::h3(tr("Importer un fichier")),
      shiny::p(class = "meta", tr(paste(
        "D\u00e9posez un fichier t\u00e9l\u00e9charg\u00e9 depuis un portail statistique. Les",
        "s\u00e9ries qu'il contient rejoignent la cat\u00e9gorie choisie et deviennent",
        "utilisables comme les autres, dans le tableau de bord comme dans la",
        "base."))),
      shiny::div(class = "barre-filtres",
        shiny::div(class = "champ champ-large",
          shiny::fileInput(ns("fichier"), tr("Fichier"), width = "100%",
                           accept = c(".csv", ".xlsx", ".xls"),
                           buttonLabel = tr("Parcourir"),
                           placeholder = tr("Aucun fichier"))),
        shiny::div(class = "champ",
          shiny::selectInput(ns("categorie_import"), tr("Cat\u00e9gorie"),
                             choices = NULL, width = "100%")),
        shiny::div(class = "champ champ-actions",
          shiny::actionButton(ns("importer"), tr("Importer"),
                              class = "btn-opesc", icon = shiny::icon("upload")))),
      shiny::div(class = "champ",
        shiny::radioButtons(ns("mode_import"), NULL, inline = TRUE,
          choices = stats::setNames(c("completer", "remplacer"),
                                    tr(c("Compl\u00e9ter les donn\u00e9es existantes",
                                         "Remplacer les donn\u00e9es existantes"))),
          selected = "completer")),
      shiny::p(class = "petit indication", tr(paste(
        "Compl\u00e9ter conserve ce qui est en base et ajoute ou corrige les p\u00e9riodes",
        "du fichier. Remplacer efface d'abord chaque s\u00e9rie concern\u00e9e : \u00e0 retenir",
        "quand le nouveau fichier fait autorit\u00e9 sur l'ancien."))),
      shiny::uiOutput(ns("resultat_import"))),

    # --- gestion des donnees importees -----------------------------------
    shiny::div(class = "cadre",
      shiny::h3(tr("Supprimer des donn\u00e9es")),
      shiny::p(class = "meta", tr(paste(
        "L'effacement porte sur les observations d'une cat\u00e9gorie. Les",
        "indicateurs restent au catalogue, pr\u00eats \u00e0 \u00eatre r\u00e9aliment\u00e9s. Cette",
        "op\u00e9ration est irr\u00e9versible : la base n'est pas versionn\u00e9e."))),
      shiny::div(class = "barre-filtres",
        shiny::div(class = "champ champ-large",
          shiny::selectInput(ns("categorie_suppression"), tr("Cat\u00e9gorie"),
                             choices = NULL, width = "100%")),
        shiny::div(class = "champ champ-actions",
          shiny::actionButton(ns("supprimer"), tr("Supprimer"),
                              class = "btn-opesc-clair", icon = shiny::icon("trash")))),
      shiny::uiOutput(ns("resultat_suppression"))),

    # Le journal vient en dernier : il rend compte de ce qui a ete fait, alors
    # que l'import et la suppression sont ce qu'on vient faire.
    journal)
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
          shiny::p(tr("La base est en lecture seule : la collecte n'est pas disponible sur ce déploiement."))))
      }
      shiny::div(class = "outils",
        shiny::selectInput(ns("portee"), NULL, width = "260px",
          choices = c("Tout le catalogue" = "",
                      stats::setNames(categories$code,
                                      tr(paste("Catégorie :", categories$libelle))))),
        shiny::actionButton(ns("lancer"), tr("Actualiser"), class = "btn-opesc",
                            icon = shiny::icon("rotate")))
    })

    shiny::updateSelectInput(session, "categorie_import",
      choices = stats::setNames(categories$code, tr(categories$libelle)),
      selected = "C15")

    rafraichir <- shiny::reactiveVal(0)
    message_import <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$importer, {
      fichier <- input$fichier
      if (is.null(fichier)) {
        message_import(list(type = "alerte",
                            texte = tr("Choisissez d'abord un fichier.")))
        return()
      }
      shiny::withProgress(message = tr("Importation en cours"), value = 0.4, {
        r <- tryCatch(
          charger_cours_livres(con, fichier$datapath, input$categorie_import,
                               mode = input$mode_import %||% "completer"),
          error = function(e) e)
        if (inherits(r, "error")) {
          message_import(list(type = "alerte", texte = sprintf(
            tr("\u00c9chec de l'import : %s"), conditionMessage(r))))
        } else {
          message_import(list(type = "note", texte = sprintf(
            tr("%d observations import\u00e9es. Elles sont disponibles dans le tableau de bord."),
            r)))
        }
      })
      rafraichir(rafraichir() + 1)
    })

    # --- suppression -----------------------------------------------------
    # La confirmation est demandee en deux temps : un premier clic annonce ce
    # qui sera efface, un second l'execute. Une suppression est irreversible.
    a_confirmer <- shiny::reactiveVal(NULL)

    shiny::updateSelectInput(session, "categorie_suppression",
      choices = stats::setNames(categories$code, tr(categories$libelle)),
      selected = "C15")

    shiny::observeEvent(input$supprimer, {
      cat_choisie <- input$categorie_suppression
      if (is.null(cat_choisie)) return()

      if (identical(a_confirmer(), cat_choisie)) {
        n <- supprimer_donnees(categorie = cat_choisie, confirmer = TRUE, con = con)
        a_confirmer(NULL)
        message_import(list(type = "note", texte = sprintf(
          tr("%d observations effac\u00e9es."), n)))
        rafraichir(rafraichir() + 1)
        return()
      }

      n <- DBI::dbGetQuery(con, "
        SELECT COUNT(*) AS n FROM observation o
        JOIN indicateur i ON i.code_interne = o.code_interne
        WHERE i.categorie = ?", params = list(cat_choisie))$n
      if (!n) {
        message_import(list(type = "alerte",
                            texte = tr("Cette cat\u00e9gorie ne contient aucune donn\u00e9e.")))
        return()
      }
      a_confirmer(cat_choisie)
      message_import(list(type = "alerte", texte = sprintf(
        tr("%d observations vont \u00eatre effac\u00e9es. Cliquez de nouveau sur Supprimer pour confirmer."),
        n)))
    })

    output$resultat_suppression <- shiny::renderUI(NULL)

    output$resultat_import <- shiny::renderUI({
      m <- message_import()
      if (is.null(m)) return(NULL)
      shiny::div(class = if (identical(m$type, "alerte")) "alerte" else "note",
                 shiny::p(m$texte))
    })

    shiny::observeEvent(input$lancer, {
      lignes <- if (is.null(input$portee) || input$portee == "")
        lire_indicateurs(con) else lire_indicateurs(con, input$portee)
      if (!nrow(lignes)) {
        shiny::showNotification(tr("Aucun indicateur dans cette portée."), type = "warning")
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
      shiny::validate(shiny::need(nrow(d) > 0, tr("Aucune collecte enregistrée.")))
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

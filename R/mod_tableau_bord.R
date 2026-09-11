# ---------------------------------------------------------------------------
# Module Tableau de bord.
#
# Enchainement impose : categorie -> indicateur -> frequence -> periode -> pays.
# Chaque etape restreint la suivante, et chaque liste est construite a partir
# de ce qui existe reellement en base, jamais a partir de ce que la source est
# censee publier.
# ---------------------------------------------------------------------------

mod_tableau_bord_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    # --- 1. Categories ----------------------------------------------------
    # --- 0. Marche a suivre pour les matieres premieres -------------------
    # La base des cours ne peut pas etre collectee automatiquement : la page du
    # Fonds monetaire international construit son lien de telechargement en
    # JavaScript. La marche a suivre a donc sa place ici, mais repliee : elle
    # ne concerne qu'un premier usage, et deployee elle repoussait les
    # categories sous la ligne de flottaison.
    shiny::div(class = "cadre bandeau-marche",
      shiny::div(class = "marche-ligne",
        shiny::span(class = "marche-icone", icone("download", 18)),
        shiny::div(class = "marche-texte",
          shiny::strong(tr("Mati\u00e8res premi\u00e8res")),
          shiny::span(tr("base \u00e0 t\u00e9l\u00e9charger puis \u00e0 importer avant utilisation"))),
        shiny::tags$a(class = "marche-bouton", target = "_blank", rel = "noopener",
                      href = "https://www.imf.org/en/research/commodity-prices",
                      tr("T\u00e9l\u00e9charger la base")),
        shiny::actionLink(ns("voir_marche"), tr("Marche \u00e0 suivre"),
                          class = "marche-bascule")),
      shiny::uiOutput(ns("detail_marche"))),

    shiny::div(class = "cadre cadre-categories",
      shiny::div(class = "cadre-titre", tr("Catégories de données")),
      shiny::uiOutput(ns("tuiles"))),

    # --- 2. Barre de filtres ---------------------------------------------
    shiny::div(class = "cadre cadre-filtres",
      shiny::div(class = "barre-filtres",
        shiny::div(class = "champ champ-indicateur",
          shiny::selectizeInput(
            ns("indicateur"), tr("Indicateur"), choices = NULL, multiple = TRUE,
            width = "100%",
            options = list(placeholder = tr("Choisissez un ou plusieurs indicateurs"),
                           maxItems = CONFIG$max_series,
                           plugins = list("remove_button"))),
          shiny::p(class = "petit indication",
                   tr("Jusqu'\u00e0 six indicateurs peuvent \u00eatre trac\u00e9s ensemble."))),
        shiny::div(class = "champ champ-frequence",
          shiny::selectInput(ns("frequence"), tr("Fréquence"), choices = NULL, width = "100%")),
        shiny::div(class = "champ champ-periode",
          shiny::uiOutput(ns("periode"))),
        shiny::div(class = "champ champ-pays",
          shiny::selectizeInput(ns("pays"), tr("Pays"), choices = NULL, multiple = TRUE,
                                width = "100%",
                                options = list(placeholder = tr("Choisissez un ou plusieurs pays"),
                                               plugins = list("remove_button"))),
          # La liste peut paraitre courte sans que rien ne soit casse : elle
          # ne propose que les entites qui renseignent l'indicateur choisi.
          # L'annoncer evite de chercher une panne la ou il n'y en a pas.
          shiny::uiOutput(ns("couverture_pays"))),
        shiny::div(class = "champ champ-actions",
          shiny::actionButton(ns("appliquer"), tr("Appliquer le filtre"),
                              class = "btn-opesc", icon = shiny::icon("filter")),
          shiny::actionButton(ns("ajouter"), tr("Ajouter au graphique"),
                              class = "btn-opesc-clair", icon = shiny::icon("plus")))),
      shiny::uiOutput(ns("avertissement"))),

    # --- 3. Series empilees ----------------------------------------------
    shiny::uiOutput(ns("liste_series")),

    # --- 4. Graphique -----------------------------------------------------
    shiny::div(class = "cadre",
      shiny::div(class = "entete-graphique",
        shiny::div(
          shiny::h3(shiny::textOutput(ns("titre"), inline = TRUE)),
          shiny::p(class = "meta", shiny::textOutput(ns("sous_titre"), inline = TRUE))),
        shiny::div(class = "outils",
          shiny::selectInput(ns("type"), NULL, width = "130px",
            choices = stats::setNames(c("ligne", "barre", "aire"), tr(c("Courbes", "Barres", "Aires")))),
          shiny::checkboxInput(ns("base100"), tr("Base 100"), value = FALSE),
          shiny::uiOutput(ns("bouton_actualiser"), inline = TRUE),
          shiny::downloadButton(ns("png"), tr("Image"), class = "btn-opesc-clair"),
          shiny::downloadButton(ns("xlsx"), tr("Données (xlsx)"), class = "btn-opesc-clair"))),
      shiny::div(class = "zone-graphique",
        plotly::plotlyOutput(ns("graphique"), height = "440px")),
      shiny::p(class = "note", shiny::textOutput(ns("note_source"), inline = TRUE))),

    # --- 5. Analyse cartographique ---------------------------------------
    shiny::div(class = "cadre",
      shiny::div(class = "entete-graphique",
        shiny::div(
          shiny::h3(tr("Analyse cartographique")),
          shiny::p(class = "meta", shiny::textOutput(ns("note_carte"), inline = TRUE))),
        shiny::div(class = "outils",
          shiny::uiOutput(ns("annee_carte"), inline = TRUE),
          shiny::downloadButton(ns("carte_xlsx"), tr("Classement (xlsx)"),
                                class = "btn-opesc-clair"))),
      shiny::div(class = "bloc-carte",
        shiny::div(class = "zone-carte",
          plotly::plotlyOutput(ns("carte"), height = "460px")),
        shiny::div(class = "colonne-fiche",
          shiny::uiOutput(ns("fiche"))))))
}

mod_tableau_bord_server <- function(id, con) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    categories <- lire_categories(con)
    tous_pays  <- lire_pays(con)

    avec_donnees <- categories$code[categories$collectes > 0]
    categorie_depart <- local({
      # La categorie retenue est celle qui porte l'indicateur de depart, a
      # condition qu'il soit alimente. Sinon la premiere categorie qui contient
      # des donnees, quelles qu'elles soient.
      d <- DBI::dbGetQuery(con, "
        SELECT categorie FROM indicateur
        WHERE code_source IN ('NY.GDP.PCAP.KD.ZG', 'NY.GDP.MKTP.KD.ZG')
          AND actif = 1 AND nb_observations > 0
        ORDER BY code_source")
      if (nrow(d)) d$categorie[[1]]
      else if (length(avec_donnees)) avec_donnees[[1]]
      else categories$code[[1]]
    })

    etat <- shiny::reactiveValues(
      categorie = categorie_depart,
      series    = list(),   # series affichees
      donnees   = NULL,     # tableau assemble
      graphique = NULL)

    # --- tuiles de categories -------------------------------------------
    # Les tuiles sont construites une seule fois. Les regenerer a chaque
    # changement de categorie remettrait a zero le compteur de clics des
    # actionButton, ce que Shiny interprete comme un nouveau clic : les
    # observateurs se declencheraient en boucle. La mise en evidence de la
    # tuile active est donc faite cote client, dans www/opesc.js.
    # --- marche a suivre, deployee a la demande --------------------------
    marche_ouverte <- shiny::reactiveVal(FALSE)
    shiny::observeEvent(input$voir_marche, marche_ouverte(!marche_ouverte()))

    output$detail_marche <- shiny::renderUI({
      if (!marche_ouverte()) return(NULL)
      etape <- function(numero, titre, points) {
        shiny::div(class = "marche-etape",
          shiny::div(class = "marche-numero", numero),
          shiny::div(
            shiny::strong(titre),
            shiny::tags$ol(class = "marche-liste",
                           lapply(points, shiny::tags$li))))
      }
      shiny::div(class = "marche-detail",
        shiny::div(class = "marche-colonnes",
          etape("1", tr("T\u00e9l\u00e9charger la base"), list(
            tr("Rubrique \u00ab Prix des mati\u00e8res premi\u00e8res \u00bb, puis \u00ab Acc\u00e9der \u00e0 la base de donn\u00e9es \u00bb."),
            tr("Cliquez sur \u00ab Voir donn\u00e9es \u00bb."),
            tr("Dans \u00ab Explorateur de donn\u00e9es \u00bb, d\u00e9finissez la p\u00e9riode, par exemple les quinze derni\u00e8res ann\u00e9es."),
            tr("La fl\u00e8che devant \u00ab Ensemble de donn\u00e9es \u00bb d\u00e9roule les autres bases disponibles, dont l'indice des prix \u00e0 la production."),
            tr("Vous pouvez ensuite restreindre aux pays et aux indicateurs voulus, plut\u00f4t que de tout t\u00e9l\u00e9charger."),
            tr("\u00ab Transformer les donn\u00e9es \u00bb permet d'en changer la pr\u00e9sentation."),
            tr("Pour la fr\u00e9quence, choisissez \u00ab Tous \u00bb : la plateforme s\u00e9pare ensuite les pas annuel, trimestriel et mensuel."),
            tr("Cliquez sur \u00ab Postulez \u00bb, puis \u00ab T\u00e9l\u00e9charger \u00bb."),
            tr("Choisissez l'ensemble de donn\u00e9es sur la page, non les donn\u00e9es compl\u00e8tes."))),
          etape("2", tr("Importer dans la plateforme"), list(
            tr("Ouvrez l'onglet \u00ab Collectes \u00bb."),
            tr("Rubrique \u00ab Importer un fichier \u00bb, cliquez sur \u00ab Parcourir \u00bb."),
            tr("Cat\u00e9gorie : \u00ab Mati\u00e8res premi\u00e8res commodityPrice \u00bb."),
            tr("Cliquez sur \u00ab Importer \u00bb, puis revenez ici.")))),
        shiny::p(class = "marche-note", tr(paste(
          "Une base est d\u00e9j\u00e0 livr\u00e9e avec la plateforme. Ces \u00e9tapes servent \u00e0 la",
          "mettre \u00e0 jour ou \u00e0 \u00e9tendre la p\u00e9riode couverte."))))
    })

    output$couverture_pays <- shiny::renderUI({
      c_ <- etat$couverture
      if (is.null(c_) || c_$retenus >= c_$total) return(NULL)
      shiny::p(class = "petit indication", sprintf(
        tr("%d entit\u00e9s sur %d renseignent cet indicateur."),
        c_$retenus, c_$total))
    })

    output$tuiles <- shiny::renderUI({
      active <- shiny::isolate(etat$categorie)

      tuiles <- lapply(seq_len(nrow(categories)), function(i) {
        # Chaque valeur est extraite comme scalaire explicite. Passer par
        # `categories[i, ]$code` renvoyait selon les cas un vecteur, et le
        # `if` qui suivait echouait avec « 'length = 3' in coercion to
        # 'logical(1)' », message d'autant plus opaque qu'il ne nomme pas la
        # ligne fautive.
        code    <- as.character(categories$code[[i]])
        libelle <- tr(as.character(categories$libelle[[i]]))
        nb      <- as.integer(categories$nb[[i]])
        collectes <- as.integer(categories$collectes[[i]])

        classe <- if (isTRUE(code == active)) "tuile tuile-active" else "tuile"
        legende <- if (collectes == 0) {
          sprintf(tr("%d indicateur%s, aucune donn\u00e9e"), nb, if (nb > 1) "s" else "")
        } else if (collectes < nb) {
          # Trois specificateurs, donc trois arguments. Un quatrieme etait
          # passe, d'ou l'avertissement repete a chaque tuile au demarrage.
          sprintf(tr("%d indicateur%s sur %d avec donn\u00e9es"), collectes,
                  if (collectes > 1) "s" else "", nb)
        } else {
          sprintf("%d indicateur%s", nb, if (nb > 1) "s" else "")
        }

        # Les deux `span` doivent etre passes DANS `label`, pas apres.
        # La signature est actionButton(inputId, label, icon, width, ...) :
        # places en arguments positionnels, ils etaient captes par `icon` puis
        # par `width`. Shiny appelait alors validateCssUnit() sur une balise
        # HTML, qui est une liste de longueur 3, d'ou le message
        # « 'length = 3' in coercion to 'logical(1)' ».
        shiny::actionButton(
          inputId = ns(paste0("cat_", code)),
          label = shiny::tagList(
            shiny::span(class = "tuile-libelle", libelle),
            shiny::span(class = if (collectes == 0) "tuile-compte tuile-vide"
                                else "tuile-compte", legende)),
          class = classe)
      })

      shiny::div(class = "tuiles", tuiles)
    })

    # Un observateur par tuile. `local()` fige la valeur de l'indice : sans lui,
    # tous les boutons partageraient la derniere categorie de la boucle.
    lapply(categories$code, function(code) {
      local({
        cc <- code
        shiny::observeEvent(input[[paste0("cat_", cc)]], {
          etat$categorie <- cc
        }, ignoreInit = TRUE)
      })
    })

    # --- cascade : categorie -> indicateurs -----------------------------
    indicateurs_categorie <- shiny::reactive({
      lire_indicateurs(con, etat$categorie)
    })

    # Indicateur retenu au chargement, s'il est present et alimente.
    # Indicateur retenu au chargement, s'il figure dans la categorie courante.
    # Le pays de depart, lui, est deja fixe par CONFIG$pays_defaut.
    INDICATEUR_DEPART <- "NY.GDP.PCAP.KD.ZG"

    shiny::observeEvent(indicateurs_categorie(), {
      d <- indicateurs_categorie()
      if (!nrow(d)) {
        shiny::updateSelectizeInput(session, "indicateur", choices = character(0),
                                    server = TRUE)
        return()
      }
      # Les indicateurs deja collectes viennent en tete, et ceux qui ne le sont
      # pas le disent. Les melanger sans distinction laissait croire a une
      # panne alors que la donnee n'avait simplement pas encore ete recuperee.
      d <- d[order(d$nb_observations == 0, d$libelle), ]
      libelles <- tr(d$libelle)
      etiquettes <- ifelse(d$nb_observations == 0,
                           paste0(libelles, "  (", tr("sans donn\u00e9es"), ")"),
                           libelles)
      choix <- stats::setNames(d$code_interne, etiquettes)
      # `options` n'est pas transmis ici. Le passer a `updateSelectizeInput`
      # reinitialise le composant cote navigateur, qui perd alors son caractere
      # multiple : le champ redevenait mono-selection des le premier
      # chargement, et il devenait impossible de choisir deux indicateurs.
      # Les options sont posees une fois pour toutes a la creation du champ.
      # L'indicateur de depart est retenu s'il figure dans la categorie et
      # porte des donnees. A defaut, le premier qui en porte : ouvrir sur un
      # indicateur vide donnerait un graphique vide, ce qui laisse croire a une
      # panne.
      #
      # La variable lue ici est `d`, la table des indicateurs de la categorie.
      # Une premiere version interrogeait un nom qui n'existe pas dans cette
      # portee : la selection retombait toujours sur le premier de la liste.
      alimentes <- d[d$nb_observations > 0, ]
      cible <- alimentes$code_interne[alimentes$code_source == INDICATEUR_DEPART]
      retenu <- if (length(cible)) cible[[1]]
                else if (nrow(alimentes)) alimentes$code_interne[[1]]
                else choix[[1]]
      shiny::updateSelectizeInput(session, "indicateur", choices = choix,
                                  selected = retenu, server = TRUE)
    })

    # Les cascades qui suivent (frequence, periode, pays) se calent sur le
    # premier indicateur choisi. Les combiner sur plusieurs indicateurs
    # produirait des intersections souvent vides : mieux vaut un reglage lisible
    # quitte a ce qu'une serie secondaire soit tronquee.
    indicateur_principal <- shiny::reactive({
      shiny::req(length(input$indicateur) > 0)
      input$indicateur[[1]]
    })

    indicateur_courant <- shiny::reactive({
      d <- indicateurs_categorie()
      ligne <- d[d$code_interne == indicateur_principal(), ]
      shiny::req(nrow(ligne) == 1)
      ligne
    })

    # --- cascade : indicateur -> frequences -----------------------------
    shiny::observeEvent(input$indicateur, {
      shiny::req(input$indicateur)
      dispo <- frequences_disponibles(con, input$indicateur)  # union des choix
      choix <- choix_frequences(dispo)
      if (!length(choix)) {
        shiny::updateSelectInput(session, "frequence",
                                 choices = stats::setNames("", tr("Aucune donnée collectée")))
        return()
      }
      # On propose par defaut le pas le plus large disponible : c'est celui qui
      # se lit le mieux sur un graphique de long terme.
      shiny::updateSelectInput(session, "frequence", choices = choix,
                               selected = unname(choix[1]))
    })

    # --- cascade : frequence -> periode ---------------------------------
    output$periode <- shiny::renderUI({
      shiny::req(input$indicateur, input$frequence)
      bornes <- etendue_periode(con, input$indicateur, input$frequence)
      if (is.null(bornes)) {
        # Distinguer les deux cas : l'indicateur n'a jamais ete collecte, ou il
        # l'a ete mais pas a ce pas. Le remede n'est pas le meme.
        n <- DBI::dbGetQuery(con,
          "SELECT nb_observations AS n FROM indicateur WHERE code_interne = ?",
          params = list(indicateur_principal()))$n
        message <- if (length(n) && n[[1]] == 0) {
          tr("Cet indicateur n'a pas encore \u00e9t\u00e9 collect\u00e9. Lancez la collecte depuis l'onglet Collectes.")
        } else {
          tr("Aucune donn\u00e9e \u00e0 ce pas. Choisissez une autre fr\u00e9quence.")
        }
        return(shiny::div(class = "champ-vide",
                          shiny::tags$label(tr("Période")),
                          shiny::p(class = "petit", message)))
      }
      shiny::dateRangeInput(
        ns("bornes"), tr("Période"),
        start = max(bornes$min, seq(bornes$max, by = "-20 years", length.out = 2)[2]),
        end = bornes$max, min = bornes$min, max = bornes$max,
        format = "dd/mm/yyyy", language = "fr", separator = " au ", width = "100%")
    })

    # La date de debut doit rester anterieure a la date de fin. Plutot que de
    # refuser la saisie, on la corrige et on le dit.
    shiny::observeEvent(input$bornes, {
      b <- input$bornes
      shiny::req(length(b) == 2, !any(is.na(b)))
      if (b[1] > b[2]) {
        shiny::updateDateRangeInput(session, "bornes", start = b[2], end = b[1])
        shiny::showNotification(
          tr("La date de début était postérieure à la date de fin : les deux ont été inversées."),
          type = "warning", duration = 6)
      }
    }, ignoreInit = TRUE)

    # --- cascade : indicateur -> pays -----------------------------------
    shiny::observeEvent(input$indicateur, {
      ligne <- indicateur_courant()
      if (ligne$dimension_pays == 0) {
        # Un cours mondial de matiere premiere n'a pas de dimension pays :
        # proposer une liste de pays serait un piege.
        shiny::updateSelectizeInput(session, "pays",
          choices = stats::setNames("WLD", tr("Cours mondial (série sans dimension pays)")),
          selected = "WLD", server = TRUE)
        return()
      }
      dispo <- DBI::dbGetQuery(con,
        "SELECT DISTINCT iso3 FROM observation WHERE code_interne = ?",
        params = list(indicateur_principal()))$iso3

      # On ne propose que les entites pour lesquelles l'indicateur existe
      # reellement. Un indicateur de pauvrete n'est renseigne que pour une
      # quarantaine de pays : en proposer deux cents menerait a des graphiques
      # vides, ce que la plateforme s'interdit.
      p <- if (length(dispo)) tous_pays[tous_pays$iso3 %in% dispo, ] else tous_pays

      # La liste peut paraitre courte sans que rien ne soit casse : le nombre
      # d'entites retenues est donc annonce sous le champ.
      etat$couverture <- list(retenus = nrow(p), total = nrow(tous_pays))
      # La liste est rangee en trois groupes nommes, chacun par ordre
      # alphabetique : le monde, les regroupements, puis les pays. Une liste
      # plate melait une quarantaine d'agregats aux deux cents pays, et il
      # fallait connaitre le nom anglais d'un regroupement pour le trouver.
      #
      # Les noms viennent de la Banque mondiale, donc en anglais. Ceux des
      # regroupements passent par la table de traduction : on cherche
      # « Monde », non « World ».
      p$libelle <- vapply(p$nom, nom_traduit, character(1), USE.NAMES = FALSE)

      monde <- p[p$iso3 == "WLD", ]
      groupes <- p[p$est_agregat == 1 & p$iso3 != "WLD", ]
      pays_seuls <- p[p$est_agregat == 0, ]

      groupes <- groupes[order(groupes$libelle), ]
      pays_seuls <- pays_seuls[order(pays_seuls$libelle), ]

      # Un groupe vide est omis : selectize afficherait un intitule sans
      # contenu, ce qui laisse croire a une liste incomplete.
      choix <- list()
      if (nrow(monde)) {
        choix[[tr("Monde")]] <- stats::setNames(monde$iso3, monde$libelle)
      }
      if (nrow(groupes)) {
        choix[[tr("R\u00e9gions et regroupements")]] <-
          stats::setNames(groupes$iso3, groupes$libelle)
      }
      if (nrow(pays_seuls)) {
        choix[[tr("Pays")]] <- stats::setNames(pays_seuls$iso3, pays_seuls$libelle)
      }

      selection <- shiny::isolate(input$pays)
      selection <- selection[selection %in% p$iso3]
      if (!length(selection)) {
        selection <- if (CONFIG$pays_defaut %in% p$iso3) CONFIG$pays_defaut
                     else utils::head(p$iso3, 1)
      }
      shiny::updateSelectizeInput(session, "pays", choices = choix,
                                  selected = selection, server = TRUE)
    })

    # --- avertissements --------------------------------------------------
    output$avertissement <- shiny::renderUI({
      messages <- character(0)
      if (length(input$pays) > CONFIG$max_pays) {
        messages <- c(messages, sprintf(
          tr("Vous avez choisi %d pays. Au-delà de %d courbes le graphique devient illisible ; seuls les %d premiers seront tracés."),
          length(input$pays), CONFIG$max_pays, CONFIG$max_pays))
      }
      if (!length(messages)) return(NULL)
      shiny::div(class = "alerte", lapply(messages, shiny::p))
    })

    # --- construction de la selection courante ---------------------------
    selection_courante <- function() {
      shiny::req(length(input$indicateur) > 0, input$frequence, input$pays)
      pays <- utils::head(input$pays, CONFIG$max_pays)
      lapply(input$indicateur, function(code) {
        list(code_interne = code, frequence = input$frequence, pays = pays)
      })
    }

    dessiner <- function() {
      shiny::req(length(etat$series) > 0)
      bornes <- input$bornes
      debut <- if (length(bornes) == 2) bornes[1] else NULL
      fin   <- if (length(bornes) == 2) bornes[2] else NULL

      d <- assembler(con, etat$series, debut, fin)
      etat$donnees <- d
      if (is.null(d)) {
        etat$graphique <- NULL
        return()
      }
      # La mise en base 100 est imposee des que les unites different : sans
      # elle, un pourcentage et un cours en dollars par tonne sur le meme axe
      # ecrasent l'un des deux.
      # Le camembert represente une repartition, pas une evolution : la mise
      # en base 100 n'a aucun sens pour lui et le rendrait uniforme.
      camembert <- identical(input$type, "camembert")
      forcer <- !camembert && length(unites_distinctes(d)) > 1
      etat$graphique <- tracer(d, type = input$type,
                               base100 = isTRUE(input$base100) && !camembert || forcer,
                               titre = NULL)

      if (camembert && !camembert_pertinent(d)) {
        shiny::showNotification(tr(paste(
          "Un camembert additionne les valeurs affich\u00e9es. Sur des pourcentages,",
          "des indices ou des rangs, le total n'a pas de sens : lisez-le avec",
          "prudence.")), type = "warning", duration = 12)
      }
      if (forcer && !isTRUE(input$base100) && !camembert) {
        shiny::updateCheckboxInput(session, "base100", value = TRUE)
        shiny::showNotification(
          tr("Les séries n'ont pas la même unité : elles sont ramenées en base 100 pour rester comparables."),
          type = "message", duration = 8)
      }
    }

    shiny::observeEvent(input$appliquer, {
      etat$series <- selection_courante()
      dessiner()
    })

    # --- selection de depart ----------------------------------------------
    # Un tableau de bord vide n'apprend rien et laisse l'utilisateur devant un
    # cadre gris. Une serie est donc tracee au chargement : la croissance du
    # produit interieur brut par habitant, au Cameroun, en annuel. Elle se
    # remplace au premier filtre applique.
    demarrage <- shiny::reactiveVal(FALSE)

    shiny::observe({
      if (demarrage()) return()
      # On attend que les cascades soient remplies : les declencher trop tot
      # produirait une selection vide, donc aucun trace.
      shiny::req(length(input$indicateur), input$frequence, length(input$pays))
      demarrage(TRUE)
      etat$series <- selection_courante()
      dessiner()

      # Si rien n'a pu etre trace, l'utilisateur doit savoir pourquoi : un
      # cadre vide se lit comme une panne alors que la base n'est simplement
      # pas alimentee.
      if (is.null(etat$donnees) || !nrow(etat$donnees)) {
        shiny::showNotification(tr(paste(
          "Aucune donn\u00e9e \u00e0 tracer au chargement. La base ne contient",
          "peut-\u00eatre encore rien pour cette cat\u00e9gorie : lancez",
          "diagnostic_plateforme() dans la console.")),
          type = "warning", duration = 12)
      }
    })

    shiny::observeEvent(input$ajouter, {
      nouvelles <- selection_courante()
      ajoutees <- sum(vapply(nouvelles, ajouter_serie, logical(1)))

      # Un seul message, et seulement si rien n'a pu etre ajoute. La version
      # precedente signalait chaque doublon separement, si bien qu'ajouter un
      # second indicateur affichait un avertissement alors que l'ajout avait
      # bien eu lieu.
      if (ajoutees == 0L) {
        shiny::showNotification(tr(paste(
          "Ces s\u00e9ries sont d\u00e9j\u00e0 affich\u00e9es. Choisissez un autre indicateur, une",
          "autre fr\u00e9quence ou d'autres pays, puis cliquez de nouveau sur Ajouter.")),
          type = "message", duration = 9)
        return()
      }
      dessiner()
    })

    # Ajoute une serie si elle n'est pas deja la et si le plafond le permet.
    # Le redessin est fait par l'appelant, une seule fois pour tout le lot.
    # Rend TRUE si la serie a ete ajoutee, FALSE sinon. La valeur est utilisee
    # par l'appelant pour decider s'il faut redessiner et quoi afficher.
    ajouter_serie <- function(s) {
      if (length(etat$series) >= CONFIG$max_series) {
        shiny::showNotification(
          tr("Six séries au maximum sur un même graphique."),
          type = "warning", duration = 6)
        return(FALSE)
      }
      deja <- vapply(etat$series, function(x)
        identical(x$code_interne, s$code_interne) &&
        identical(x$frequence, s$frequence) &&
        identical(sort(x$pays), sort(s$pays)), logical(1))
      # Aucun message ici : c'est l'appelant qui decide quoi dire, une seule
      # fois, apres avoir traite tout le lot. Signaler chaque doublon
      # separement affichait un avertissement alors que l'ajout avait bien eu
      # lieu pour les autres series.
      if (length(deja) && any(deja)) return(FALSE)
      etat$series <- c(etat$series, list(s))
      TRUE
    }

    # --- series empilees --------------------------------------------------
    output$liste_series <- shiny::renderUI({
      if (!length(etat$series)) return(NULL)
      libelles <- vapply(etat$series, function(s) {
        l <- DBI::dbGetQuery(con,
          "SELECT libelle FROM indicateur WHERE code_interne = ?",
          params = list(s$code_interne))$libelle
        sprintf("%s (%s, %s)", tr(l), tolower(libelle_frequence(s$frequence)),
                paste(s$pays, collapse = ", "))
      }, character(1))

      shiny::div(class = "cadre cadre-series",
        shiny::span(class = "cadre-titre-petit",
                    sprintf(tr("S\u00e9ries affich\u00e9es (%d sur %d)"),
                            length(libelles), CONFIG$max_series)),
        shiny::div(class = "jetons",
          lapply(seq_along(libelles), function(i) {
            # Le bouton de retrait n'est plus un actionLink. Reconstruire cette
            # liste remettait a zero le compteur de clics de chaque lien, ce
            # que Shiny interprete comme un nouveau clic : ajouter une
            # troisieme serie declenchait aussitot le retrait des precedentes,
            # et le graphique restait bloque a deux courbes. Le clic passe
            # maintenant par Shiny.setInputValue, en mode evenement, qui ne se
            # declenche que sur une action reelle de l'utilisateur.
            shiny::span(class = "jeton", libelles[i],
              shiny::tags$button(
                class = "jeton-retirer", type = "button",
                `data-cible` = ns("retirer"), `data-serie` = i,
                title = tr("Retirer cette s\u00e9rie"), "\u00d7"))
          })))
    })

    shiny::observeEvent(input$retirer, {
      i <- suppressWarnings(as.integer(input$retirer))
      shiny::req(!is.na(i), i >= 1, i <= length(etat$series))
      etat$series <- etat$series[-i]
      if (length(etat$series)) {
        dessiner()
      } else {
        etat$donnees <- NULL
        etat$graphique <- NULL
      }
    }, ignoreInit = TRUE)

    # --- actualisation ---------------------------------------------------
    output$bouton_actualiser <- shiny::renderUI({
      if (!base_modifiable()) return(NULL)
      shiny::actionButton(ns("actualiser"), tr("Actualiser les données"),
                          class = "btn-opesc-clair", icon = shiny::icon("rotate"))
    })

    shiny::observeEvent(input$actualiser, {
      if (!length(etat$series)) {
        shiny::showNotification("Appliquez d'abord un filtre.", type = "message")
        return()
      }
      codes <- unique(vapply(etat$series, function(s) s$code_interne, character(1)))
      marques <- paste(rep("?", length(codes)), collapse = ",")
      lignes <- DBI::dbGetQuery(con, sprintf(
        "SELECT * FROM indicateur WHERE code_interne IN (%s)", marques),
        params = as.list(codes))

      shiny::withProgress(message = "Actualisation en cours", value = 0, {
        res <- collecter(con, lignes, declencheur = "bouton",
          avancement = function(i, n, libelle, erreur) {
            shiny::incProgress(1 / n, detail = sprintf("%d/%d : %s", i, n, libelle))
          })
        if (length(res$erreurs)) {
          shiny::showNotification(
            sprintf(tr("Actualisation terminée avec %d erreur(s). Voir l'onglet Collectes."),
                    length(res$erreurs)), type = "warning", duration = 10)
        } else {
          shiny::showNotification(sprintf(
            "%d valeurs ajoutées, %d révisées.", res$creees, res$modifiees),
            type = "message", duration = 8)
        }
      })
      dessiner()
    })

    # --- sorties ----------------------------------------------------------
    output$titre <- shiny::renderText({
      if (is.null(etat$donnees)) return(tr("Aucune série affichée"))
      libelles <- unique(etat$donnees$libelle)
      if (length(libelles) == 1) libelles else
        sprintf("%d indicateurs comparés", length(libelles))
    })

    output$sous_titre <- shiny::renderText({
      if (is.null(etat$donnees)) {
        return(tr("Choisissez une catégorie, un indicateur, une fréquence, une période et un ou plusieurs pays, puis appliquez le filtre."))
      }
      d <- etat$donnees
      sprintf("%s : %d observations, de %s à %s.",
              paste(unique(d$unite), collapse = " / "), nrow(d),
              format(min(d$date_periode), "%d/%m/%Y"),
              format(max(d$date_periode), "%d/%m/%Y"))
    })

    output$note_source <- shiny::renderText({
      if (is.null(etat$donnees)) return("")
      sprintf(tr("Source : %s. Extraction du %s."),
              paste(unique(etat$donnees$source), collapse = " ; "),
              format(Sys.Date(), "%d/%m/%Y"))
    })

    output$graphique <- plotly::renderPlotly({
      g <- etat$graphique
      shiny::validate(shiny::need(!is.null(g),
        tr("Aucune donnée pour cette combinaison. Élargissez la période, changez de fréquence ou vérifiez que l'indicateur a bien été collecté.")))
      tracer_interactif(g)
    })

    # --- carte ------------------------------------------------------------
    # La carte suit le premier indicateur affiche, et non l'ensemble des
    # series : superposer plusieurs indicateurs sur un meme aplat de couleur
    # n'aurait aucun sens, les unites n'etant pas comparables.
    serie_cartographiee <- shiny::reactive({
      shiny::req(length(etat$series) > 0)
      etat$series[[1]]
    })

    annees_disponibles <- shiny::reactive({
      s <- serie_cartographiee()
      annees_carte(con, s$code_interne, s$frequence)
    })

    output$annee_carte <- shiny::renderUI({
      annees <- annees_disponibles()
      if (!length(annees)) return(NULL)
      shiny::sliderInput(
        ns("annee"), NULL, min = min(annees), max = max(annees),
        value = max(annees), step = 1, sep = "", width = "260px",
        animate = shiny::animationOptions(interval = 900, loop = FALSE))
    })

    donnees_carte_courantes <- shiny::reactive({
      s <- serie_cartographiee()
      annees <- annees_disponibles()
      shiny::req(length(annees) > 0)
      # Tant que le curseur n'est pas rendu, on prend la derniere annee utile.
      annee <- if (is.null(input$annee)) max(annees) else input$annee
      donnees_carte(con, s$code_interne, s$frequence, annee)
    })

    output$carte <- plotly::renderPlotly({
      s <- serie_cartographiee()
      dim_pays <- DBI::dbGetQuery(con,
        "SELECT dimension_pays AS d FROM indicateur WHERE code_interne = ?",
        params = list(s$code_interne))$d
      shiny::validate(shiny::need(
        length(dim_pays) && dim_pays[[1]] == 1,
        tr("Cet indicateur est un cours mondial : il n'a pas de dimension pays et ne peut pas \u00eatre cartographi\u00e9.")))

      d <- donnees_carte_courantes()
      shiny::validate(shiny::need(
        nrow(d) > 0,
        tr("Aucune donn\u00e9e cartographiable pour cette ann\u00e9e. D\u00e9placez le curseur ou changez de fr\u00e9quence.")))
      tracer_carte(d, surligner = s$pays, id_clic = ns("pays_clique"))
    })

    # Fiche du pays clique. `event_data` renvoie NULL tant qu'aucun clic n'a eu
    # lieu, ce qui donne l'invite d'usage plutot qu'un cadre vide.
    output$fiche <- shiny::renderUI({
      clic <- input$pays_clique
      if (is.null(clic) || !nzchar(clic)) {
        return(shiny::div(class = "fiche-invite",
          shiny::span(class = "fiche-invite-icone", icone("globe", 30)),
          shiny::p(tr("Cliquez sur un pays de la carte pour afficher sa fiche : drapeau, langue officielle, r\u00e9gion et rang mondial."))))
      }
      d <- donnees_carte_courantes()
      shiny::req(nrow(d) > 0)
      i <- match(toupper(clic), d$iso3)
      shiny::req(!is.na(i))
      fiche_pays(con, d$iso3[[i]], d$libelle[[1]], d$unite[[1]], d$annee[[1]],
                 d$valeur[[i]], i, nrow(d))
    })

    output$note_carte <- shiny::renderText({
      if (!length(etat$series)) {
        return(tr("Appliquez un filtre : la carte suit le premier indicateur affich\u00e9."))
      }
      d <- try(donnees_carte_courantes(), silent = TRUE)
      if (inherits(d, "try-error") || !nrow(d)) return("")
      sprintf(tr("%s, ann\u00e9e %d : %d pays renseign\u00e9s. \u00c9chelle born\u00e9e aux centiles 2 et 98 ; vos pays sont soulign\u00e9s."),
              tr(d$libelle[1]), d$annee[1], nrow(d))
    })

    output$carte_xlsx <- shiny::downloadHandler(
      filename = function() sprintf("opesc_classement_%s.xlsx", horodatage()),
      content = function(fichier) {
        d <- donnees_carte_courantes()
        shiny::req(nrow(d) > 0)
        d$rang <- seq_len(nrow(d))
        sortie <- d[c("rang", "pays", "iso3", "region", "annee", "valeur", "unite")]
        names(sortie) <- c("Rang", "Pays", "Code pays", tr("R\u00e9gion"), tr("Ann\u00e9e"),
                           "Valeur", tr("Unit\u00e9"))
        wb <- openxlsx::createWorkbook()
        openxlsx::addWorksheet(wb, "Classement")
        openxlsx::writeData(wb, "Classement", sortie, headerStyle =
          openxlsx::createStyle(fontColour = "#FFFFFF", fgFill = "#0A2F5C",
                                textDecoration = "bold"))
        openxlsx::freezePane(wb, "Classement", firstRow = TRUE)
        openxlsx::setColWidths(wb, "Classement", seq_along(sortie), widths = "auto")
        openxlsx::saveWorkbook(wb, fichier, overwrite = TRUE)
      })

    output$png <- shiny::downloadHandler(
      filename = function() sprintf("opesc_graphique_%s.png", horodatage()),
      content = function(fichier) {
        shiny::req(etat$graphique)
        ecrire_image(fichier, etat$graphique)
      })

    output$xlsx <- shiny::downloadHandler(
      filename = function() sprintf("opesc_donnees_%s.xlsx", horodatage()),
      content = function(fichier) {
        shiny::req(etat$donnees)
        ecrire_classeur(fichier, etat$donnees)
      })
  })
}

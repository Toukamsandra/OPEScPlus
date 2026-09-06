# ---------------------------------------------------------------------------
# Module Accueil : presentation de la plateforme et acces aux sites de
# reference.
# ---------------------------------------------------------------------------

#' Sites vers lesquels l'accueil renvoie
#'
#' Les adresses sont regroupees ici pour se corriger en un seul endroit le jour
#' ou l'un des fournisseurs reorganise son portail, ce qui arrive : le FMI l'a
#' fait deux fois en un an.
#' @noRd
LIENS <- list(
  institutions = list(
    list("MINEPAT", "Minist\u00e8re de l'\u00c9conomie, de la Planification et de l'Am\u00e9nagement du Territoire",
         "https://www.minepat.gov.cm"),
    list("OPESc", "L'observatoire d'origine, dont OPESc+ prolonge les travaux",
         "https://minepat.com/opesc.php"),
    list("INS Cameroun", "Institut national de la statistique",
         "https://ins-cameroun.cm")),
  sources = list(
    list("Banque mondiale", "Indicateurs du d\u00e9veloppement dans le monde, dette, gouvernance, pauvret\u00e9",
         "https://data.worldbank.org", "156 indicateurs"),
    list("Fonds mon\u00e9taire international", "Perspectives de l'\u00e9conomie mondiale, finances publiques, prix des produits de base",
         "https://www.imf.org/en/Data", "49 indicateurs"),
    list("Growth Lab, Universit\u00e9 Harvard", "Atlas de la complexit\u00e9 \u00e9conomique",
         "https://atlas.hks.harvard.edu", "2 indicateurs"),
    list("OCDE", "Comptes nationaux trimestriels, prix, emploi",
         "https://data.oecd.org", "\u00e0 rebrancher"))
)

#' Fonctionnalites presentees sur l'accueil
#' @noRd
FONCTIONS <- list(
  list("chart", "Tableau de bord interactif",
       "Choisissez une cat\u00e9gorie, un indicateur, une fr\u00e9quence, une p\u00e9riode et un ou plusieurs pays. Chaque \u00e9tape ne propose que ce qui existe r\u00e9ellement en base : aucun filtre ne m\u00e8ne \u00e0 un graphique vide.",
       "Tableau de bord"),
  list("layers", "Superposition de s\u00e9ries",
       "Jusqu'\u00e0 six s\u00e9ries sur un m\u00eame graphique. Quand les unit\u00e9s diff\u00e8rent, elles sont ramen\u00e9es en base 100 pour rester comparables.",
       "Tableau de bord"),
  list("globe", "Analyse cartographique",
       "Une carte du monde pilot\u00e9e par le m\u00eame filtre, avec un curseur d'ann\u00e9e animable. Un clic sur un pays ouvre sa fiche.",
       "Tableau de bord"),
  list("trend", "Projections",
       "Trois m\u00e9thodes de prolongement, avec intervalle : tendance lin\u00e9aire, marche al\u00e9atoire avec d\u00e9rive, lissage de Holt.",
       "Tableau de bord"),
  list("table", "Base de donn\u00e9es compl\u00e8te",
       "Consultation et t\u00e9l\u00e9chargement au format tableur, en s\u00e9ries longues ou en tableau crois\u00e9. Chaque classeur porte ses sources.",
       "Base de donn\u00e9es"),
  list("search", "GoogleOPESc+, recherche orient\u00e9e",
       "Une recherche restreinte \u00e0 trente-cinq sources institutionnelles choisies : donn\u00e9es, publications et actualit\u00e9. La d\u00e9finition de la notion et vos propres indicateurs s'affichent en t\u00eate.",
       "GoogleOPESc+"),
  list("refresh", "Collecte tra\u00e7able",
       "Actualisation \u00e0 la demande, par cat\u00e9gorie ou en totalit\u00e9, avec un journal de chaque ex\u00e9cution.",
       "Collectes")
)

#' Toutes les chaines de ces structures qui passent par le dictionnaire
#'
#' Sert au controle de completude : ces textes ne sont pas des litteraux
#' `tr("...")` dans le code, ils viennent de listes. Sans cette fonction, ils
#' echappaient au controle et restaient en francais dans l'interface anglaise.
#' @noRd
chaines_accueil <- function() {
  c(vapply(FONCTIONS, function(f) f[[2]], character(1)),
    vapply(FONCTIONS, function(f) f[[3]], character(1)),
    vapply(FONCTIONS, function(f) f[[4]], character(1)),
    vapply(LIENS$institutions, function(l) l[[2]], character(1)),
    vapply(LIENS$sources, function(l) l[[2]], character(1)),
    vapply(LIENS$sources, function(l) l[[4]], character(1)),
    CONFIG$sous_titre, CONFIG$devise, PARTENAIRES$nom)
}

mod_accueil_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(

    # --- banniere ---------------------------------------------------------
    shiny::div(class = "hero",
      shiny::div(class = "hero-texte",
        shiny::span(class = "hero-surtitre", tr("R\u00e9publique du Cameroun")),
        shiny::h1(tr("Comprendre l'\u00e9conomie mondiale pour \u00e9clairer la d\u00e9cision publique")),
        shiny::p(tr(paste(
          "OPESc+ rassemble les indicateurs \u00e9conomiques de l'ensemble des",
          "\u00e9conomies, collect\u00e9s directement aupr\u00e8s des institutions qui les",
          "publient, et les met \u00e0 disposition sous forme de s\u00e9ries",
          "exploitables : filtres par pays, par p\u00e9riode et par variable,",
          "graphiques et cartes export\u00e9s en un clic, t\u00e9l\u00e9chargement au format",
          "tableur."))),
        shiny::div(class = "hero-actions",
          shiny::actionButton(ns("vers_tdb"), tr("Ouvrir le tableau de bord"),
                              class = "btn-opesc btn-large"),
          shiny::actionButton(ns("vers_base"), tr("Consulter la base"),
                              class = "btn-opesc-clair btn-large"),
          shiny::actionButton(ns("manuel"), tr("T\u00e9l\u00e9charger le manuel"),
                              class = "btn-opesc-clair btn-large",
                              icon = shiny::icon("download"))),
        shiny::uiOutput(ns("formulaire_manuel"))),
      # Une illustration decorative ne dit rien. Un graphique de la croissance
      # camerounaise, tire de la base elle-meme, montre d'emblee ce que la
      # plateforme contient et de quelle source elle le tient.
      shiny::div(class = "hero-image", banniere_graphique())),

    # --- chiffres cles ----------------------------------------------------
    shiny::uiOutput(ns("chiffres")),

    # --- fonctionnalites --------------------------------------------------
    shiny::div(class = "section",
      shiny::h2(tr("Ce que la plateforme permet")),
      shiny::div(class = "grille-fonctions",
        # Le detail est replie. Sept cartes deployees faisaient une page que
        # personne ne lit : l'oeil glisse sur un mur de texte, alors qu'il
        # parcourt volontiers sept titres.
        lapply(seq_along(FONCTIONS), function(i) {
          f <- FONCTIONS[[i]]
          shiny::tags$details(class = "carte-fonction",
            shiny::tags$summary(
              shiny::div(class = "fonction-icone", icone(f[[1]])),
              shiny::div(class = "fonction-titre",
                shiny::h3(tr(f[[2]])),
                shiny::span(class = "fonction-onglet", tr(f[[4]]))),
              shiny::span(class = "fonction-chevron", "\u203A")),
            shiny::p(class = "fonction-detail", tr(f[[3]])))
        }))),

    # --- acces exterieurs -------------------------------------------------
    shiny::div(class = "section",
      shiny::h2(tr("Institutions")),
      shiny::div(class = "grille-liens",
        lapply(LIENS$institutions, function(l) {
          shiny::tags$a(class = "carte-lien", href = l[[3]], target = "_blank",
                        rel = "noopener", title = tr(l[[2]]),
            shiny::strong(l[[1]]),
            shiny::span(class = "carte-lien-fleche", "\u2192"))
        }))),

    shiny::div(class = "section",
      shiny::h2(tr("Sources des donn\u00e9es")),
      shiny::p(class = "section-chapo", tr(paste(
        "Toutes les donn\u00e9es proviennent d'interfaces publiques et gratuites.",
        "Aucune n'est produite par la plateforme. Toute r\u00e9utilisation doit",
        "citer la source d'origine et la date d'extraction."))),
      shiny::div(class = "grille-liens",
        lapply(LIENS$sources, function(l) {
          shiny::tags$a(class = "carte-lien carte-source", href = l[[3]],
                        target = "_blank", rel = "noopener",
            shiny::strong(l[[1]]), shiny::span(tr(l[[2]])),
            shiny::span(class = "etiquette", l[[4]]))
        }))))
}

mod_accueil_server <- function(id, con, parent) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns


    output$chiffres <- shiny::renderUI({
      n <- DBI::dbGetQuery(con, "
        SELECT (SELECT COUNT(*) FROM indicateur WHERE actif = 1) AS indicateurs,
               (SELECT COUNT(*) FROM categorie) AS categories,
               (SELECT COUNT(*) FROM pays WHERE est_agregat = 0) AS pays,
               (SELECT COUNT(*) FROM observation) AS observations,
               (SELECT MAX(fin) FROM journal_collecte WHERE statut LIKE 'termine%') AS maj")

      chiffre <- function(valeur, libelle) {
        shiny::div(class = "chiffre",
          shiny::span(class = "chiffre-valeur",
                      format(valeur, big.mark = "\u202f", scientific = FALSE)),
          shiny::span(class = "chiffre-libelle", libelle))
      }
      shiny::div(class = "bande-chiffres",
        chiffre(n$indicateurs, tr("indicateurs")),
        chiffre(n$categories, tr("cat\u00e9gories")),
        chiffre(n$pays, tr("\u00e9conomies")),
        chiffre(n$observations, tr("observations")),
        shiny::div(class = "chiffre chiffre-maj",
          shiny::span(class = "chiffre-libelle", tr("Derni\u00e8re actualisation")),
          shiny::span(class = "chiffre-date",
                      if (is.na(n$maj)) tr("aucune collecte") else substr(n$maj, 1, 16))))
    })

    # --- manuel d'utilisation --------------------------------------------
    # Le formulaire s'affiche dans la page, et non dans une fenetre modale.
    # Trois mecanismes ont echoue avant celui-ci, tous pour la meme raison de
    # fond : ils dependaient d'une liaison etablie par Shiny ou Bootstrap dans
    # le navigateur.
    #
    #   downloadButton en pied de fenetre modale : jamais relie, clic sans effet
    #   sendCustomMessage : le gestionnaire etait enregistre depuis opesc.js,
    #     charge avant le script de Shiny, donc jamais pris en compte
    #   modalDialog : le theme Bootstrap 5 est attache a la barre d'onglets et
    #     non a la page, si bien que le balisage de la fenetre ne correspondait
    #     pas a la version de Bootstrap chargee et qu'elle ne s'ouvrait pas
    #
    # Un panneau replie dans la page et un lien vers un fichier statique ne
    # dependent de rien : ni fenetre modale, ni JavaScript, ni liaison Shiny.
    ouvert <- shiny::reactiveVal(FALSE)
    shiny::observeEvent(input$manuel, ouvert(!ouvert()))

    output$formulaire_manuel <- shiny::renderUI({
      if (!ouvert()) return(NULL)
      langue <- if (is.null(input$manuel_langue)) langue_courante() else input$manuel_langue
      format <- if (is.null(input$manuel_format)) "pdf" else input$manuel_format

      shiny::div(
        class = "formulaire-manuel",
        shiny::div(class = "formulaire-titre", tr("T\u00e9l\u00e9charger le manuel")),
        # Le compte est lu en base plutot qu'ecrit dans le texte : il change a
        # chaque evolution du catalogue, et un chiffre fige dans une phrase
        # devient faux sans que rien ne le signale.
        shiny::p(class = "manuel-note", sprintf(
          tr(paste("Le manuel pr\u00e9sente la plateforme, d\u00e9taille les cinq onglets,",
                   "expose la m\u00e9thode et recense les %d indicateurs des %d",
                   "cat\u00e9gories avec leur code de collecte et leur unit\u00e9.")),
          n_indicateurs(con), n_categories(con))),
        shiny::div(
          class = "choix-manuel",
          shiny::radioButtons(
            ns("manuel_langue"), tr("Langue du manuel"),
            choices = stats::setNames(names(LANGUES), unname(LANGUES)),
            selected = langue, inline = TRUE),
          shiny::radioButtons(
            ns("manuel_format"), tr("Format du fichier"),
            choices = c("PDF" = "pdf", "Word" = "docx"),
            selected = format, inline = TRUE)),
        shiny::div(
          class = "formulaire-actions",
          shiny::tags$a(
            class = "btn btn-opesc", role = "button",
            href = sprintf("www/manuel/manuel_opesc_%s.%s", langue, format),
            download = sprintf("Manuel_OPESc_%s.%s", toupper(langue), format),
            shiny::icon("download"), " ", tr("Valider")),
          shiny::actionLink(ns("fermer_manuel"), tr("Annuler"),
                            class = "lien-annuler")))
    })

    shiny::observeEvent(input$fermer_manuel, ouvert(FALSE))

    # Les boutons de la banniere basculent d'onglet plutot que de faire
    # defiler : la navigation reste celle de la barre, sans duplication.
    shiny::observeEvent(input$vers_tdb, {
      shiny::updateNavbarPage(parent, "onglets", selected = "Tableau de bord")
    })
    shiny::observeEvent(input$vers_base, {
      shiny::updateNavbarPage(parent, "onglets", selected = tr("Base de donn\u00e9es"))
    })
  })
}

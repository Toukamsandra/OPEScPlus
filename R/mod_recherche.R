# ---------------------------------------------------------------------------
# Recherche orientee.
#
# Ce n'est pas un moteur de recherche generaliste. Le principe est l'inverse :
# la liste des sources est fermee et choisie, et chaque lien renvoie vers la
# recherche du terme SUR le site vise. Un resultat ne peut donc pas etre hors
# sujet, ni provenir d'une source dont l'autorite n'est pas etablie.
#
# La requete est d'abord confrontee au catalogue de la plateforme : si la
# donnee est deja en base, la reponse la plus utile est celle-la, pas un lien
# vers l'exterieur.
# ---------------------------------------------------------------------------

.cache_recherche <- new.env(parent = emptyenv())

#' Liste des sources de reference
#' @noRd
sites_fiables <- function() {
  if (!is.null(.cache_recherche$sites)) return(.cache_recherche$sites)
  d <- utils::read.csv(app_sys("extdata/sites_fiables.csv"),
                       stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  .cache_recherche$sites <- d
  d
}

#' Mots-cles rattachant une requete a une categorie
#' @noRd
mots_cles <- function() {
  if (!is.null(.cache_recherche$mots)) return(.cache_recherche$mots)
  d <- utils::read.csv(app_sys("extdata/mots_cles.csv"),
                       stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  .cache_recherche$mots <- d
  d
}

#' Normalise un texte pour la comparaison
#'
#' Minuscules, sans accents, sans ponctuation. Sans cela, « dette publique » et
#' « Dette Publique » ne se rencontreraient pas, et « energie » manquerait
#' « énergie ».
#' @noRd
normaliser <- function(t) {
  t <- iconv(tolower(as.character(t)), to = "ASCII//TRANSLIT")
  t[is.na(t)] <- ""
  gsub("[^a-z0-9 ]", " ", t)
}

# Mots vides : sans ce filtre, « des » rattachait « chomage des jeunes » aux
# prix, parce que le mot figure dans « indice des prix ».
MOTS_VIDES <- c("de", "des", "du", "la", "le", "les", "un", "une", "et", "en",
                "sur", "pour", "aux", "par", "dans", "avec", "au", "the", "of",
                "and", "in", "to", "cours", "taux", "indice", "donnee", "donnees")

#' Categories auxquelles se rattache une requete
#'
#' @return codes de categorie, du plus au moins pertinent.
#' @noRd
categories_de_la_requete <- function(requete) {
  termes <- unlist(strsplit(normaliser(requete), "\\s+"))
  termes <- termes[nchar(termes) >= 3 & !termes %in% MOTS_VIDES]
  if (!length(termes)) return(character(0))

  d <- mots_cles()
  scores <- vapply(seq_len(nrow(d)), function(i) {
    mots <- unlist(strsplit(normaliser(d$mots[[i]]), "\\s+"))
    # Un terme compte s'il figure parmi les mots-cles, ou s'il en est le
    # prefixe : « exportation » doit rencontrer « exportations ».
    sum(vapply(termes, function(t) {
      any(mots == t) || any(startsWith(mots, t) & nchar(t) >= 5)
    }, logical(1)))
  }, integer(1))

  if (max(scores) == 0L) return(character(0))
  d$categorie[order(-scores)][scores[order(-scores)] > 0]
}

#' Indicateurs du catalogue correspondant a la requete
#' @noRd
indicateurs_de_la_requete <- function(con, requete, limite = 8L) {
  termes <- unlist(strsplit(normaliser(requete), "\\s+"))
  termes <- termes[nchar(termes) >= 3]
  if (!length(termes)) return(NULL)

  d <- DBI::dbGetQuery(con, "
    SELECT code_interne, libelle, categorie, unite, nb_observations
    FROM indicateur WHERE actif = 1")
  if (!nrow(d)) return(NULL)

  cible <- normaliser(d$libelle)
  scores <- vapply(seq_len(nrow(d)), function(i) {
    sum(vapply(termes, function(t) grepl(t, cible[[i]], fixed = TRUE), logical(1)))
  }, integer(1))

  d <- d[scores > 0, ]
  if (!nrow(d)) return(NULL)
  # Les indicateurs deja collectes d'abord : un resultat sans donnee derriere
  # n'aide pas.
  d <- d[order(-scores[scores > 0], d$nb_observations == 0, d$libelle), ]
  utils::head(d, limite)
}

TYPES <- c(donnees = "Donn\u00e9es", publication = "Publications",
           actualite = "Actualit\u00e9")

#' Liens vers les sources, ordonnes par pertinence
#'
#' @param requete texte saisi par l'utilisateur.
#' @param categories categories detectees.
#' @param types types de resultats retenus. Le type filtre, il n'entre pas
#'   dans le calcul de pertinence : une actualite reste rattachee a ses
#'   categories comme une base de donnees.
#' @noRd
liens_de_la_requete <- function(requete, categories, types = names(TYPES)) {
  d <- sites_fiables()
  d <- d[d$type %in% types, , drop = FALSE]
  if (!nrow(d)) return(d)
  q <- utils::URLencode(trimws(requete), reserved = TRUE)
  d$url <- vapply(d$gabarit, function(g) gsub("{q}", q, g, fixed = TRUE),
                  character(1), USE.NAMES = FALSE)

  # Le classement croise deux ordres. Celui de la requete : la premiere
  # categorie detectee compte plus que la troisieme. Et celui du site : les
  # categories y sont listees par ordre d'importance, si bien qu'un site dont
  # le sujet est la premiere specialite passe devant un site qui ne le traite
  # qu'accessoirement. Sans ce second critere, une recherche sur le cacao
  # placait l'Agence internationale de l'energie avant la page des marches de
  # produits de base de la Banque mondiale.
  d$score <- vapply(seq_len(nrow(d)), function(i) {
    couvertes <- unlist(strsplit(d$categories[[i]], " ", fixed = TRUE))
    meilleur <- 0L
    for (rang_requete in seq_along(categories)) {
      rang_site <- match(categories[[rang_requete]], couvertes)
      if (is.na(rang_site)) next
      # Trois criteres, par ordre decroissant de poids.
      #   1. Le rang de la categorie dans la requete : la premiere detectee
      #      pese davantage que la troisieme.
      #   2. Le rang de la categorie chez le site : ses categories sont
      #      listees par ordre d'importance.
      #   3. La specialisation : a rang egal, un site qui couvre trois sujets
      #      est plus pertinent qu'un portail qui en couvre huit. Sans ce
      #      dernier critere, une recherche sur le cacao placait le portail
      #      generaliste du FMI avant la page des marches de produits de base
      #      de la Banque mondiale.
      valeur <- (length(categories) - rang_requete + 1L) * 1000L +
                (10L - min(rang_site, 9L)) * 10L +
                (10L - min(length(couvertes), 9L))
      if (valeur > meilleur) meilleur <- as.integer(valeur)
    }
    meilleur
  }, integer(1))

  d[order(-d$score, d$nom), ]
}

ONGLETS <- c(tout = "Tout", images = "Images", actualite = "Actualit\u00e9",
             videos = "Vid\u00e9os")

mod_recherche_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "cadre cadre-recherche",
      shiny::div(class = "cadre-titre", "GoogleOPESc+"),
      shiny::p(class = "meta", tr(paste(
        "Recherchez un sujet, un indicateur, un pays ou une actualit\u00e9. Les",
        "r\u00e9sultats proviennent d'un ensemble ferm\u00e9 de sources institutionnelles :",
        "aucun r\u00e9sultat hors sujet, aucune source dont l'autorit\u00e9 n'est pas",
        "\u00e9tablie."))),
      shiny::div(class = "zone-saisie",
        shiny::div(class = "barre-recherche",
          shiny::textInput(ns("requete"), NULL, width = "100%",
                           placeholder = tr("Sujet, indicateur, pays ou actualit\u00e9")),
          shiny::actionButton(ns("chercher"), tr("Rechercher"),
                              class = "btn-opesc", icon = shiny::icon("search"))),
        # Les propositions s'affichent pendant la frappe, sous le champ, comme
        # une liste de completion.
        shiny::uiOutput(ns("propositions"))),
      shiny::uiOutput(ns("exemples"))),

    shiny::uiOutput(ns("onglets")),
    shiny::uiOutput(ns("resultats")),

    if (widget_recherche_actif()) {
      shiny::div(class = "cadre cadre-widget",
        shiny::div(class = "cadre-titre", tr("Recherche sur le web")),
        shiny::p(class = "meta", tr(paste(
          "Le moteur ci-dessous est restreint aux sources de r\u00e9f\u00e9rence de la",
          "plateforme. Il apporte ses propres onglets : tout, images,",
          "actualit\u00e9s."))),
        balises_widget())
    })
}

mod_recherche_server <- function(id, con, parent) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    lancee <- shiny::reactiveVal("")
    onglet <- shiny::reactiveVal("tout")

    lancer <- function(terme) {
      lancee(trimws(terme))
      onglet("tout")
    }
    shiny::observeEvent(input$chercher, lancer(input$requete))

    # --- propositions pendant la frappe ----------------------------------
    output$propositions <- shiny::renderUI({
      saisie <- input$requete
      if (is.null(saisie) || identical(trimws(saisie), lancee())) return(NULL)
      props <- propositions(saisie, con)
      if (!length(props)) return(NULL)

      shiny::div(class = "propositions",
        lapply(seq_along(props), function(i) {
          shiny::actionLink(ns(paste0("prop_", i)), props[[i]],
                            class = "proposition")
        }))
    })

    # Les propositions sont en nombre fixe : les observateurs sont crees une
    # fois, et lisent le libelle courant au moment du clic. Les recreer a
    # chaque frappe remettrait leur compteur a zero et declencherait des
    # recherches fantomes.
    lapply(seq_len(8L), function(i) {
      shiny::observeEvent(input[[paste0("prop_", i)]], {
        props <- propositions(input$requete, con)
        if (length(props) >= i) {
          shiny::updateTextInput(session, "requete", value = props[[i]])
          lancer(props[[i]])
        }
      }, ignoreInit = TRUE)
    })

    # --- exemples, tant qu'aucune recherche n'a ete lancee ---------------
    EXEMPLES <- c("dette publique", "inflation", "cours du cacao",
                  "taux de change", "complexit\u00e9 \u00e9conomique",
                  "politique mon\u00e9taire BEAC")

    output$exemples <- shiny::renderUI({
      if (nzchar(lancee())) return(NULL)
      shiny::div(class = "suggestions",
        shiny::span(class = "petit", tr("Exemples")),
        lapply(seq_along(EXEMPLES), function(i) {
          shiny::actionLink(ns(paste0("ex_", i)), EXEMPLES[[i]],
                            class = "suggestion")
        }))
    })

    lapply(seq_along(EXEMPLES), function(i) {
      shiny::observeEvent(input[[paste0("ex_", i)]], {
        shiny::updateTextInput(session, "requete", value = EXEMPLES[[i]])
        lancer(EXEMPLES[[i]])
      }, ignoreInit = TRUE)
    })

    # --- barre d'onglets -------------------------------------------------
    output$onglets <- shiny::renderUI({
      if (!nzchar(lancee()) || !recherche_web_active()) return(NULL)
      actif <- onglet()
      shiny::div(class = "onglets-recherche",
        lapply(names(ONGLETS), function(cle) {
          shiny::actionLink(
            ns(paste0("onglet_", cle)), tr(ONGLETS[[cle]]),
            class = paste("onglet-recherche",
                          if (cle == actif) "onglet-actif"))
        }))
    })

    lapply(names(ONGLETS), function(cle) {
      shiny::observeEvent(input[[paste0("onglet_", cle)]], onglet(cle),
                          ignoreInit = TRUE)
    })

    output$resultats <- shiny::renderUI({
      q <- lancee()
      if (!nzchar(q)) return(NULL)
      vue <- onglet()

      categories <- categories_de_la_requete(q)
      libelles_cat <- DBI::dbGetQuery(con, "SELECT code, libelle FROM categorie")
      nom_categorie <- function(code) {
        l <- libelles_cat$libelle[libelles_cat$code == code]
        if (length(l)) tr(l[[1]]) else code
      }

      # Le nombre de sources proposees est desormais borne. En afficher
      # trente-cinq a chaque recherche revenait a ne rien filtrer du tout :
      # seules celles qui traitent reellement du sujet sont retenues, et six
      # au maximum. A defaut de rattachement thematique, on garde les
      # generalistes plutot que la liste entiere.
      types_utiles <- if (identical(vue, "actualite")) "actualite"
                      else if (identical(vue, "tout")) names(TYPES)
                      else names(TYPES)
      liens <- liens_de_la_requete(q, categories, types_utiles)
      pertinents <- liens[liens$score > 0, , drop = FALSE]
      if (!nrow(pertinents)) pertinents <- utils::head(liens, 4L)
      pertinents <- utils::head(pertinents[order(-pertinents$score, pertinents$nom), ], 6L)

      resultats <- rechercher_web(q, 10L, vue)
      definition <- if (identical(vue, "tout")) definir(q) else NULL
      indicateurs <- if (identical(vue, "tout"))
        indicateurs_de_la_requete(con, q, limite = 4L) else NULL

      shiny::div(class = "cadre cadre-resultats",

        # --- definition de la notion ------------------------------------
        if (!is.null(definition)) {
          shiny::div(class = "bloc-definition",
            shiny::div(class = "definition-entete",
              shiny::span(class = "definition-terme", definition$terme),
              if (nzchar(definition$categorie)) {
                shiny::span(class = "definition-categorie",
                            nom_categorie(definition$categorie))
              }),
            shiny::p(class = "definition-texte", definition$definition))
        },

        # --- ce que la plateforme contient deja -------------------------
        # Chaque indicateur porte sa definition et la source qui en repond.
        # Une definition sans source ne vaut rien dans un document
        # administratif : celle de la Banque mondiale engage la Banque
        # mondiale, une definition anonyme n'engage personne.
        if (!is.null(indicateurs) && nrow(indicateurs)) {
          shiny::div(class = "bloc-interne",
            shiny::div(class = "bloc-interne-titre",
                       tr("Disponible dans la plateforme")),
            lapply(seq_len(nrow(indicateurs)), function(i) {
              r <- indicateurs[i, ]
              def <- lire_definition(con, r$code_interne)
              shiny::div(class = "resultat-interne",
                shiny::strong(tr(r$libelle)),
                shiny::span(class = "resultat-meta", sprintf(
                  "%s \u00b7 %s", nom_categorie(r$categorie),
                  if (r$nb_observations > 0)
                    sprintf(tr("%d observations"), r$nb_observations)
                  else tr("sans donn\u00e9es"))),
                if (!is.null(def)) {
                  shiny::tagList(
                    shiny::p(class = "resultat-definition", def$texte),
                    shiny::span(class = "resultat-source",
                                sprintf(tr("Source de la d\u00e9finition : %s"),
                                        def$source)))
                } else {
                  shiny::span(class = "resultat-sans-definition",
                              tr("D\u00e9finition non renseign\u00e9e. Lancez collecter_definitions()."))
                })
            }))
        },

        # --- resultats du web -------------------------------------------
        if (recherche_web_active()) {
          if (is.null(resultats) || !nrow(resultats)) {
            shiny::p(class = "note", tr(
              "Aucun r\u00e9sultat sur les sources retenues pour cet onglet."))
          } else if (identical(vue, "images")) {
            shiny::div(class = "grille-images",
              lapply(seq_len(nrow(resultats)), function(i) {
                r <- resultats[i, ]
                shiny::tags$a(class = "vignette", href = r$url, target = "_blank",
                              rel = "noopener",
                  shiny::img(src = r$vignette, alt = r$titre, loading = "lazy"),
                  shiny::span(class = "vignette-legende", r$titre))
              }))
          } else {
            shiny::div(class = "liste-resultats",
              lapply(seq_len(nrow(resultats)), function(i) {
                r <- resultats[i, ]
                organisme <- organisme_du_domaine(r$domaine)
                shiny::div(class = if (i == 1) "resultat resultat-premier"
                                   else "resultat",
                  shiny::div(class = "resultat-fil",
                    shiny::span(if (nzchar(organisme)) organisme else r$domaine),
                    shiny::span(class = "resultat-url", r$domaine)),
                  shiny::tags$a(class = "resultat-titre", href = r$url,
                                target = "_blank", rel = "noopener", r$titre),
                  shiny::p(class = "resultat-extrait", r$extrait))
              }))
          }
        },

        # --- sources a interroger, en nombre limite ---------------------
        if (nrow(pertinents)) {
          shiny::tagList(
            shiny::div(class = "separateur-resultats",
              if (recherche_web_active()) tr("Interroger directement les sources")
              else sprintf(tr("Sources de r\u00e9f\u00e9rence sur ce sujet%s"),
                           if (length(categories))
                             paste0(" : ", nom_categorie(categories[[1]])) else "")),
            shiny::div(class = "liste-resultats",
              lapply(seq_len(nrow(pertinents)), function(i) {
                r <- pertinents[i, ]
                shiny::div(class = if (i == 1 && !recherche_web_active())
                                     "resultat resultat-premier" else "resultat",
                  shiny::div(class = "resultat-fil",
                    shiny::span(r$organisme),
                    shiny::span(class = "resultat-type", tr(TYPES[[r$type]]))),
                  shiny::tags$a(class = "resultat-titre", href = r$url,
                                target = "_blank", rel = "noopener", r$nom),
                  shiny::p(class = "resultat-extrait", tr(r$description)))
              })))
        },

        if (identical(mode_recherche(), "aucun")) {
          shiny::div(class = "note",
            shiny::p(tr(paste(
              "La recherche sur le web n'est pas configur\u00e9e : seuls les acc\u00e8s",
              "aux sources sont propos\u00e9s. Voir configurer_recherche()."))))
        } else if (widget_recherche_actif()) {
          shiny::div(class = "note",
            shiny::p(tr(paste(
              "Les r\u00e9sultats du web s'affichent dans le moteur int\u00e9gr\u00e9, plus bas.",
              "Ajoutez une clef d'API pour que la plateforme les mette elle-m\u00eame",
              "en forme, avec ses propres onglets."))))
        })
    })
  })
}

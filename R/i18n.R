# ---------------------------------------------------------------------------
# Bilinguisme francais-anglais.
#
# Le mecanisme est volontairement simple : la langue est portee par le
# parametre `lang` de l'adresse, et changer de langue recharge la page. C'est
# ce qui permet de traduire l'integralite de l'interface, y compris les
# libelles construits une seule fois au demarrage, sans transformer chaque
# element en sortie reactive.
#
# Le dictionnaire vit dans inst/extdata/traductions.csv, deux colonnes : le
# francais fait office de cle. Ajouter une traduction se fait donc en ajoutant
# une ligne, sans toucher au code. Une chaine absente du dictionnaire est
# renvoyee telle quelle : il vaut mieux un mot en francais dans une interface
# anglaise qu'une case vide.
# ---------------------------------------------------------------------------

LANGUES <- c(fr = "Fran\u00e7ais", en = "English")

.i18n <- new.env(parent = emptyenv())

#' Dictionnaire, charge une seule fois
#' @noRd
dictionnaire <- function() {
  if (!is.null(.i18n$table)) return(.i18n$table)
  chemin <- app_sys("extdata/traductions.csv")
  t <- if (nzchar(chemin) && file.exists(chemin)) {
    utils::read.csv(chemin, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  } else {
    data.frame(fr = character(), en = character(), stringsAsFactors = FALSE)
  }
  .i18n$table <- stats::setNames(t$en, t$fr)
  .i18n$table
}

#' Langue de la session courante
#'
#' @param request objet de requete Shiny. Quand il est fourni, la langue est
#'   lue dans l'adresse ; sinon on rend la derniere langue retenue.
#' @noRd
langue_courante <- function(request = NULL) {
  if (!is.null(request)) {
    q <- shiny::parseQueryString(request$QUERY_STRING %||% "")
    lang <- q$lang
    if (!is.null(lang) && lang %in% names(LANGUES)) {
      .i18n$langue <- lang
      return(lang)
    }
  }
  if (is.null(.i18n$langue)) "fr" else .i18n$langue
}

#' Fixe la langue depuis une session Shiny
#'
#' L'interface lit la langue dans la requete, mais le serveur produit lui aussi
#' des libelles apres coup : notifications, en-tetes de tableaux, messages
#' d'etat. Sans ce rappel, ils resteraient dans la langue de la session
#' precedente.
#'
#' Limite connue : la langue est portee par une variable du paquet, donc
#' partagee entre sessions. Deux utilisateurs simultanes ayant choisi des
#' langues differentes verraient l'un des deux basculer. C'est acceptable pour
#' un usage interne a quelques agents ; au-dela, il faudrait porter la langue
#' dans chaque module.
#' @noRd
fixer_langue_session <- function(session) {
  shiny::observe({
    recherche <- session$clientData$url_search
    if (!is.null(recherche)) langue_courante(list(QUERY_STRING = recherche))
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Traduit une chaine
#'
#' @param texte chaine en francais, telle qu'elle figure dans le dictionnaire.
#' @export
tr <- function(texte) {
  if (!length(texte)) return(texte)
  if (langue_courante() == "fr") return(texte)

  d <- dictionnaire()
  # `match` et non `d[[cle]]`. Le dictionnaire est un vecteur nomme, et sur un
  # vecteur atomique `[[` leve « indice hors limites » pour une cle absente au
  # lieu de rendre NULL, contrairement a une liste. Toute chaine hors
  # dictionnaire faisait donc echouer la construction de l'interface entiere,
  # et comme la fonction sort avant en francais, seul l'anglais tombait.
  i <- match(as.character(texte), names(d))
  traduit <- unname(d[i])
  manquant <- is.na(i) | is.na(traduit) | !nzchar(traduit)
  traduit[manquant] <- as.character(texte)[manquant]
  traduit
}

#' Selecteur de langue
#'
#' Une liste deroulante sur fond blanc. Le changement de langue recharge la
#' page avec le parametre `lang`, ce qui permet de traduire l'integralite de
#' l'interface, y compris les libelles construits une seule fois au demarrage.
#' @noRd
selecteur_langue <- function() {
  active <- langue_courante()
  shiny::div(
    class = "selecteur-langue",
    shiny::tags$label(`for` = "choix-langue", class = "langue-etiquette", tr("Langue")),
    shiny::tags$select(
      id = "choix-langue", class = "langue-liste",
      onchange = "window.location.search = '?lang=' + this.value;",
      lapply(names(LANGUES), function(code) {
        shiny::tags$option(value = code, selected = if (code == active) "selected",
                           LANGUES[[code]])
      })))
}

#' Chemin d'un manuel d'utilisation
#'
#' @param langue "fr" ou "en".
#' @param format "pdf" ou "docx".
#' @noRd
chemin_manuel <- function(langue = "fr", format = "pdf") {
  langue <- match.arg(langue, names(LANGUES))
  format <- match.arg(format, c("pdf", "docx"))
  app_sys(sprintf("extdata/manuel/manuel_opesc_%s.%s", langue, format))
}

#' Verifie que les manuels sont bien en place
#'
#' Le telechargement pointe vers un fichier servi depuis inst/app/www. S'il
#' manque, le navigateur recoit une erreur 404 sans le moindre message a
#' l'ecran, ce qui donne l'impression que le bouton ne fait rien.
#'
#' @examples
#' \dontrun{
#' verifier_manuels()
#' }
#' @export
verifier_manuels <- function() {
  combinaisons <- expand.grid(langue = names(LANGUES),
                              format = c("pdf", "docx"),
                              stringsAsFactors = FALSE)
  combinaisons$fichier <- sprintf("manuel_opesc_%s.%s",
                                  combinaisons$langue, combinaisons$format)
  combinaisons$chemin <- vapply(combinaisons$fichier, function(f) {
    app_sys(file.path("app/www/manuel", f))
  }, character(1), USE.NAMES = FALSE)
  combinaisons$present <- nzchar(combinaisons$chemin) & file.exists(combinaisons$chemin)
  combinaisons$taille_ko <- ifelse(combinaisons$present,
                                   round(file.size(combinaisons$chemin) / 1024), NA)
  combinaisons$adresse <- file.path("www/manuel", combinaisons$fichier)

  if (all(combinaisons$present)) {
    message("Les quatre manuels sont en place. Si le t\u00e9l\u00e9chargement ne d\u00e9marre pas, ",
            "ouvrez directement http://127.0.0.1:PORT/www/manuel/manuel_opesc_fr.pdf ",
            "en rempla\u00e7ant PORT par celui affich\u00e9 au lancement.")
  } else {
    message("Manuels manquants. Placez-les dans inst/app/www/manuel/ du projet.")
  }
  combinaisons[c("fichier", "present", "taille_ko", "adresse")]
}

.cache_noms <- new.env(parent = emptyenv())

#' Traduit un nom de pays ou d'agregat
#'
#' Les noms viennent de la Banque mondiale, qui ne publie qu'en anglais. Le
#' dictionnaire ordinaire ne convient pas : il va du francais vers l'anglais,
#' et ces noms sont deja dans la langue d'arrivee. Une table dediee fait donc
#' le chemin inverse, et seulement quand l'interface est en francais.
#'
#' Un nom absent de la table est rendu tel quel : mieux vaut un nom anglais
#' qu'un blanc, et la table ne couvre que les agregats, dont le nom est
#' vraiment genant en anglais.
#'
#' @param nom nom publie par la source.
#' @noRd
nom_traduit <- function(nom) {
  if (!identical(langue_courante(), "fr")) return(nom)

  if (is.null(.cache_noms$table)) {
    chemin <- app_sys("extdata/noms_pays_fr.csv")
    d <- if (nzchar(chemin) && file.exists(chemin)) {
      utils::read.csv(chemin, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
    } else {
      data.frame(en = character(), fr = character(), stringsAsFactors = FALSE)
    }
    .cache_noms$table <- stats::setNames(d$fr, d$en)
  }

  i <- match(nom, names(.cache_noms$table))
  ifelse(is.na(i), nom, .cache_noms$table[i])
}

# ---------------------------------------------------------------------------
# Definitions des indicateurs.
#
# Elles sont recuperees aupres du fournisseur de chaque serie, et non redigees
# ici. Deux raisons.
#
# La premiere tient a l'autorite : dans un document administratif, une
# definition sans source ne vaut rien. Celle de la Banque mondiale pour le
# produit interieur brut engage la Banque mondiale, la mienne n'engagerait
# personne.
#
# La seconde tient a l'exactitude : trois cents definitions redigees a la main
# comporteraient des approximations, et les approximations sur une definition
# d'indicateur se propagent ensuite dans les notes qui l'emploient.
#
# La Banque mondiale publie, pour chaque indicateur, un texte de definition et
# le nom de l'organisme qui en repond. Ces deux champs sont repris tels quels.
# ---------------------------------------------------------------------------

API_INDICATEUR <- "https://api.worldbank.org/v2/indicator"

#' Recupere les definitions des indicateurs
#'
#' Interroge la Banque mondiale pour les series qui en proviennent, et retombe
#' sur le glossaire de la plateforme pour les autres. Chaque definition est
#' enregistree avec la source qui en repond.
#'
#' @param forcer si TRUE, recupere aussi les definitions deja presentes.
#' @param pause secondes entre deux appels.
#'
#' @return nombre de definitions enregistrees, de facon invisible.
#'
#' @examples
#' \dontrun{
#' collecter_definitions()
#' }
#' @export
collecter_definitions <- function(forcer = FALSE, pause = 0.2) {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  requete <- "SELECT code_interne, code_source, libelle, source
              FROM indicateur WHERE actif = 1"
  if (!forcer) {
    requete <- paste(requete,
      "AND code_interne NOT IN (SELECT code_interne FROM definition)")
  }
  d <- DBI::dbGetQuery(con, paste(requete, "ORDER BY categorie, libelle"))

  if (!nrow(d)) {
    message("Toutes les definitions sont deja enregistrees.")
    return(invisible(0L))
  }
  cat(sprintf("%d indicateurs a traiter.\n", nrow(d)))
  cat(sprintf("Comptez environ %s : un appel par indicateur.\n\n",
              format(.POSIXct(nrow(d) * (pause + 0.6), tz = "UTC"), "%M min %S s")))
  depart <- Sys.time()

  enregistrees <- 0L
  depuis_glossaire <- 0L

  for (i in seq_len(nrow(d))) {
    ligne <- d[i, ]
    def <- NULL

    if (grepl("^Banque mondiale", ligne$source)) {
      # La Banque mondiale ne publie ses definitions qu'en anglais : la langue
      # est enregistree avec le texte, faute de quoi l'interface francaise
      # afficherait de l'anglais sans le dire.
      def <- definition_banque_mondiale(ligne$code_source, pause)
      if (!is.null(def)) def$langue <- "en"
    }

    # A defaut, le glossaire de la plateforme, dont la source est nommee comme
    # telle : l'utilisateur doit savoir que la definition vient d'ici et non
    # de l'institution qui publie la serie.
    if (is.null(def)) {
      interne <- definir(ligne$libelle)
      if (!is.null(interne)) {
        # La source nommee est celle du manuel de reference, non la
        # plateforme : une definition doit renvoyer a une autorite.
        def <- list(texte = interne$definition,
                    source = if (isTRUE(nzchar(interne$source %||% "")))
                               interne$source else "Glossaire OPESc+",
                    langue = langue_courante())
        depuis_glossaire <- depuis_glossaire + 1L
      }
    }

    if (is.null(def)) next

    DBI::dbExecute(con, "
      INSERT INTO definition (code_interne, texte, source, langue, recuperee)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT (code_interne) DO UPDATE
      SET texte = excluded.texte, source = excluded.source,
          langue = excluded.langue, recuperee = excluded.recuperee",
      params = list(ligne$code_interne, def$texte, def$source,
                    def$langue %||% "en", format(Sys.Date(), "%Y-%m-%d")))
    enregistrees <- enregistrees + 1L

    # L'avancement est imprime sur des lignes distinctes : le retour chariot
    # n'a aucun effet dans certaines consoles, et l'utilisateur se retrouvait
    # devant un ecran fige pendant dix minutes.
    if (i %% 10 == 0 || i == nrow(d)) {
      ecoule <- as.numeric(difftime(Sys.time(), depart, units = "secs"))
      cat(sprintf("  %3d/%d  %d definitions  (reste ~%s)\n", i, nrow(d),
                  enregistrees,
                  format(.POSIXct(ecoule / i * (nrow(d) - i), tz = "UTC"),
                         "%M:%S")))
      utils::flush.console()
    }
  }

  cat(sprintf("\r  %d definitions enregistrees, dont %d issues du glossaire.\n",
              enregistrees, depuis_glossaire))

  manquantes <- DBI::dbGetQuery(con, "
    SELECT source, COUNT(*) AS n FROM indicateur
    WHERE actif = 1 AND code_interne NOT IN (SELECT code_interne FROM definition)
    GROUP BY source ORDER BY n DESC")
  if (nrow(manquantes)) {
    cat("\nSans definition, par fournisseur :\n")
    for (j in seq_len(nrow(manquantes))) {
      cat(sprintf("  %-32s %d\n", manquantes$source[[j]], manquantes$n[[j]]))
    }
    cat("Ces fournisseurs ne publient pas de definition interrogeable.\n")
  }
  invisible(enregistrees)
}

#' Definition publiee par la Banque mondiale
#'
#' L'interface rend deux champs utiles : le texte de definition et le nom de
#' l'organisme qui en repond. Les deux sont conserves.
#' @noRd
definition_banque_mondiale <- function(code, pause = 0.2) {
  url <- sprintf("%s/%s", API_INDICATEUR, utils::URLencode(code, reserved = TRUE))
  reponse <- tryCatch(
    appel(url, list(format = "json"), pause = pause),
    error = function(e) NULL)
  if (is.null(reponse)) return(NULL)

  corps <- tryCatch(
    jsonlite::fromJSON(httr2::resp_body_string(reponse), simplifyVector = FALSE),
    error = function(e) NULL)
  # La reponse est un couple : les metadonnees de pagination, puis les
  # resultats. Un code inconnu ne rend que le premier element.
  if (is.null(corps) || length(corps) < 2 || !length(corps[[2]])) return(NULL)

  item <- corps[[2]][[1]]
  texte <- item$sourceNote
  if (is.null(texte) || !nzchar(trimws(texte))) return(NULL)

  organisme <- item$sourceOrganization
  if (is.null(organisme) || !nzchar(trimws(organisme))) {
    organisme <- "Banque mondiale"
  }
  list(texte = trimws(texte), source = trimws(organisme))
}

#' Etat des definitions
#'
#' @examples
#' \dontrun{
#' diagnostic_definitions()
#' }
#' @export
diagnostic_definitions <- function() {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  d <- DBI::dbGetQuery(con, "
    SELECT c.libelle AS categorie,
           COUNT(i.code_interne) AS indicateurs,
           SUM(CASE WHEN d.code_interne IS NOT NULL THEN 1 ELSE 0 END) AS definis
    FROM indicateur i
    JOIN categorie c ON c.code = i.categorie
    LEFT JOIN definition d ON d.code_interne = i.code_interne
    WHERE i.actif = 1
    GROUP BY c.libelle, c.ordre ORDER BY c.ordre")
  print(d, row.names = FALSE)

  sources <- DBI::dbGetQuery(con, "
    SELECT source, COUNT(*) AS n FROM definition GROUP BY source ORDER BY n DESC")
  if (nrow(sources)) {
    cat("\nSources des definitions :\n")
    print(sources, row.names = FALSE)
  }
  invisible(d)
}

#' Definition a afficher, dans la langue de l'interface si possible
#'
#' Trois cas, dans cet ordre.
#'
#'   La definition enregistree est dans la langue courante : elle est retenue.
#'   Le glossaire de la plateforme connait la notion : sa definition est
#'     retenue, traduite, et sa source est celle du manuel de reference.
#'   A defaut, la definition du fournisseur est affichee telle quelle, avec la
#'     mention de sa langue.
#'
#' Ce dernier cas n'est pas satisfaisant, mais il vaut mieux qu'une absence :
#' une definition en anglais renseigne davantage qu'un blanc, pourvu que le
#' lecteur sache qu'elle est en anglais.
#'
#' @param con connexion ouverte.
#' @param code_interne identifiant de l'indicateur.
#' @param libelle libelle de l'indicateur, pour interroger le glossaire.
#' @noRd
definition_affichable <- function(con, code_interne, libelle) {
  courante <- langue_courante()
  enregistree <- lire_definition(con, code_interne)

  if (!is.null(enregistree) && identical(enregistree$langue, courante)) {
    return(enregistree)
  }

  # Le glossaire est interroge sur le libelle de l'indicateur : « Dette
  # publique brute » y retrouve la notion de dette publique.
  interne <- tryCatch(definir(libelle), error = function(e) NULL)
  if (!is.null(interne)) {
    return(list(texte = interne$definition,
                source = if (isTRUE(nzchar(interne$source %||% "")))
                           interne$source else "Glossaire OPESc+",
                langue = courante))
  }
  enregistree
}

#' Corrige la langue des definitions deja enregistrees
#'
#' A utiliser quand les definitions sont en base mais que leur langue n'y
#' figure pas, ce qui est le cas des bases anterieures a son introduction.
#' Aucune requete n'est emise : la langue se deduit de la source.
#'
#' Cela evite une recollecte complete, qui demande une dizaine de minutes pour
#' un resultat identique.
#'
#' @examples
#' \dontrun{
#' marquer_langue_definitions()
#' }
#' @export
marquer_langue_definitions <- function() {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # Les fournisseurs internationaux ne publient qu'en anglais ; tout ce qui
  # vient des manuels de reference a ete redige en francais dans le glossaire.
  n_en <- DBI::dbExecute(con, "
    UPDATE definition SET langue = 'en'
    WHERE source NOT LIKE '%Glossaire%'
      AND source NOT LIKE '%Syst\u00e8me de comptabilit\u00e9%'
      AND source NOT LIKE '%Manuel%'
      AND source NOT LIKE '%R\u00e9solutions%'
      AND source NOT LIKE '%Convention%'
      AND source NOT LIKE '%Cadre de viabilit\u00e9%'
      AND source NOT LIKE '%Comit\u00e9 d'' aide%'")

  n_fr <- DBI::dbExecute(con, "
    UPDATE definition SET langue = 'fr'
    WHERE source LIKE '%Glossaire%'
       OR source LIKE '%Syst\u00e8me de comptabilit\u00e9%'
       OR source LIKE '%Manuel%'
       OR source LIKE '%R\u00e9solutions%'
       OR source LIKE '%Convention%'
       OR source LIKE '%Cadre de viabilit\u00e9%'")

  cat(sprintf("%d definitions marquees en anglais, %d en francais.\n", n_en, n_fr))
  cat("Aucune requete n'a ete emise.\n")
  invisible(n_en + n_fr)
}


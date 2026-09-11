# ---------------------------------------------------------------------------
# Fraicheur des donnees et collecte planifiee.
#
# Une plateforme dont les donnees vieillissent en silence est pire qu'une
# plateforme vide : elle affiche des chiffres perimes avec la meme assurance
# que des chiffres recents, et rien ne distingue les deux a l'ecran.
#
# Deux dispositions repondent a cela, et l'ordre compte.
#
# La premiere est de le dire. Un bandeau annonce l'age des donnees des qu'il
# depasse un seuil, et la mention suit l'utilisateur sur tous les onglets.
# Elle vaut meme si personne n'automatise jamais rien.
#
# La seconde est d'automatiser. Un script s'execute chaque semaine sur un
# poste de la division, collecte ce qui manque, reconstruit la base publiee et
# journalise. Il ne publie pas de lui-meme : pousser sur un depot demande une
# authentification, et une machine qui publie sans surveillance finirait par
# publier une base corrompue.
# ---------------------------------------------------------------------------

# Au-dela de ce nombre de jours, la plateforme signale l'age des donnees.
# Quarante-cinq jours correspondent au rythme de revision des principales
# sources : la Banque mondiale revise deux a quatre fois l'an, le Fonds
# monetaire international publie en avril et octobre.
SEUIL_FRAICHEUR <- 45L
SEUIL_ALERTE <- 120L

#' Age des donnees, en jours
#'
#' Fonde sur la derniere collecte reussie, non sur la date de la derniere
#' observation : une serie peut s'arreter en 2023 parce que la source n'a rien
#' publie depuis, sans que la plateforme soit pour autant en retard.
#'
#' @param con connexion ouverte.
#' @return liste (jours, date, indicateurs), ou NULL si rien n'a ete collecte.
#' @noRd
age_donnees <- function(con) {
  d <- tryCatch(DBI::dbGetQuery(con, "
    SELECT MAX(derniere_collecte) AS derniere,
           COUNT(*) AS n
    FROM indicateur
    WHERE actif = 1 AND derniere_collecte IS NOT NULL"),
    error = function(e) NULL)

  if (is.null(d) || !nrow(d) || is.na(d$derniere[[1]])) return(NULL)

  date <- as.Date(substr(d$derniere[[1]], 1, 10))
  if (is.na(date)) return(NULL)

  list(jours = as.integer(Sys.Date() - date),
       date = date,
       indicateurs = d$n[[1]])
}

#' Bandeau signalant des donnees anciennes
#'
#' Rien n'est affiche tant que les donnees sont recentes : une mention
#' permanente deviendrait du decor et ne serait plus lue le jour ou elle
#' compte.
#' @noRd
bandeau_fraicheur <- function(con) {
  age <- tryCatch(age_donnees(con), error = function(e) NULL)
  if (is.null(age) || age$jours <= SEUIL_FRAICHEUR) return(NULL)

  alerte <- age$jours > SEUIL_ALERTE
  shiny::div(
    class = paste("bandeau-fraicheur", if (alerte) "fraicheur-alerte"),
    shiny::span(class = "fraicheur-icone", if (alerte) "\u26A0" else "\u24D8"),
    shiny::span(
      shiny::strong(sprintf(
        tr("Donn\u00e9es actualis\u00e9es il y a %d jours"), age$jours)),
      shiny::span(class = "fraicheur-detail",
        if (alerte) {
          tr(paste("Elles sont probablement d\u00e9pass\u00e9es. Avant de les citer,",
                   "v\u00e9rifiez aupr\u00e8s de la source ou relancez une collecte."))
        } else {
          tr(paste("Les sources r\u00e9visent leurs s\u00e9ries plusieurs fois par an :",
                   "une actualisation est conseill\u00e9e."))
        })))
}

#' Collecte planifiee, destinee a une tache automatique
#'
#' Collecte ce qui manque, reconstruit la base destinee a la publication, et
#' ecrit un compte rendu dans un fichier. Elle ne pousse rien sur le depot :
#' cela demande une authentification, et une machine qui publie sans
#' surveillance finirait par publier une base corrompue un jour de panne.
#'
#' @param journal chemin du compte rendu. NULL pour ecrire a cote de la base.
#' @param publier si TRUE, reconstruit aussi la base compacte.
#' @param annee_min profondeur retenue pour la base publiee.
#'
#' @examples
#' \dontrun{
#' collecte_hebdomadaire()
#' }
#' @export
collecte_hebdomadaire <- function(journal = NULL, publier = TRUE,
                                  annee_min = 1990) {
  debut <- Sys.time()
  if (is.null(journal)) {
    journal <- file.path(dirname(chemin_base()), "collecte_planifiee.log")
  }

  noter <- function(...) {
    ligne <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                     paste0(...))
    cat(ligne, "\n", sep = "")
    cat(ligne, "\n", file = journal, sep = "", append = TRUE)
  }

  noter("Debut de la collecte planifiee.")

  resultat <- tryCatch({
    con <- connexion()
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    avant <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM observation")$n
    DBI::dbDisconnect(con)
    on.exit()

    collecter_manquants()

    con <- connexion()
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    apres <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM observation")$n
    noter(sprintf("%d observations avant, %d apres, soit %+d.",
                  avant, apres, apres - avant))
    list(ok = TRUE, ajoutees = apres - avant)
  }, error = function(e) {
    noter("ECHEC de la collecte : ", conditionMessage(e))
    list(ok = FALSE, ajoutees = 0L)
  })

  if (resultat$ok && publier) {
    tryCatch({
      preparer_publication(annee_min = annee_min)
      base <- file.path("inst", "extdata", "opesc.sqlite")
      if (file.exists(base)) {
        noter(sprintf("Base publiee reconstruite : %.0f Mo.",
                      file.size(base) / 1024^2))
      }
    }, error = function(e) {
      noter("ECHEC de la preparation : ", conditionMessage(e))
    })
  }

  duree <- as.numeric(difftime(Sys.time(), debut, units = "mins"))
  noter(sprintf("Termine en %.0f minutes.", duree))

  if (resultat$ok && publier) {
    noter("Il reste a pousser sur le depot pour mettre en ligne :")
    noter("  git add . && git commit -m \"Collecte du ",
          format(Sys.Date(), "%d/%m/%Y"), "\" && git push")
  }
  invisible(resultat$ok)
}

#' Etat de la fraicheur des donnees
#'
#' @examples
#' \dontrun{
#' diagnostic_fraicheur()
#' }
#' @export
diagnostic_fraicheur <- function() {
  con <- connexion()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  age <- age_donnees(con)
  if (is.null(age)) {
    cat("Aucune collecte enregistree.\n")
    return(invisible(NULL))
  }

  cat(sprintf("Derniere collecte : %s, il y a %d jours.\n",
              format(age$date, "%d/%m/%Y"), age$jours))
  cat(sprintf("%d indicateurs portent une date de collecte.\n", age$indicateurs))

  if (age$jours > SEUIL_ALERTE) {
    cat("\nLes donnees sont probablement depassees.\n")
  } else if (age$jours > SEUIL_FRAICHEUR) {
    cat("\nUne actualisation est conseillee.\n")
  } else {
    cat("\nDonnees recentes.\n")
  }

  # Le detail par categorie : une categorie peut etre bien plus ancienne que
  # la moyenne sans que le chiffre global le montre.
  d <- DBI::dbGetQuery(con, "
    SELECT c.libelle,
           MAX(i.derniere_collecte) AS derniere,
           SUM(CASE WHEN i.derniere_collecte IS NULL THEN 1 ELSE 0 END) AS jamais
    FROM indicateur i JOIN categorie c ON c.code = i.categorie
    WHERE i.actif = 1
    GROUP BY c.libelle, c.ordre ORDER BY c.ordre")

  cat("\nPar categorie :\n")
  for (i in seq_len(nrow(d))) {
    if (is.na(d$derniere[[i]])) {
      etat <- "jamais collectee"
    } else {
      j <- as.integer(Sys.Date() - as.Date(substr(d$derniere[[i]], 1, 10)))
      etat <- sprintf("il y a %d jours", j)
    }
    manque <- if (d$jamais[[i]] > 0) sprintf(", %d sans donnees", d$jamais[[i]]) else ""
    cat(sprintf("  %-46s %s%s\n", substr(d$libelle[[i]], 1, 46), etat, manque))
  }
  invisible(d)
}

# Ce controle existe parce que la meme erreur s'est produite quatre fois : un
# remplacement de bloc fait disparaitre un tr() sans que rien ne le signale, et
# le texte reste en francais dans l'interface anglaise. Un litteral portant des
# accents est presque toujours destine a l'utilisateur : les requetes SQL, les
# classes de style et les adresses n'en comportent pas.

masquer_commentaires <- function(t) {
  car <- strsplit(t, "", fixed = TRUE)[[1]]
  sortie <- car
  i <- 1L; n <- length(car); quote <- NULL
  while (i <= n) {
    c <- car[[i]]
    if (!is.null(quote)) {
      if (c == "\\" && quote != "`") { i <- i + 2L; next }
      if (c == quote) quote <- NULL
      i <- i + 1L; next
    }
    if (c %in% c('"', "'", "`")) { quote <- c; i <- i + 1L; next }
    if (c == "#") {
      while (i <= n && car[[i]] != "\n") { sortie[[i]] <- " "; i <- i + 1L }
      next
    }
    i <- i + 1L
  }
  paste(sortie, collapse = "")
}

sources_du_paquet <- function() {
  dossier <- system.file("..", package = "opescplus")
  f <- list.files(dossier, pattern = "[.]R$", recursive = TRUE, full.names = TRUE)
  f[grepl("/R/", f, fixed = TRUE)]
}

test_that("aucun texte accentue n'echappe au dictionnaire", {
  fichiers <- sources_du_paquet()
  skip_if(!length(fichiers), "sources non accessibles")

  # Fichiers dont les chaines vont a la console et non a l'ecran, et fichiers
  # de constantes evaluees au chargement, dont les textes passent par tr() au
  # moment du rendu.
  hors <- c("i18n.R", "connecteurs.R", "graphiques.R", "collecte.R", "bd.R",
            "config.R", "mod_accueil.R")
  fichiers <- fichiers[!basename(fichiers) %in% hors]

  d <- dictionnaire()
  restants <- character(0)

  for (f in fichiers) {
    code <- masquer_commentaires(paste(readLines(f, warn = FALSE), collapse = "\n"))
    litteraux <- regmatches(code, gregexpr('"(\\\\.|[^"\\\\])*"', code))[[1]]
    for (brut in litteraux) {
      texte <- substr(brut, 2L, nchar(brut) - 1L)
      if (nchar(texte) < 4L) next
      if (!grepl("\\\\u00[0-9a-fA-F]{2}", texte) &&
          !grepl("[\u00c0-\u00ff]", texte)) next
      if (grepl("^[%|_]|indice[|]index|_START_", texte)) next
      valeur <- tryCatch(eval(parse(text = paste0('"', texte, '"'))),
                         error = function(e) texte)
      if (!valeur %in% names(d)) restants <- c(restants, paste(basename(f), valeur))
    }
  }
  expect_equal(unique(restants), character(0))
})

test_that("chaque module qui utilise ns() le definit", {
  # Oubli qui a fait echouer le formulaire du manuel : ns() etait appele dans
  # un renderUI sans que le module ne l'ait recupere de la session.
  fichiers <- sources_du_paquet()
  skip_if(!length(fichiers), "sources non accessibles")
  modules <- fichiers[grepl("mod_", basename(fichiers), fixed = TRUE)]

  for (f in modules) {
    code <- paste(readLines(f, warn = FALSE), collapse = "\n")
    serveur <- sub("^.*moduleServer", "", code)
    if (!grepl("ns\\\\(", serveur)) next
    expect_true(grepl("ns <- session\\\\$ns", serveur, perl = TRUE),
                info = basename(f))
  }
})

lire_sources <- function() {
  dossier <- system.file("..", package = "opescplus")
  fichiers <- list.files(dossier, pattern = "[.]R$", recursive = TRUE,
                         full.names = TRUE)
  fichiers <- fichiers[grepl("/R/", fichiers, fixed = TRUE)]
  if (!length(fichiers)) return(NULL)
  paste(unlist(lapply(fichiers, readLines, warn = FALSE)), collapse = "\n")
}

#' Chaines passees a tr() dans le code, sous ses deux formes
#'
#' tr("...") pour les libelles courts, tr(paste("...", "...")) pour les textes
#' longs. Ignorer la seconde forme laissait passer tous les paragraphes.
chaines_traduites <- function(code) {
  simples <- regmatches(code, gregexpr('tr[(]"[^"]*"[)]', code))[[1]]
  simples <- gsub('^tr[(]"', "", simples)
  simples <- gsub('"[)]$', "", simples)

  motif <- 'tr[(]paste[(](?:[[:space:]]*"[^"]*"[[:space:]]*,?)+[)][)]'
  composees <- regmatches(code, gregexpr(motif, code))[[1]]
  composees <- vapply(composees, function(x) {
    morceaux <- regmatches(x, gregexpr('"[^"]*"', x))[[1]]
    paste(gsub('^"|"$', "", morceaux), collapse = " ")
  }, character(1), USE.NAMES = FALSE)

  chaines <- c(simples, composees)
  chaines <- chaines[nzchar(chaines)]
  # Les sequences \uXXXX du code source sont interpretees comme R le ferait.
  unique(vapply(chaines, function(x) eval(parse(text = paste0('"', x, '"'))),
                character(1), USE.NAMES = FALSE))
}

test_that("toutes les chaines enveloppees ont leur traduction", {
  # Garantie qu'un changement de langue ne laisse plus de francais a l'ecran.
  code <- lire_sources()
  skip_if(is.null(code), "sources non accessibles")
  absentes <- setdiff(chaines_traduites(code), names(dictionnaire()))
  expect_equal(absentes, character(0))
})

test_that("les deux formes d'appel sont bien reconnues", {
  code <- 'tr("Court") et tr(paste("Un texte", "sur deux lignes"))'
  expect_setequal(chaines_traduites(code),
                  c("Court", "Un texte sur deux lignes"))
})

test_that("les libelles de categories sont traduits", {
  d <- dictionnaire()
  cats <- utils::read.csv(app_sys("extdata/categories.csv"),
                          stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  expect_true(all(cats$libelle %in% names(d)))
})

test_that("les libelles des indicateurs actifs sont traduits", {
  d <- dictionnaire()
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                         stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  actifs <- cat[cat$source %in% names(REGISTRE), ]
  expect_lt(length(setdiff(actifs$libelle, names(d))), 10L)
})

test_that("le dictionnaire n'a ni doublon ni traduction vide", {
  t <- utils::read.csv(app_sys("extdata/traductions.csv"),
                       stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  expect_equal(nrow(t), length(unique(t$fr)))
  expect_true(all(nzchar(trimws(t$en))))
  expect_gt(nrow(t), 400L)
})

test_that("les textes des listes de l'accueil sont traduits", {
  # Ces chaines ne sont pas des litteraux tr("...") : elles viennent des
  # structures FONCTIONS, LIENS et CONFIG. Le controle par expression
  # reguliere ne les voyait pas, et elles restaient en francais dans
  # l'interface anglaise.
  absentes <- setdiff(chaines_accueil(), names(dictionnaire()))
  expect_equal(absentes, character(0))
})

test_that("les noms des partenaires commerciaux sont affichables", {
  # Les noms de pays ne sont pas traduits : ils servent tels quels.
  expect_equal(nrow(PARTENAIRES), 10L)
  expect_true(all(nzchar(PARTENAIRES$nom)))
})

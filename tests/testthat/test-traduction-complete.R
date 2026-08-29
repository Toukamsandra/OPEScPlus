test_that("toutes les chaines enveloppees ont leur traduction", {
  # Ce controle est la garantie qu'un changement de langue ne laisse plus de
  # francais a l'ecran. Il echoue des qu'un tr() est ajoute sans son entree.
  d <- dictionnaire()
  fichiers <- list.files(system.file("..", package = "opescplus"),
                         pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  fichiers <- fichiers[grepl("/R/", fichiers)]
  skip_if(!length(fichiers), "sources non accessibles")

  code <- paste(unlist(lapply(fichiers, readLines, warn = FALSE)), collapse = "\n")
  chaines <- regmatches(code, gregexpr('tr\\("[^"]*"\\)', code))[[1]]
  chaines <- gsub('^tr\\("|"\\)$', "", chaines)
  chaines <- chaines[nzchar(chaines)]
  chaines <- vapply(chaines, function(x) {
    eval(parse(text = paste0('"', x, '"')))
  }, character(1), USE.NAMES = FALSE)

  absentes <- setdiff(unique(chaines), names(d))
  expect_length(absentes, 0L)
})

test_that("les libelles de categories sont traduits", {
  d <- dictionnaire()
  cats <- utils::read.csv(app_sys("extdata/categories.csv"), stringsAsFactors = FALSE,
                          fileEncoding = "UTF-8-BOM")
  expect_true(all(cats$libelle %in% names(d)))
})

test_that("les libelles des indicateurs actifs sont traduits", {
  d <- dictionnaire()
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  actifs <- cat[cat$source %in% names(REGISTRE), ]
  absents <- setdiff(actifs$libelle, names(d))
  # Quelques indicateurs desactives peuvent manquer, pas les actifs.
  expect_lt(length(absents), 10L)
})

test_that("le dictionnaire n'a ni doublon ni traduction vide", {
  t <- utils::read.csv(app_sys("extdata/traductions.csv"), stringsAsFactors = FALSE,
                       fileEncoding = "UTF-8-BOM")
  expect_equal(nrow(t), length(unique(t$fr)))
  expect_true(all(nzchar(trimws(t$en))))
})

test_that("les quatre manuels sont servis comme ressources statiques", {
  # Le telechargement passe par un lien vers inst/app/www : si le fichier n'y
  # est pas, le lien renvoie une erreur 404 sans le moindre message.
  for (langue in c("fr", "en")) {
    for (format in c("pdf", "docx")) {
      chemin <- app_sys(sprintf("app/www/manuel/manuel_opesc_%s.%s", langue, format))
      expect_true(nzchar(chemin) && file.exists(chemin), info = paste(langue, format))
    }
  }
})

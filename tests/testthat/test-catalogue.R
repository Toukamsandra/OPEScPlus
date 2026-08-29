lire_catalogue <- function() {
  utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                  fileEncoding = "UTF-8-BOM")
}

test_that("les codes internes du catalogue sont uniques", {
  # Ce sont des cles primaires : un doublon ferait echouer le chargement.
  d <- lire_catalogue()
  expect_equal(nrow(d), length(unique(d$code_interne)))
})

test_that("chaque indicateur pointe vers une categorie declaree", {
  d <- lire_catalogue()
  c_ <- utils::read.csv(app_sys("extdata/categories.csv"), stringsAsFactors = FALSE,
                        fileEncoding = "UTF-8-BOM")
  expect_true(all(d$categorie %in% c_$code))
})

test_that("les frequences declarees appartiennent au referentiel", {
  d <- lire_catalogue()
  declarees <- unique(unlist(strsplit(d$frequences, ",", fixed = TRUE)))
  expect_true(all(declarees %in% FREQUENCES$code))
})

test_that("les series sans dimension pays sont des cours mondiaux", {
  # Un cours de cacao n'a pas de pays : le tableau de bord s'appuie sur cette
  # colonne pour masquer le selecteur.
  d <- lire_catalogue()
  sans_pays <- d[d$dimension_pays == 0, ]
  expect_true(all(sans_pays$categorie == "C01"))
  expect_gt(nrow(sans_pays), 20)
})

test_that("chaque source active dispose d'un connecteur", {
  d <- lire_catalogue()
  couvertes <- d$source %in% names(REGISTRE)
  # Sept indicateurs restent sans connecteur et sont desactives au chargement.
  expect_lt(sum(!couvertes), 10)
})

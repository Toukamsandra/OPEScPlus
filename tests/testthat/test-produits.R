test_that("chaque cours du catalogue a une correspondance Pink Sheet", {
  # Sans correspondance, le connecteur echoue a la collecte. C'est le controle
  # qui evite de relivrer un catalogue dont un quart des lignes ne passera pas.
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  cours <- cat$code_source[cat$categorie == "C01"]
  expect_gt(length(cours), 20)
  expect_true(all(cours %in% names(CODES_PINK_SHEET)),
              info = paste(setdiff(cours, names(CODES_PINK_SHEET)), collapse = ", "))
})

test_that("les cours sont declares sans dimension pays", {
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  expect_true(all(cat$dimension_pays[cat$categorie == "C01"] == 0))
})

test_that("la source des cours est bien branchee au registre", {
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  sources <- unique(cat$source[cat$categorie == "C01"])
  expect_length(sources, 1L)
  expect_true(sources %in% names(REGISTRE))
})

test_that("l'agregation annuelle ne porte que sur le mensuel", {
  r <- data.frame(
    iso3 = "WLD",
    date_periode = c(as.Date(sprintf("2020-%02d-01", 1:12)), as.Date("2019-01-01")),
    frequence = c(rep("M", 12), "A"),
    valeur = c(rep(c(10, 20), each = 6), 999),
    stringsAsFactors = FALSE)
  a <- agreger_en_annuel(r)
  expect_equal(nrow(a), 1L)
  expect_equal(a$valeur, 15)
  # La valeur annuelle deja presente ne doit pas etre reprise dans la moyenne.
  expect_false(999 %in% a$valeur)
})

test_that("la correspondance des codes est injective", {
  expect_equal(length(CODES_PINK_SHEET), length(unique(CODES_PINK_SHEET)))
})

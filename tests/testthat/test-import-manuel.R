fichier_essai <- function() {
  # Reproduction fidele du format telecharge : colonnes d'identification, puis
  # une colonne par periode, annuelle, trimestrielle et mensuelle melangees.
  d <- data.frame(
    DATASET = rep("IMF.RES:PCPS(9.0.0)", 3),
    SERIES_CODE = c("G001.PCOCO.USD.M", "G001.PCOCO.INDEX.M",
                    "G001.PCOCO.PCH.M"),
    COUNTRY = "World",
    INDICATOR = "Cocoa, US dollars per metric tonne",
    DATA_TRANSFORMATION = c("US dollars", "Index", "Index, percent change"),
    FREQUENCY = "Monthly",
    `2020` = c(2500, 100, 1.5),
    `2020-Q1` = c(2400, 96, 1.2),
    `2020-M01` = c(2380, 95, 1.1),
    `2020-M02` = c(2420, 97, 1.3),
    check.names = FALSE, stringsAsFactors = FALSE)
  chemin <- tempfile(fileext = ".csv")
  utils::write.csv(d, chemin, row.names = FALSE)
  chemin
}

test_that("le code du produit est extrait de SERIES_CODE", {
  # La colonne INDICATOR ne porte qu'un libelle : le code utile est le
  # deuxieme element de SERIES_CODE.
  d <- data.frame(SERIES_CODE = c("G001.PCOCO.INDEX.Q", "G001.POILBRE.USD.M"),
                  stringsAsFactors = FALSE)
  expect_equal(extraire_code_produit(d), c("PCOCO", "POILBRE"))
})

test_that("la transformation retenue est le niveau en dollars", {
  # Retenir une variation donnerait des pourcentages la ou l'on attend un cours.
  d <- data.frame(
    DATA_TRANSFORMATION = c("Index, percent change", "US dollars", "Index"),
    valeur = 1:3, stringsAsFactors = FALSE)
  r <- retenir_transformation(d)
  expect_equal(nrow(r), 1L)
  expect_equal(attr(r, "unite"), "US dollars")

  # Un indice sans niveau en dollars reste retenu.
  d2 <- data.frame(DATA_TRANSFORMATION = c("Index", "Index, percent change"),
                   valeur = 1:2, stringsAsFactors = FALSE)
  expect_equal(attr(retenir_transformation(d2), "unite"), "Index")
})

test_that("le depliage lit la frequence dans le nom de la colonne", {
  d <- data.frame(`2020` = 2500, `2020-Q1` = 2400, `2020-M01` = 2380,
                  check.names = FALSE)
  r <- deplier(d, c("2020", "2020-Q1", "2020-M01"))
  expect_equal(nrow(r), 3L)
  expect_setequal(r$frequence, c("A", "T", "M"))
  expect_equal(r$valeur[r$frequence == "M"], 2380)
})

test_that("l'apercu n'ecrit rien et decrit le fichier", {
  chemin <- fichier_essai()
  on.exit(unlink(chemin))
  sortie <- utils::capture.output(n <- importer_produits_local(chemin, apercu = TRUE))
  expect_equal(n, 0L)
  expect_true(any(grepl("colonnes de periode", sortie)))
})

test_that("les cinq indices du catalogue portent le code du fichier PCPS", {
  # Le suffixe W venait de la nomenclature du flux WEO et n'existe pas ici.
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"), stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8-BOM")
  codes <- cat$code_source[cat$categorie == "C01"]
  expect_true(all(c("PALLFNF", "PNRG", "PFANDB", "PMETA", "PRAWM") %in% codes))
  expect_false(any(grepl("W$", codes[grepl("^P(ALLFNF|NRG|FANDB|META|RAWM)", codes)])))
})

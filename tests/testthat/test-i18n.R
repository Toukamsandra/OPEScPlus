test_that("le dictionnaire est bien forme", {
  d <- dictionnaire()
  expect_gt(length(d), 60)
  expect_equal(length(d), length(unique(names(d))))
  expect_false(any(is.na(d)))
})

test_that("en francais, tr rend la chaine inchangee", {
  .i18n$langue <- "fr"
  expect_equal(tr("Tableau de bord"), "Tableau de bord")
  expect_equal(tr("Cha\u00eene absente du dictionnaire"),
               "Cha\u00eene absente du dictionnaire")
})

test_that("en anglais, tr traduit ce qu'il connait", {
  .i18n$langue <- "en"
  expect_equal(tr("Tableau de bord"), "Dashboard")
  expect_equal(tr("Pays"), "Countries")
  # Une chaine absente revient telle quelle : mieux vaut un mot en francais
  # dans une interface anglaise qu'une case vide.
  expect_equal(tr("Cha\u00eene absente"), "Cha\u00eene absente")
  .i18n$langue <- "fr"
})

test_that("tr accepte un vecteur", {
  .i18n$langue <- "en"
  expect_equal(tr(c("Accueil", "Collectes")), c("Home", "Data collection"))
  .i18n$langue <- "fr"
})

test_that("la langue est lue dans l'adresse", {
  expect_equal(langue_courante(list(QUERY_STRING = "?lang=en")), "en")
  expect_equal(langue_courante(list(QUERY_STRING = "?lang=fr")), "fr")
  # Une langue inconnue ne change rien plutot que de casser l'interface.
  .i18n$langue <- "fr"
  expect_equal(langue_courante(list(QUERY_STRING = "?lang=zz")), "fr")
})

test_that("les libelles de frequence suivent la langue", {
  .i18n$langue <- "en"
  expect_equal(libelle_frequence("A"), "Annual")
  expect_equal(libelle_frequence("M"), "Monthly")
  .i18n$langue <- "fr"
  expect_equal(libelle_frequence("A"), "Annuelle")
})

test_that("l'agregation annuelle d'un cours est une moyenne", {
  # Un prix est une moyenne de periode, jamais une somme.
  r <- data.frame(
    iso3 = "WLD",
    date_periode = as.Date(sprintf("2020-%02d-01", 1:12)),
    frequence = "M", valeur = c(rep(10, 6), rep(20, 6)),
    stringsAsFactors = FALSE)
  a <- agreger_en_annuel(r)
  expect_equal(nrow(a), 1L)
  expect_equal(a$valeur, 15)
  expect_equal(a$frequence, "A")
})

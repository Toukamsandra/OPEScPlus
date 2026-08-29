serie <- function(nom, valeurs, unite = "USD courants", debut = 2020) {
  data.frame(
    serie = nom, unite = unite,
    date_periode = seq(as.Date(sprintf("%d-01-01", debut)), by = "year",
                       length.out = length(valeurs)),
    valeur = valeurs, stringsAsFactors = FALSE)
}

test_that("le camembert ne retient que la derniere periode", {
  # Un camembert est une repartition a un instant, pas une evolution : le
  # cumuler sur plusieurs annees n'aurait aucun sens.
  d <- rbind(serie("A", c(10, 30)), serie("B", c(90, 70)))
  parts <- parts_camembert(d)
  expect_equal(nrow(parts), 2L)
  expect_equal(as.integer(format(attr(parts, "periode"), "%Y")), 2021L)
  expect_equal(sort(parts$valeur), c(30, 70))
  expect_equal(sum(parts$part), 100)
})

test_that("les valeurs nulles ou negatives sont ecartees", {
  # Une part negative dessinerait un secteur inverse, sans signification.
  d <- rbind(serie("A", 50), serie("B", -20), serie("C", 0))
  parts <- parts_camembert(d)
  expect_equal(parts$serie, "A")
})

test_that("un camembert vide rend NULL plutot qu'une erreur", {
  expect_null(parts_camembert(NULL))
  expect_null(parts_camembert(serie("A", numeric(0))[0, ]))
  expect_null(tracer_camembert(serie("A", -5)))
})

test_that("la pertinence du camembert depend de l'unite", {
  # Additionner des parts de PIB de plusieurs pays ne donne aucun total
  # interpretable : l'interface doit le signaler.
  expect_true(camembert_pertinent(rbind(serie("A", 10), serie("B", 20))))
  expect_false(camembert_pertinent(rbind(serie("A", 10, "% du PIB"),
                                         serie("B", 20, "% du PIB"))))
  expect_false(camembert_pertinent(rbind(serie("A", 10, "Indice"),
                                         serie("B", 20, "Indice"))))
  # Unites melangees : le total n'a pas de sens non plus.
  expect_false(camembert_pertinent(rbind(serie("A", 10, "USD"),
                                         serie("B", 20, "tonnes"))))
})

test_that("tr ne tombe jamais sur une cle absente", {
  # C'est le defaut qui bloquait toute l'interface anglaise.
  .i18n$langue <- "en"
  expect_silent(r <- tr(c("Tableau de bord", "Cha\u00eene totalement inconnue")))
  expect_equal(r[[2]], "Cha\u00eene totalement inconnue")
  expect_equal(tr(character(0)), character(0))
  .i18n$langue <- "fr"
})

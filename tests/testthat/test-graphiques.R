serie_test <- function(nom, valeurs, unite = "%") {
  data.frame(
    serie = nom, unite = unite,
    date_periode = seq(as.Date("2020-01-01"), by = "year", length.out = length(valeurs)),
    valeur = valeurs, stringsAsFactors = FALSE)
}

test_that("la mise en base 100 part de la premiere observation", {
  d <- serie_test("A", c(50, 75, 100))
  r <- en_base_100(d)
  expect_equal(r$valeur, c(100, 150, 200))
})

test_that("une serie dont la premiere valeur est nulle est ecartee", {
  # Diviser par zero produirait des infinis qui feraient disparaitre les autres
  # courbes du graphique.
  d <- rbind(serie_test("A", c(0, 10)), serie_test("B", c(5, 10)))
  r <- en_base_100(d)
  expect_equal(unique(r$serie), "B")
})

test_that("les unites distinctes sont detectees", {
  d <- rbind(serie_test("A", 1:3, "%"), serie_test("B", 1:3, "USD"))
  expect_length(unites_distinctes(d), 2L)
  expect_length(unites_distinctes(serie_test("A", 1:3)), 1L)
})

test_that("tracer renvoie NULL sur un tableau vide plutot que d'echouer", {
  expect_null(tracer(NULL))
  expect_null(tracer(serie_test("A", numeric(0))[0, ]))
})

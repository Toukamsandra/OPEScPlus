test_that("les periodes sont ramenees au premier jour de la periode couverte", {
  # Cette convention est ce qui permet de superposer sur un meme graphique des
  # series de pas differents : si elle casse, tout l'axe temporel casse.
  expect_equal(periode_vers_date("2023"),      list(as.Date("2023-01-01"), "A"))
  expect_equal(periode_vers_date("2023-Q2"),   list(as.Date("2023-04-01"), "T"))
  expect_equal(periode_vers_date("2023Q4"),    list(as.Date("2023-10-01"), "T"))
  expect_equal(periode_vers_date("2023-S2"),   list(as.Date("2023-07-01"), "S"))
  expect_equal(periode_vers_date("2023-07"),   list(as.Date("2023-07-01"), "M"))
  expect_equal(periode_vers_date("2023M7"),    list(as.Date("2023-07-01"), "M"))
  expect_equal(periode_vers_date("2023-07-14"), list(as.Date("2023-07-14"), "J"))
})

test_that("une periode illisible ne fait pas echouer la collecte", {
  # Les connecteurs filtrent ensuite sur les NA : une ligne aberrante doit etre
  # ignoree, pas interrompre les milliers d'autres.
  r <- periode_vers_date("n/a")
  expect_true(is.na(r[[1]]))
})

test_that("la conversion en lot renvoie une ligne par periode", {
  d <- periodes_vers_dates(c("2020", "2021-Q1", "2022-03"))
  expect_equal(nrow(d), 3L)
  expect_equal(d$frequence, c("A", "T", "M"))
})

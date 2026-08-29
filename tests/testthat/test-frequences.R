test_that("les frequences sont proposees du pas le plus large au plus fin", {
  # L'annuel arrive en tete parce que c'est le pas qui se lit le mieux sur un
  # graphique de long terme, et de loin le plus courant dans le catalogue.
  choix <- choix_frequences(c("M", "A", "T"))
  expect_equal(unname(choix), c("A", "T", "M"))
  expect_equal(names(choix), c("Annuelle", "Trimestrielle", "Mensuelle"))
})

test_that("un code de frequence inconnu est ecarte", {
  expect_equal(unname(choix_frequences(c("A", "Z"))), "A")
  expect_length(choix_frequences(character(0)), 0L)
})

test_that("le referentiel des frequences est coherent", {
  expect_equal(nrow(FREQUENCES), length(unique(FREQUENCES$code)))
  expect_equal(FREQUENCES$rang, seq_len(nrow(FREQUENCES)))
})

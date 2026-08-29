base_carte <- function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  creer_schema(con)
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C02', 'Reel', 2)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source,
                            frequences, unite, dimension_pays)
    VALUES ('X', 'C02', 'PIB', 'BM', 'NY', 'A', '%', 1)")
  for (p in c("CMR", "GAB", "FRA", "CHN", "NLD", "IND")) {
    DBI::dbExecute(con, "INSERT INTO pays VALUES (?, ?, 'Region', 'Revenu', 0)",
                   params = list(p, p))
  }
  DBI::dbExecute(con, "INSERT INTO pays VALUES ('WLD', 'Monde', '', '', 1)")
  for (a in 2020:2022) {
    for (i in seq_along(c("CMR", "GAB", "FRA", "CHN", "NLD", "IND"))) {
      p <- c("CMR", "GAB", "FRA", "CHN", "NLD", "IND")[i]
      DBI::dbExecute(con,
        "INSERT INTO observation VALUES ('X', ?, 'A', ?, ?, ?)",
        params = list(p, sprintf("%d-01-01", a), a, i + a / 1000))
    }
  }
  # Une valeur pour un agregat, qui ne doit jamais apparaitre sur la carte.
  DBI::dbExecute(con,
    "INSERT INTO observation VALUES ('X', 'WLD', 'A', '2022-01-01', 2022, 999)")
  con
}

test_that("la carte exclut les agregats", {
  # Colorer le monde au milieu des pays ecraserait l'echelle et fausserait la
  # lecture : c'est la garantie la plus importante de ce module.
  con <- base_carte(); on.exit(DBI::dbDisconnect(con))
  d <- donnees_carte(con, "X", "A", 2022)
  expect_false("WLD" %in% d$iso3)
  expect_equal(nrow(d), 6L)
})

test_that("les annees proposees sont celles qui ont assez de pays", {
  con <- base_carte(); on.exit(DBI::dbDisconnect(con))
  expect_equal(annees_carte(con, "X", "A", seuil = 5L), 2020:2022)
  expect_length(annees_carte(con, "X", "A", seuil = 50L), 0L)
})

test_that("les valeurs sont triees par ordre decroissant", {
  con <- base_carte(); on.exit(DBI::dbDisconnect(con))
  d <- donnees_carte(con, "X", "A", 2021)
  expect_equal(d$valeur, sort(d$valeur, decreasing = TRUE))
})

test_that("tracer_carte renvoie NULL sur un tableau vide", {
  expect_null(tracer_carte(NULL))
  expect_null(tracer_carte(data.frame()))
})

test_that("la liste des partenaires est coherente", {
  expect_equal(nrow(PARTENAIRES), 10L)
  expect_true(all(nchar(PARTENAIRES$iso2) == 2))
  expect_true(all(nchar(PARTENAIRES$iso3) == 3))
  expect_equal(length(unique(PARTENAIRES$iso3)), 10L)
})

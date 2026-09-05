base_compteurs <- function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  creer_schema(con)
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C01', 'Mati\u00e8res', 1)")
  DBI::dbExecute(con, "INSERT INTO pays VALUES ('WLD', 'Monde', '', '', 1)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source,
                            frequences, dimension_pays, nb_observations)
    VALUES ('C01.PCOCO', 'C01', 'Cacao', 'FMI', 'PCOCO', 'M,A', 0, 0)")
  con
}

test_that("le compteur suit les observations reellement presentes", {
  # C'est le defaut signale : des cours importes restaient affiches comme non
  # collectes parce que le compteur etait recopie et non recalcule.
  con <- base_compteurs(); on.exit(DBI::dbDisconnect(con))
  for (m in 1:6) {
    DBI::dbExecute(con,
      "INSERT INTO observation VALUES ('C01.PCOCO', 'WLD', 'M', ?, 2020, 2500)",
      params = list(sprintf("2020-%02d-01", m)))
  }
  expect_equal(DBI::dbGetQuery(con,
    "SELECT nb_observations AS n FROM indicateur")$n, 0)

  rafraichir_compteurs(con)
  expect_equal(DBI::dbGetQuery(con,
    "SELECT nb_observations AS n FROM indicateur")$n, 6)
})

test_that("une date de collecte est posee sur les donnees importees", {
  # Sans elle, l'interface continuerait de presenter l'indicateur comme jamais
  # alimente, alors que ses observations sont en base.
  con <- base_compteurs(); on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con,
    "INSERT INTO observation VALUES ('C01.PCOCO', 'WLD', 'A', '2020-01-01', 2020, 2500)")
  rafraichir_compteurs(con)
  d <- DBI::dbGetQuery(con, "SELECT derniere_collecte FROM indicateur")
  expect_false(is.na(d$derniere_collecte[[1]]))
})

test_that("un indicateur sans observation reste a zero", {
  con <- base_compteurs(); on.exit(DBI::dbDisconnect(con))
  rafraichir_compteurs(con)
  d <- DBI::dbGetQuery(con, "SELECT nb_observations, derniere_collecte FROM indicateur")
  expect_equal(d$nb_observations[[1]], 0)
  expect_true(is.na(d$derniere_collecte[[1]]))
})

test_that("le compteur se corrige apres suppression d'observations", {
  con <- base_compteurs(); on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con,
    "INSERT INTO observation VALUES ('C01.PCOCO', 'WLD', 'A', '2020-01-01', 2020, 1)")
  rafraichir_compteurs(con)
  DBI::dbExecute(con, "DELETE FROM observation")
  rafraichir_compteurs(con)
  expect_equal(DBI::dbGetQuery(con,
    "SELECT nb_observations AS n FROM indicateur")$n, 0)
})

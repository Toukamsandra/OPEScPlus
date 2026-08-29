base_temporaire <- function() {
  chemin <- tempfile(fileext = ".sqlite")
  con <- DBI::dbConnect(RSQLite::SQLite(), chemin)
  creer_schema(con)
  con
}

test_that("le schema cree toutes les tables attendues", {
  con <- base_temporaire()
  on.exit(DBI::dbDisconnect(con))
  expect_true(all(c("categorie", "pays", "indicateur", "observation",
                    "journal_collecte") %in% DBI::dbListTables(con)))
})

test_that("une observation ne peut pas etre enregistree deux fois", {
  # La cle porte sur indicateur, pays, frequence et periode. Sans elle, une
  # collecte relancee dupliquerait toute la base.
  con <- base_temporaire()
  on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C01', 'Test', 1)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source, frequences)
    VALUES ('X', 'C01', 'Test', 'S', 'CS', 'A')")
  ligne <- "INSERT INTO observation VALUES ('X', 'CMR', 'A', '2020-01-01', 2020, 1.0)"
  DBI::dbExecute(con, ligne)
  expect_error(DBI::dbExecute(con, ligne))
})

test_that("une meme serie peut coexister en mensuel et en annuel", {
  con <- base_temporaire()
  on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C01', 'Test', 1)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source, frequences)
    VALUES ('X', 'C01', 'Test', 'S', 'CS', 'A,M')")
  DBI::dbExecute(con, "INSERT INTO observation VALUES ('X','CMR','A','2020-01-01',2020,1)")
  DBI::dbExecute(con, "INSERT INTO observation VALUES ('X','CMR','M','2020-01-01',2020,2)")
  expect_equal(sort(frequences_disponibles(con, "X")), c("A", "M"))
})

test_that("les frequences declarees servent de repli sur une base vide", {
  # Avant toute collecte, la base ne peut rien dire : on retombe alors sur ce
  # que le catalogue annonce, pour que le filtre ne soit pas vide.
  con <- base_temporaire()
  on.exit(DBI::dbDisconnect(con))
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C01', 'Test', 1)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source, frequences)
    VALUES ('X', 'C01', 'Test', 'S', 'CS', 'A,T')")
  expect_setequal(frequences_disponibles(con, "X"), c("A", "T"))
})

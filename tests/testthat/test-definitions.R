test_that("la table des definitions est creee avec le schema", {
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))
  creer_schema(con)
  expect_true("definition" %in% DBI::dbListTables(con))
})

test_that("une definition absente rend NULL plutot qu'une erreur", {
  # L'interface interroge la table pour chaque resultat affiche : une absence
  # ne doit pas interrompre le rendu de la page.
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))
  creer_schema(con)
  expect_null(lire_definition(con, "C02.INEXISTANT"))
})

test_that("une definition est relue avec sa source", {
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))
  creer_schema(con)
  DBI::dbExecute(con, "
    INSERT INTO definition VALUES ('C02.PIB', 'Somme des valeurs ajout\u00e9es.',
                                   'Banque mondiale', '2026-09-05')")
  d <- lire_definition(con, "C02.PIB")
  expect_equal(d$source, "Banque mondiale")
  expect_match(d$texte, "valeurs ajout")
})

test_that("une definition est remplacee et non dupliquee", {
  # Le code interne est cle primaire : relancer la collecte doit mettre a jour
  # la definition, non en empiler une seconde.
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))
  creer_schema(con)
  for (texte in c("Premiere version", "Seconde version")) {
    DBI::dbExecute(con, "
      INSERT INTO definition (code_interne, texte, source, recuperee)
      VALUES ('C02.PIB', ?, 'Banque mondiale', '2026-09-05')
      ON CONFLICT (code_interne) DO UPDATE
      SET texte = excluded.texte", params = list(texte))
  }
  n <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM definition")$n
  expect_equal(n, 1L)
  expect_equal(lire_definition(con, "C02.PIB")$texte, "Seconde version")
})

test_that("le schema s'applique aussi a une base ou observation est une vue", {
  # C'est le cas d'une base publiee : les observations y sont rangees sous
  # forme compacte et exposees par une vue. SQLite refuse d'indexer une vue,
  # et le schema doit rester applicable sans echouer.
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))

  DBI::dbExecute(con, "CREATE TABLE obs_compacte (
    id_indicateur INTEGER, id_pays INTEGER, frequence TEXT,
    date_periode TEXT, annee INTEGER, valeur REAL)")
  DBI::dbExecute(con, "CREATE VIEW observation AS
    SELECT 'X' AS code_interne, 'WLD' AS iso3, frequence, date_periode,
           annee, valeur FROM obs_compacte")

  expect_no_error(creer_schema(con))
  expect_true("definition" %in% DBI::dbListTables(con))
})

test_that("la categorie des cours importes existe et est peuplee", {
  cats <- utils::read.csv(app_sys("extdata/categories.csv"),
                          stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  expect_true("C15" %in% cats$code)

  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                         stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  c15 <- cat[cat$categorie == "C15", ]
  expect_gt(nrow(c15), 100)
  expect_true(all(c15$dimension_pays == 0))
  expect_equal(nrow(c15), length(unique(c15$code_source)))
})

test_that("les taux de change ne sont pas ranges dans les matieres premieres", {
  # Le fichier telecharge les livre avec les cours, mais un taux de change
  # n'est pas un produit : le confondre fausserait la lecture de la categorie.
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                         stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  c15 <- cat[cat$categorie == "C15", ]
  expect_false(any(grepl("^T[0-9]", c15$code_source)))
})

test_that("un indicateur porteur d'observations reste actif sans connecteur", {
  # C'est la regle qui rend visible une base importee : ses series n'ont aucun
  # connecteur, et la seule appartenance au registre les aurait masquees.
  con <- DBI::dbConnect(RSQLite::SQLite(), tempfile(fileext = ".sqlite"))
  on.exit(DBI::dbDisconnect(con))
  creer_schema(con)
  DBI::dbExecute(con, "INSERT INTO categorie VALUES ('C15', 'Import', 15)")
  DBI::dbExecute(con, "INSERT INTO pays VALUES ('WLD', 'Monde', '', '', 1)")
  DBI::dbExecute(con, "
    INSERT INTO indicateur (code_interne, categorie, libelle, source, code_source,
                            frequences, dimension_pays, actif)
    VALUES ('C15.PCOCO', 'C15', 'Cacao', 'Import local', 'PCOCO', 'M', 0, 1)")
  DBI::dbExecute(con,
    "INSERT INTO observation VALUES ('C15.PCOCO','WLD','M','2020-01-01',2020,2500)")

  presents <- DBI::dbGetQuery(con,
    "SELECT DISTINCT code_interne FROM observation")$code_interne
  expect_true("C15.PCOCO" %in% presents)
  expect_false("Import local" %in% names(REGISTRE))
})

test_that("les libelles de la categorie importee sont traduits", {
  d <- dictionnaire()
  cat <- utils::read.csv(app_sys("extdata/catalogue.csv"),
                         stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  c15 <- cat[cat$categorie == "C15", ]
  # Les libelles deja en anglais dans la source n'ont pas d'entree : ils sont
  # identiques dans les deux langues.
  francais <- c15$libelle[grepl("[\u00e0-\u00ff]|^Indice|^Huile|^Bois", c15$libelle)]
  expect_lt(length(setdiff(francais, names(d))), 5L)
})

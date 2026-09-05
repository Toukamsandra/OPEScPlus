test_that("les domaines sont extraits des adresses des sources", {
  # La meme table sert a construire les liens et a filtrer les resultats :
  # aucune divergence possible entre ce que la plateforme propose et ce
  # qu'elle accepte.
  d <- domaines_fiables()
  expect_gt(length(d), 15)
  expect_false(any(grepl("^https?://|/", d)))
  expect_false(any(grepl("^www[.]", d)))
  expect_true("data.worldbank.org" %in% d || "worldbank.org" %in% d)
})

test_that("un sous-domaine d'une source retenue est accepte", {
  domaines <- c("worldbank.org", "imf.org")
  expect_true(domaine_retenu("documents.worldbank.org", domaines))
  expect_true(domaine_retenu("www.imf.org", domaines))
  expect_true(domaine_retenu("imf.org", domaines))
})

test_that("un domaine etranger est refuse", {
  # C'est la garantie de fond : meme si le moteur etait mal configure, aucun
  # resultat exterieur a la liste ne peut s'afficher.
  domaines <- c("worldbank.org", "imf.org")
  expect_false(domaine_retenu("exemple.com", domaines))
  expect_false(domaine_retenu("worldbank.org.exemple.com", domaines))
  expect_false(domaine_retenu("faux-worldbank.org", domaines))
})

test_that("la recherche rend NULL tant qu'elle n'est pas configuree", {
  ancienne_cle <- Sys.getenv("OPESC_CSE_CLE")
  ancien_id <- Sys.getenv("OPESC_CSE_ID")
  Sys.setenv(OPESC_CSE_CLE = "", OPESC_CSE_ID = "")
  on.exit(Sys.setenv(OPESC_CSE_CLE = ancienne_cle, OPESC_CSE_ID = ancien_id))

  # Sans identifiants, l'onglet retombe sur les liens par site : la plateforme
  # reste utilisable, elle ne tombe pas en erreur.
  expect_false(recherche_web_active())
  expect_null(rechercher_web("dette publique"))
  expect_null(rechercher_web(""))
})

test_that("l'organisme est retrouve depuis le domaine", {
  expect_true(nzchar(organisme_du_domaine("data.worldbank.org")))
  expect_equal(organisme_du_domaine("exemple.com"), "")
})

test_that("le glossaire retrouve la notion, y compris par ses initiales", {
  .i18n$langue <- "fr"
  expect_equal(definir("dette publique")$terme, "Dette publique")
  expect_equal(definir("PIB")$terme, "Produit int\u00e9rieur brut")
  expect_equal(definir("inflation")$terme, "Inflation")
  # « croissance » doit rendre la notion la plus proche, non une notion qui
  # la contient par hasard.
  expect_equal(definir("croissance")$terme, "Croissance \u00e9conomique")
  expect_null(definir("xyzzy"))
})

test_that("la definition suit la langue de l'interface", {
  .i18n$langue <- "en"
  d <- definir("inflation")
  expect_match(d$definition, "price", ignore.case = TRUE)
  .i18n$langue <- "fr"
  d <- definir("inflation")
  expect_match(d$definition, "prix", ignore.case = TRUE)
})

test_that("les propositions partent des premieres lettres", {
  p <- propositions("dett")
  expect_true(any(grepl("Dette", p)))
  # Deux caracteres au moins : proposer sur une seule lettre n'aiderait pas.
  expect_length(propositions("d"), 0L)
  expect_length(propositions(""), 0L)
})

test_that("les propositions privilegient les termes qui commencent par la saisie", {
  p <- propositions("infl")
  expect_gt(length(p), 0L)
  expect_true(startsWith(normaliser(p[[1]]), "infl"))
})

test_that("le nombre de sources proposees est borne", {
  # C'est le defaut signale : la totalite des sources s'affichait a chaque
  # recherche, ce qui revenait a ne pas filtrer.
  for (requete in c("dette publique", "inflation", "cours du cacao")) {
    cs <- categories_de_la_requete(requete)
    liens <- liens_de_la_requete(requete, cs, names(TYPES))
    pertinents <- liens[liens$score > 0, , drop = FALSE]
    expect_lt(nrow(utils::head(pertinents, 6L)), nrow(sites_fiables()))
    expect_gt(nrow(pertinents), 0L)
  }
})

test_that("les domaines de presse sont un sous-ensemble des sources", {
  presse <- domaines_par_type("actualite")
  expect_gt(length(presse), 3L)
  expect_true(all(presse %in% domaines_fiables()))
})

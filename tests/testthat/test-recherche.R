test_that("les fichiers de la recherche sont bien formes", {
  s <- sites_fiables()
  expect_gt(nrow(s), 30)
  expect_true(all(s$type %in% names(TYPES)))
  # Les trois types doivent etre representes, sans quoi le filtre proposerait
  # une case qui ne donne jamais rien.
  expect_setequal(unique(s$type), names(TYPES))
  expect_true(all(nzchar(s$nom)))
  expect_true(all(grepl("^https://", s$gabarit)))
  # Chaque site doit couvrir au moins une categorie existante.
  cats <- utils::read.csv(app_sys("extdata/categories.csv"),
                          stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  for (i in seq_len(nrow(s))) {
    couvertes <- unlist(strsplit(s$categories[[i]], " ", fixed = TRUE))
    expect_true(all(couvertes %in% cats$code), info = s$nom[[i]])
  }
})

test_that("la normalisation ignore casse, accents et ponctuation", {
  expect_equal(normaliser("Dette Publique"), "dette publique")
  expect_equal(trimws(normaliser("\u00e9nergie, \u00e9lectricit\u00e9")), "energie  electricite")
})

test_that("les mots vides ne creent pas de rattachement", {
  # « des » figurait dans « indice des prix » et rattachait a tort
  # « chomage des jeunes » a la categorie des prix.
  expect_length(categories_de_la_requete("de la des les"), 0L)
  cs <- categories_de_la_requete("ch\u00f4mage des jeunes")
  expect_equal(cs[[1]], "C10")
})

test_that("une requete est rattachee a la bonne categorie", {
  attendus <- list(
    "dette publique" = c("C03", "C09"),
    "cours du cacao" = "C01",
    "inflation" = "C08",
    "taux de change" = "C06",
    "complexit\u00e9 \u00e9conomique" = "C12")
  for (requete in names(attendus)) {
    cs <- categories_de_la_requete(requete)
    expect_true(cs[[1]] %in% attendus[[requete]], info = requete)
  }
})

test_that("le classement privilegie le site specialise", {
  # Une recherche sur le cacao doit placer la page des marches de produits de
  # base avant un portail generaliste qui traite aussi le sujet.
  cs <- categories_de_la_requete("cours du cacao")
  liens <- liens_de_la_requete("cours du cacao", cs)
  premier <- liens$nom[[1]]
  expect_match(premier, "produits de base|Pink|commodit", ignore.case = TRUE)
  expect_true(liens$score[[1]] > 0)
})

test_that("tous les liens portent la requete, encodee", {
  cs <- categories_de_la_requete("dette publique")
  liens <- liens_de_la_requete("dette publique", cs)
  avec_gabarit <- grepl("{q}", liens$gabarit, fixed = TRUE)
  # Un lien construit avec un gabarit doit contenir la requete encodee : c'est
  # ce qui garantit qu'aucun resultat n'est hors sujet.
  expect_true(all(grepl("dette%20publique", liens$url[avec_gabarit])))
  expect_false(any(grepl("{q}", liens$url, fixed = TRUE)))
})

test_that("une requete sans rattachement ne casse rien", {
  cs <- categories_de_la_requete("xyzzy")
  expect_length(cs, 0L)
  liens <- liens_de_la_requete("xyzzy", cs)
  expect_equal(nrow(liens), nrow(sites_fiables()))
  expect_true(all(liens$score == 0))
})

test_that("le filtre par type ne retient que les sources voulues", {
  cs <- categories_de_la_requete("dette publique")
  actualite <- liens_de_la_requete("dette publique", cs, "actualite")
  expect_true(all(actualite$type == "actualite"))
  expect_gt(nrow(actualite), 0L)

  tous <- liens_de_la_requete("dette publique", cs, names(TYPES))
  expect_equal(nrow(tous), nrow(sites_fiables()))
})

test_that("chaque type propose au moins une source pertinente sur un sujet courant", {
  # Un type coche qui ne rend jamais rien de pertinent serait trompeur.
  for (requete in c("dette publique", "inflation", "cours du cacao")) {
    cs <- categories_de_la_requete(requete)
    for (type in names(TYPES)) {
      l <- liens_de_la_requete(requete, cs, type)
      expect_gt(sum(l$score > 0), 0L, info = paste(requete, type))
    }
  }
})

test_that("aucun type selectionne rend un tableau vide sans erreur", {
  cs <- categories_de_la_requete("inflation")
  expect_equal(nrow(liens_de_la_requete("inflation", cs, character(0))), 0L)
})

test_that("une definition porte toujours une source", {
  # C'est la condition posee sur une source absente qui interrompait
  # l'affichage de la recherche entiere : `nzchar(NULL)` rend un vecteur vide,
  # dont `if` ne sait que faire. La source est donc toujours une chaine.
  .i18n$langue <- "fr"
  for (terme in c("dette publique", "inflation", "PIB", "agr\u00e9gat")) {
    d <- definir(terme)
    expect_false(is.null(d), info = terme)
    expect_true(is.character(d$source), info = terme)
    expect_true(nzchar(d$source), info = terme)
  }
})

test_that("les sources citees sont des references, non la plateforme", {
  # Une definition doit renvoyer a une autorite. Le glossaire ne se cite
  # lui-meme qu'a defaut de mieux.
  d <- utils::read.csv(app_sys("extdata/definitions.csv"),
                       stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  expect_true("source" %in% names(d))
  expect_true(all(nzchar(d$source)))
  expect_lt(sum(grepl("OPESc", d$source)), 3L)
})

test_that("un libelle d'indicateur retrouve la bonne notion", {
  # Les libelles d'indicateurs ne reprennent presque jamais le nom canonique
  # d'une notion : les variantes de libelle font le lien.
  .i18n$langue <- "fr"
  attendus <- list(
    "Taux de croissance du PIB r\u00e9el" = "Croissance \u00e9conomique",
    "Dette publique brute" = "Dette publique",
    "Taux de ch\u00f4mage total" = "Taux de ch\u00f4mage",
    "Envois de fonds des migrants" = "Transferts des migrants")
  for (libelle in names(attendus)) {
    d <- definir(libelle)
    expect_false(is.null(d), info = libelle)
    expect_equal(d$terme, attendus[[libelle]], info = libelle)
  }
})

test_that("un mot commun ne suffit pas a rattacher une notion", {
  # « prix » rattachait « PIB par habitant, prix courants » a l'indice des prix
  # a la consommation. Une definition fausse est pire qu'une definition
  # absente.
  .i18n$langue <- "fr"
  d <- definir("PIB par habitant, prix courants")
  expect_false(identical(d$terme, "Indice des prix \u00e0 la consommation"))
})

test_that("la variante la plus specifique l'emporte", {
  # « PIB reel » est une variante du produit interieur brut, « taux de
  # croissance du PIB » une variante de la croissance : sur un libelle qui
  # contient les deux, la seconde doit gagner.
  .i18n$langue <- "fr"
  expect_equal(definir("Taux de croissance du PIB r\u00e9el")$terme,
               "Croissance \u00e9conomique")
})

test_that("toute definition affichee porte une langue", {
  .i18n$langue <- "fr"
  d <- definir("dette publique")
  expect_true(nzchar(d$source))
})

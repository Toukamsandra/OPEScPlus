test_that("la table des complements pays est bien formee", {
  t <- table_pays_extra()
  expect_gt(nrow(t), 180)
  expect_equal(nrow(t), length(unique(t$iso3)))
  expect_true(all(nchar(t$iso3) == 3))
  expect_true(all(nchar(t$iso2) == 2))
})

test_that("un pays inconnu ne fait pas echouer la fiche", {
  # Un territoire absent de la table doit rendre des champs vides, pas une
  # erreur : sinon un clic sur la carte casserait tout l'affichage.
  r <- infos_pays("ZZZ")
  expect_equal(r$iso2, "")
  expect_equal(r$langues, "")
})

test_that("les complements du Cameroun sont exacts", {
  r <- infos_pays("CMR")
  expect_equal(r$iso2, "cm")
  expect_match(r$langues, "Fran\u00e7ais")
  expect_match(r$langues, "anglais")
})

test_that("l'adresse du drapeau est vide quand le code manque", {
  expect_equal(url_drapeau(""), "")
  expect_match(url_drapeau("cm", 80), "^https://flagcdn\\.com/w80/cm\\.png$")
})

test_that("tous les partenaires du bandeau ont leurs complements", {
  for (i in seq_len(nrow(PARTENAIRES))) {
    r <- infos_pays(PARTENAIRES$iso3[[i]])
    expect_true(nzchar(r$iso2), info = PARTENAIRES$nom[[i]])
    expect_equal(r$iso2, PARTENAIRES$iso2[[i]], info = PARTENAIRES$nom[[i]])
  }
})

test_that("les icones renvoient du SVG", {
  for (n in c("chart", "layers", "globe", "trend", "table", "refresh")) {
    expect_match(as.character(icone(n)), "<svg", fixed = TRUE)
  }
  # Un nom inconnu rend une forme neutre plutot qu'une erreur.
  expect_match(as.character(icone("inexistant")), "<svg", fixed = TRUE)
})

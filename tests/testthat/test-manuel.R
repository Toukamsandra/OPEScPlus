test_that("les quatre manuels sont livres avec le paquet", {
  # Le telechargement copie un fichier embarque : s'il manque, le bouton
  # echoue au clic et non a l'installation. D'ou ce controle.
  for (langue in c("fr", "en")) {
    for (format in c("pdf", "docx")) {
      chemin <- chemin_manuel(langue, format)
      expect_true(nzchar(chemin) && file.exists(chemin),
                  info = paste(langue, format))
      expect_gt(file.size(chemin), 10000)
    }
  }
})

test_that("chemin_manuel refuse une langue ou un format inconnu", {
  expect_error(chemin_manuel("de", "pdf"))
  expect_error(chemin_manuel("fr", "odt"))
})

test_that("les quatre manuels sont servis comme ressources statiques", {
  # Le telechargement pointe vers inst/app/www : si le fichier n'y est pas, le
  # navigateur recoit une erreur 404 sans le moindre message.
  for (langue in c("fr", "en")) {
    for (format in c("pdf", "docx")) {
      chemin <- app_sys(sprintf("app/www/manuel/manuel_opesc_%s.%s", langue, format))
      expect_true(nzchar(chemin) && file.exists(chemin), info = paste(langue, format))
      expect_gt(file.size(chemin), 20000)
    }
  }
})

test_that("le selecteur de langue est une liste deroulante", {
  h <- as.character(selecteur_langue())
  expect_match(h, "<select", fixed = TRUE)
  expect_match(h, "langue-liste", fixed = TRUE)
  # Les deux langues doivent y figurer.
  expect_match(h, 'value="fr"', fixed = TRUE)
  expect_match(h, 'value="en"', fixed = TRUE)
})

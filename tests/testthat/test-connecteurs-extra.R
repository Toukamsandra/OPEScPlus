test_that("les periodes de toutes formes sont normalisees", {
  # Les fournisseurs rendent la periode sous des formes variees : 2023,
  # 2023-Q2, 2023-M07, 2023-07. Chacune est ramenee au premier jour de la
  # periode qu'elle couvre.
  d <- normaliser_serie(
    iso3 = rep("CMR", 4),
    periode = c("2023", "2023-Q4", "2023-M07", "2023-03"),
    valeur = c(1, 2, 3, 4))
  expect_equal(nrow(d), 4L)
  expect_equal(d$frequence, c("A", "Q", "M", "M"))
  expect_equal(d$date_periode,
               c("2023-01-01", "2023-10-01", "2023-07-01", "2023-03-01"))
})

test_that("une periode invalide est ecartee, pas devinee", {
  # Un cinquieme trimestre ou un treizieme mois signale un format non prevu :
  # deviner produirait une observation fausse, silencieusement.
  d <- normaliser_serie(iso3 = rep("CMR", 3),
                        periode = c("2023-Q5", "2023-M13", "2023-Q2"),
                        valeur = c(1, 2, 3))
  expect_equal(nrow(d), 1L)
  expect_equal(d$date_periode, "2023-04-01")
})

test_that("les codes pays qui ne sont pas en ISO3 sont ecartes", {
  # Convertir a l'aveugle creerait de faux rapprochements : « CM » peut
  # designer le Cameroun comme autre chose selon la nomenclature.
  d <- normaliser_serie(iso3 = c("CMR", "CM", "120", "NGA"),
                        periode = rep("2023", 4), valeur = 1:4)
  expect_equal(sort(d$iso3), c("CMR", "NGA"))
})

test_that("une valeur absente n'est pas enregistree", {
  d <- normaliser_serie(iso3 = rep("CMR", 3), periode = rep("2023", 3),
                        valeur = c(1, NA, 3))
  expect_equal(nrow(d), 2L)
})

test_that("l'annee de depart filtre la serie", {
  d <- normaliser_serie(iso3 = rep("CMR", 3),
                        periode = c("2018", "2021", "2024"),
                        valeur = 1:3, debut = 2020)
  expect_equal(nrow(d), 2L)
})

test_that("une serie vide porte les colonnes attendues", {
  # Le moteur assemble les series par rbind : une serie vide sans colonnes
  # ferait echouer l'assemblage.
  d <- serie_vide()
  expect_equal(names(d),
               c("iso3", "date_periode", "frequence", "valeur"))
  expect_equal(nrow(d), 0L)
})

test_that("les trois fournisseurs sont au registre", {
  for (f in c("OCDE", "OIT (ILOSTAT)", "CNUCED")) {
    expect_true(f %in% names(REGISTRE), info = f)
    expect_true(is.function(REGISTRE[[f]]), info = f)
  }
})

test_that("toute fonction citee au registre existe", {
  # Cette verification est nee d'un chargement qui echouait : le registre
  # etait construit dans un fichier lu avant celui qui definit certains
  # connecteurs, R lisant les fichiers d'un paquet par ordre alphabetique.
  for (nom in names(REGISTRE)) {
    expect_true(is.function(REGISTRE[[nom]]), info = nom)
  }
})

test_that("le registre est defini dans un fichier lu en dernier", {
  # Le prefixe zzz garantit l'ordre. Sans lui, ajouter un connecteur dans un
  # fichier dont le nom suit alphabetiquement casserait le chargement, et
  # l'erreur ne parlerait pas d'ordre de lecture.
  fichiers <- basename(list.files(
    system.file("..", package = "opescplus"), pattern = "[.]R$",
    recursive = TRUE))
  if (!length(fichiers)) skip("Sources non accessibles depuis le paquet installe.")
  succeed()
})

test_that("les codes de zone propres a un fournisseur sont ecartes", {
  # L'Organisation internationale du travail numerote ses regions X01, X02 :
  # trois caracteres comme un code ISO3, mais ils ne designent aucun pays et
  # se melangeraient a eux sans etre reconnus.
  d <- normaliser_serie(iso3 = c("CMR", "X01", "X02", "NGA", "WLD"),
                        periode = rep("2023", 5), valeur = 1:5)
  expect_equal(sort(d$iso3), c("CMR", "NGA", "WLD"))
})

test_that("tout code prive commencant par X est ecarte", {
  # La norme ISO 3166 reserve la lettre X aux usages prives : aucun pays n'en
  # porte. Un premier filtre ne visait que X01 et X02, et laissait passer XA1,
  # region de l'Organisation internationale du travail.
  d <- normaliser_serie(
    iso3 = c("CMR", "X01", "XA1", "XB2", "NGA"),
    periode = rep("2023", 5), valeur = 1:5)
  expect_equal(sort(d$iso3), c("CMR", "NGA"))
})

# ---------------------------------------------------------------------------
# Configuration generale de la plateforme OPESc+
#
# Le chemin de la base n'est plus une constante : voir `chemin_base()` dans
# bd.R. Un paquet installe est en lecture seule, la base ne peut donc pas
# vivre a l'interieur.
# ---------------------------------------------------------------------------

CONFIG <- list(
  nom          = "OPESc+",
  sous_titre   = "Observatoire des perspectives economiques",
  ministere    = "MINEPAT",
  devise       = "Republique du Cameroun : Paix, Travail, Patrie",
  pays_defaut  = "CMR",
  max_series   = 6L,      # nombre de courbes superposables
  max_pays     = 8L,
  fuseau       = "Africa/Douala"
)

# Frequences reconnues, de la plus fine a la plus large.
# Les sources retenues (Banque mondiale, FMI, OCDE) ne publient que de l'annuel,
# du trimestriel et du mensuel. Les niveaux hebdomadaire, journalier et
# intrajournalier sont prevus dans le schema pour les cours de change et de
# matieres premieres que l'on pourra brancher plus tard, mais aucune source du
# catalogue actuel ne les alimente : le filtre ne les proposera donc jamais tant
# qu'aucune observation de ce pas n'existe en base.
FREQUENCES <- data.frame(
  code    = c("I", "J", "H", "M", "T", "S", "A"),
  libelle = c("Intrajournaliere", "Journaliere", "Hebdomadaire", "Mensuelle",
              "Trimestrielle", "Semestrielle", "Annuelle"),
  rang    = 1:7,
  stringsAsFactors = FALSE
)

# Palette : lisible en videoprojection et distinguable en nuances de gris.
PALETTE <- c("#1F3864", "#C00000", "#2E7D32", "#E07B00", "#5B2C87",
             "#00838F", "#8D6E63", "#455A64")

libelle_frequence <- function(codes) {
  tr(FREQUENCES$libelle[match(codes, FREQUENCES$code)])
}

# Vecteur nomme pour selectInput : c("Annuelle" = "A", ...), du plus large au
# plus fin, l'annuel etant le cas le plus courant.
choix_frequences <- function(codes) {
  codes <- codes[codes %in% FREQUENCES$code]
  if (!length(codes)) return(character(0))
  f <- FREQUENCES[FREQUENCES$code %in% codes, ]
  f <- f[order(-f$rang), ]
  stats::setNames(f$code, tr(f$libelle))
}

# Principaux partenaires commerciaux du Cameroun, affiches dans le bandeau.
#
# Rangs 1 a 5 et 8 : classement des clients du Cameroun en 2024 publie par
# l'Institut national de la statistique (Pays-Bas 19,2 %, Chine 16,5 %,
# Inde 10,1 %, Italie 6,4 %, France 5,7 %, Tchad 4,3 %). Les autres sont les
# principaux fournisseurs, dont le rang exact n'a pas ete verifie.
#
# La liste se modifie ici et nulle part ailleurs. Le code `iso2` sert a
# retrouver le drapeau, le code `iso3` a filtrer la base d'un clic.
PARTENAIRES <- data.frame(
  iso2 = c("nl", "cn", "in", "it", "fr", "es", "be", "td", "ng", "us"),
  iso3 = c("NLD", "CHN", "IND", "ITA", "FRA", "ESP", "BEL", "TCD", "NGA", "USA"),
  nom  = c("Pays-Bas", "Chine", "Inde", "Italie", "France",
           "Espagne", "Belgique", "Tchad", "Nig\u00e9ria", "\u00c9tats-Unis"),
  stringsAsFactors = FALSE
)

# Texte de presentation affiche sous le bandeau.
PRESENTATION <- list(
  titre = "Donn\u00e9es \u00e9conomiques mondiales, comparables et actualis\u00e9es",
  chapo = paste(
    "OPESc+ rassemble les indicateurs \u00e9conomiques de l'ensemble des",
    "\u00e9conomies, collect\u00e9s directement aupr\u00e8s des institutions qui les",
    "publient, et les met \u00e0 disposition sous forme de s\u00e9ries exploitables."),
  points = list(
    c("Quatorze cat\u00e9gories",
      "Des mati\u00e8res premi\u00e8res aux finances publiques, de la monnaie au secteur ext\u00e9rieur."),
    c("Quatre sources de r\u00e9f\u00e9rence",
      "Banque mondiale, Fonds mon\u00e9taire international, OCDE, Growth Lab de l'Universit\u00e9 Harvard."),
    c("Filtres en cascade",
      "Cat\u00e9gorie, indicateur, fr\u00e9quence, p\u00e9riode, pays. Chaque \u00e9tape se limite \u00e0 ce qui existe en base."),
    c("Graphique et carte",
      "Comparaison entre pays, superposition de s\u00e9ries, projection, export en image et en tableur."))
)


# ---------------------------------------------------------------------------
# Configuration generale de la plateforme OPESc+
#
# Le chemin de la base n'est plus une constante : voir `chemin_base()` dans
# bd.R. Un paquet installe est en lecture seule, la base ne peut donc pas
# vivre a l'interieur.
# ---------------------------------------------------------------------------

CONFIG <- list(
  nom          = "OPESc+",
  sous_titre   = "Observatoire des perspectives \u00e9conomiques",
  ministere    = "MINEPAT",
  devise       = "R\u00e9publique du Cameroun : Paix, Travail, Patrie",
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
# Palette des graphiques, accordee a la charte du ministere. Les trois
# premieres couleurs sont celles des armoiries de la Republique, ce qui donne
# a un graphique a deux ou trois series une identite immediate. Les suivantes
# les completent en restant distinguables, y compris pour un daltonien : elles
# different autant par leur clarte que par leur teinte.
PALETTE <- c("#0A2F5C", "#CE1126", "#2E7BC4", "#177245", "#7A5195",
             "#B07219", "#5A6470", "#8FC0EA")

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

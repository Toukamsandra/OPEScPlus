# Shiny charge automatiquement les fichiers du dossier R/ quand il detecte une
# application. Dans un paquet, c'est l'espace de noms qui s'en charge : laisser
# les deux mecanismes actifs chargerait le code deux fois.
options(shiny.autoload.r = FALSE)

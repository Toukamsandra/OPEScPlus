# ---------------------------------------------------------------------------
# Registre des connecteurs.
#
# Ce fichier porte le prefixe `zzz` pour une raison precise : R lit les
# fichiers d'un paquet par ordre alphabetique, et cette liste nomme des
# fonctions definies dans plusieurs fichiers. Placee ailleurs, elle serait
# evaluee avant que certaines existent, et le chargement echouerait sur un
# « objet introuvable ».
#
# Toute source du catalogue doit y figurer. Un indicateur dont la source en
# est absente est desactive au chargement plutot que laisse visible et muet
# dans l'interface.
# ---------------------------------------------------------------------------

REGISTRE <- list(
  "Banque mondiale (WDI)"      = connecteur_banque_mondiale,
  "Banque mondiale (IDS)"      = connecteur_banque_mondiale,
  "Banque mondiale (WGI)"      = connecteur_banque_mondiale,
  "Banque mondiale (PIP)"      = connecteur_banque_mondiale,
  "Banque mondiale (Findex)"   = connecteur_banque_mondiale,
  "Banque mondiale (ASPIRE)"   = connecteur_banque_mondiale,
  "Banque mondiale (LPI)"      = connecteur_banque_mondiale,
  "Banque mondiale (B-READY)"  = connecteur_banque_mondiale,
  # Les trois anciennes entrees FMI convergent vers le flux WEO du nouveau
  # portail : il porte aussi bien les agregats de finances publiques que les
  # cours des matieres premieres.
  "FMI (WEO)"                  = connecteur_fmi_weo,
  "FMI (Fiscal Monitor)"       = connecteur_fmi_weo,
  "FMI (PCPS)"                   = connecteur_produits_de_base,
  "Banque mondiale (Pink Sheet)" = connecteur_produits_de_base,
  # L'OCDE revient au registre. Les 404 obtenus auparavant s'expliquent : elle
  # a retire `stats.oecd.org` en 2024 pour un nouveau service a
  # `sdmx.oecd.org`. Les identifiants de flux ont change de forme avec lui,
  # et ceux du catalogue doivent etre verifies un par un avec
  # `tester_fournisseur()` avant d'etre consideres comme acquis.
  "OCDE"                       = connecteur_ocde,
  "OIT (ILOSTAT)"              = connecteur_ilostat,
  "CNUCED"                     = connecteur_cnuced,
  "Growth Lab Harvard (Atlas)" = connecteur_atlas,
  "Growth Lab Harvard"         = connecteur_atlas,
  "Growth Lab / Comtrade"      = connecteur_atlas)

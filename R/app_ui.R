#' Interface de l'application
#'
#' @param request objet de requete Shiny, requis pour la mise en signet.
#' @noRd
app_ui <- function(request) {
  # La langue est lue dans l'adresse avant toute construction : tous les
  # appels a tr() qui suivent en dependent.
  langue_courante(request)

  shiny::tagList(
    ressources_externes(),
    message_bienvenue(),
    shiny::tags$span(id = "opesc-texte-reconnexion", style = "display:none",
                     tr("Reconnexion en cours")),

    shiny::div(
      class = "bandeau",
      # La devise nationale est retiree du bandeau : elle figure deja sur les
      # armoiries, ou elle est lisible, et la repeter en petit texte gris
      # encombrait la ligne sans rien apporter.
      shiny::div(
        class = "bandeau-principal",
        shiny::div(
          class = "bandeau-cote",
          shiny::img(src = "www/armoiries_cameroun.png", class = "logo logo-etat",
                     alt = tr("Armoiries de la R\u00e9publique du Cameroun"))),
        shiny::div(
          class = "marque",
          shiny::strong(CONFIG$nom),
          shiny::tags$small(tr(CONFIG$sous_titre))),
        shiny::div(
          class = "bandeau-cote bandeau-cote-droite",
          selecteur_langue(),
          shiny::img(src = "www/logo_minepat.png", class = "logo logo-ministere",
                     alt = CONFIG$ministere))),
      bandeau_partenaires()),

    shiny::div(
      class = "conteneur",
      shiny::navbarPage(
        title = NULL, id = "onglets", theme = theme_opesc(), collapsible = TRUE,
        shiny::tabPanel(tr("Accueil"), mod_accueil_ui("accueil")),
        shiny::tabPanel(tr("Tableau de bord"), mod_tableau_bord_ui("tdb")),
        shiny::tabPanel(tr("Base de donn\u00e9es"), mod_base_donnees_ui("base")),
        shiny::tabPanel("GoogleOPESc+", mod_recherche_ui("recherche")),
        shiny::tabPanel(tr("Collectes"), mod_collectes_ui("collectes")))),

    shiny::div(
      class = "pied",
      shiny::div(shiny::strong(CONFIG$nom), " : ", CONFIG$sous_titre),
      shiny::div(
        class = "pied-mentions",
        tr("Donn\u00e9es : Banque mondiale, Fonds mon\u00e9taire international, OCDE, "),
        tr("Growth Lab (Universit\u00e9 Harvard), CNUCED, OIT, FAO. "),
        tr("Toute r\u00e9utilisation doit citer la source d'origine et la date d'extraction."))))
}

#' Bandeau des principaux partenaires commerciaux
#'
#' Les drapeaux sont servis par flagcdn.com, qui les expose par code ISO a deux
#' lettres. Aucun fichier n'est donc a distribuer avec le paquet. Si le service
#' est injoignable, l'image se masque et le code du pays reste affiche : le
#' bandeau garde son sens hors connexion.
#' @noRd
bandeau_partenaires <- function() {
  shiny::div(
    class = "bandeau-partenaires",
    shiny::div(
      class = "partenaires-interne",
      shiny::span(class = "partenaires-titre", tr("Principaux partenaires commerciaux")),
      shiny::div(
        class = "partenaires-liste",
        lapply(seq_len(nrow(PARTENAIRES)), function(i) {
          iso2 <- PARTENAIRES$iso2[[i]]
          shiny::span(
            class = "partenaire", title = PARTENAIRES$nom[[i]],
            shiny::img(
              class = "drapeau", src = url_drapeau(iso2, 40),
              alt = tr(PARTENAIRES$nom[[i]]),
              onerror = "this.style.display='none'"),
            shiny::span(class = "partenaire-nom", tr(PARTENAIRES$nom[[i]])))
        }))))
}

#' Message d'accueil affiche a l'ouverture
#'
#' Une notification breve, pas une fenetre modale : un dialogue a fermer a
#' chaque connexion devient vite une corvee pour qui ouvre la plateforme
#' plusieurs fois par jour.
#' @noRd
message_bienvenue <- function() {
  # Le message ne paraît qu'une fois par session de navigation. Il reparaissait
  # a chaque rechargement de page, donc a chaque changement de langue et a
  # chaque retour sur l'onglet, ce qui en faisait une gene plutot qu'un accueil.
  # `sessionStorage` retient qu'il a ete montre ; il s'efface a la fermeture du
  # navigateur, si bien qu'une nouvelle connexion le retrouve.
  #
  # Le cadre est retire du document en meme temps que le texte disparait, et
  # non quelques instants plus tard : un encadre vide subsistait le temps de la
  # transition.
  titre <- sprintf("%s %s", tr("Bienvenue sur"), CONFIG$nom)
  corps <- tr(paste(
    "Observatoire des perspectives \u00e9conomiques du MINEPAT. Les donn\u00e9es mises",
    "\u00e0 disposition proviennent des institutions statistiques internationales de",
    "r\u00e9f\u00e9rence. Nous vous souhaitons d'y trouver mati\u00e8re \u00e0 vos analyses."))

  shiny::tags$script(shiny::HTML(sprintf(
    "document.addEventListener('DOMContentLoaded', function () {
       try {
         if (sessionStorage.getItem('opesc_bienvenue')) { return; }
         sessionStorage.setItem('opesc_bienvenue', '1');
       } catch (e) { /* navigation privee : le message s'affichera */ }

       setTimeout(function () {
         var n = document.createElement('div');
         n.className = 'bienvenue';
         n.innerHTML = '<strong>' + %s + '</strong><span>' + %s + '</span>';
         document.body.appendChild(n);

         var retirer = function () {
           n.classList.remove('bienvenue-visible');
           setTimeout(function () { if (n.parentNode) { n.remove(); } }, 340);
         };
         setTimeout(function () { n.classList.add('bienvenue-visible'); }, 60);
         setTimeout(retirer, 7000);
         n.addEventListener('click', retirer);
       }, 500);
     });",
    jsonlite::toJSON(titre, auto_unbox = TRUE),
    jsonlite::toJSON(corps, auto_unbox = TRUE))))
}

#' Theme visuel
#' @noRd
theme_opesc <- function() {
  bslib::bs_theme(
    version = 5,
    primary = "#1F3864", secondary = "#5C6672",
    "body-bg" = "#F5F7FA", "body-color" = "#1B1F24")
}

#' Ressources statiques servies sous /www
#'
#' `add_resource_path` remplace le dossier `www/` d'une application classique :
#' dans un paquet, les fichiers vivent dans `inst/app/www` et doivent etre
#' declares explicitement.
#' @noRd
ressources_externes <- function() {
  golem::add_resource_path("www", app_sys("app/www"))

  shiny::tags$head(
    golem::favicon(ico = "favicon", ext = "png"),
    golem::bundle_resources(path = app_sys("app/www"), app_title = "OPESc+"),
    shiny::tags$link(rel = "stylesheet", type = "text/css", href = "www/opesc.css"),
    shiny::tags$script(src = "www/opesc.js"),

    # Le message du voile de deconnexion est pose des le chargement : Shiny
    # cree ce voile lui-meme, sans texte, et il n'y a pas d'autre moment pour
    # lui en donner un.
    shiny::tags$script(shiny::HTML(sprintf(
      "document.addEventListener('DOMContentLoaded', function () {
         var poser = function () {
           var v = document.getElementById('shiny-disconnected-overlay');
           if (v) { v.setAttribute('data-message', %s); }
         };
         document.addEventListener('shiny:disconnected', function () {
           setTimeout(poser, 50);
         });
       });",
      jsonlite::toJSON(tr(paste(
        "La connexion \u00e0 la plateforme a \u00e9t\u00e9 interrompue. Vos donn\u00e9es sont",
        "intactes : rechargez la page pour reprendre.")), auto_unbox = TRUE)))))
}

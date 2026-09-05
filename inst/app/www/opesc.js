/* Mise en evidence de la tuile de categorie active.
 *
 * Le basculement se fait cote client, sans reconstruire les boutons. Regenerer
 * les tuiles a chaque changement de categorie remettrait a zero le compteur de
 * clics des actionButton, ce que Shiny interprete comme un nouveau clic : les
 * observateurs se declencheraient en cascade a chaque selection. */
document.addEventListener("click", function (e) {
  var tuile = e.target.closest(".tuile");
  if (!tuile) { return; }
  var groupe = tuile.closest(".tuiles");
  if (!groupe) { return; }
  groupe.querySelectorAll(".tuile").forEach(function (t) {
    t.classList.remove("tuile-active");
  });
  tuile.classList.add("tuile-active");
});

/* Retrait d'une serie affichee.
 *
 * Le clic passe par Shiny.setInputValue en mode evenement plutot que par un
 * actionLink. Reconstruire la liste des jetons remettait a zero le compteur de
 * clics de chaque lien, ce que Shiny lisait comme un nouveau clic : ajouter
 * une troisieme serie declenchait aussitot le retrait des precedentes. */
document.addEventListener("click", function (e) {
  var bouton = e.target.closest(".jeton-retirer");
  if (!bouton) { return; }
  e.preventDefault();
  if (window.Shiny && Shiny.setInputValue) {
    Shiny.setInputValue(bouton.dataset.cible, bouton.dataset.serie,
                        { priority: "event" });
  }
});

/* Maintien de la connexion et lisibilite pendant les calculs.
 *
 * Deux phenomenes distincts assombrissent la page, et Shiny les traite de la
 * meme facon alors qu'ils n'ont pas la meme gravite.
 *
 *   1. Un calcul en cours : Shiny estompe les sorties concernees. C'est
 *      normal, mais l'estompage etait si fort qu'il ressemblait a une panne.
 *   2. La connexion perdue : Shiny voile toute la page en gris, sans un mot.
 *      L'utilisateur croit que l'ecran s'est mis en veille alors que
 *      l'application ne repond simplement plus.
 *
 * Le battement ci-dessous evite la seconde situation dans la plupart des cas :
 * une connexion sans echange finit par etre fermee, par le navigateur qui
 * ralentit les onglets en arriere-plan comme par les equipements reseau
 * intermediaires. */
(function () {
  var PERIODE = 20000;
  var battement = null;

  function demarrer() {
    if (battement) { return; }
    battement = setInterval(function () {
      if (window.Shiny && Shiny.setInputValue) {
        Shiny.setInputValue("opesc_battement", Date.now(), { priority: "event" });
      }
    }, PERIODE);
  }

  function arreter() {
    if (battement) { clearInterval(battement); battement = null; }
  }

  document.addEventListener("shiny:connected", demarrer);
  document.addEventListener("shiny:disconnected", arreter);

  /* Un onglet revenu au premier plan a pu manquer plusieurs battements : on en
     envoie un tout de suite plutot que d'attendre le suivant. */
  document.addEventListener("visibilitychange", function () {
    if (!document.hidden && window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue("opesc_battement", Date.now(), { priority: "event" });
    }
  });
})();

/* Maintien de la connexion.
 *
 * Shiny voile la page en gris quand la liaison avec le serveur se coupe, ce
 * qui donne l'impression que le site se met en veille. Deux causes se
 * combinent : le navigateur ralentit les minuteries d'un onglet laisse au
 * second plan, et les serveurs intermediaires ferment les connexions restees
 * silencieuses.
 *
 * Un battement regulier suffit a l'eviter. L'ecouteur est pose sur le document
 * plutot que sur l'objet Shiny : ce fichier est charge avant le script de
 * Shiny, et tester son existence a cet instant reviendrait a ne rien
 * enregistrer du tout. */
document.addEventListener("shiny:connected", function () {
  setInterval(function () {
    if (window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue("opesc_pouls", Date.now(), { priority: "event" });
    }
  }, 25000);
});

/* Reconnexion silencieuse. Plutot que de laisser le voile gris et un lien
 * « Reload », on tente de rouvrir la page de nous-memes apres un court delai :
 * l'interruption est le plus souvent passagere. */
document.addEventListener("shiny:disconnected", function () {
  if (document.querySelector(".bandeau-reconnexion")) { return; }
  var source = document.getElementById("opesc-texte-reconnexion");
  var bandeau = document.createElement("div");
  bandeau.className = "bandeau-reconnexion";
  bandeau.textContent = source ? source.textContent : "Reconnexion";
  document.body.appendChild(bandeau);
  setTimeout(function () { window.location.reload(); }, 4000);
});

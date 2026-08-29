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

# ---------------------------------------------------------------------------
# Travail courant.
# ---------------------------------------------------------------------------

# Ajouter un module : cree R/mod_<nom>.R avec le squelette golem.
#   golem::add_module(name = "fiches_pays", with_test = TRUE)

# Ajouter un fichier utilitaire ou une fonction de service.
#   golem::add_utils("dates")
#   golem::add_fct("projections")

# Ajouter une ressource statique dans inst/app/www.
#   golem::add_css_file("complements")
#   golem::add_js_file("interactions")

# Regenerer NAMESPACE et man/ apres modification des balises roxygen.
#   devtools::document()

# Tests.
#   devtools::test()
#   devtools::check()

# Lancer l'application en developpement.
#   devtools::load_all(); run_app()

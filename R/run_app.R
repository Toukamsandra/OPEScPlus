#' Lance la plateforme OPESc+
#'
#' @param onStart fonction executee avant le premier appel de l'application.
#' @param options options passees a [shiny::shinyApp()].
#' @param enableBookmarking mode de mise en signet.
#' @param uiPattern expression reguliere des chemins servis.
#' @param ... options accessibles ensuite par `golem::get_golem_options()`.
#'
#' @examples
#' \dontrun{
#' opescplus::run_app()
#' }
#' @export
run_app <- function(onStart = NULL,
                    options = list(),
                    enableBookmarking = NULL,
                    uiPattern = "/",
                    ...) {
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern),
    golem_opts = list(...))
}

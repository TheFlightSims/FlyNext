require([
        'jquery', 
], function(jquery) {
  // nested require to ensure jquery is ready before
  // jui_theme_switch starts
  require([
        '3rdparty/jquery/jquery.jui_theme_switch.min'
  ], function() {


    $(function() {
      $("#ui-theme-switcher").jui_theme_switch({
        stylesheet_link_id: "ui-theme",
        datasource_url: "jquery-ui-themes.json"
      });
    });
});

});

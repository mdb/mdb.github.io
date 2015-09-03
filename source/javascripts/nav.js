$(document).ready(function() {
  $('button').click(function() {
    $(this).toggleClass('expanded').siblings('div.nav-container').toggleClass('expanded');
  });
});

$(document).ready(function () {
  var imgs = $('ul.gallery li a.thumbnail img');

  $(imgs).on('load', function() {
    $(this).fadeIn().parent().addClass('loaded');
  });
});

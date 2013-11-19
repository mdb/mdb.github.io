$(document).ready(function () {
  var imgs = $('ul.gallery li a.thumbnail img');

  imgs.each(function() {
    if (this.complete) {
      $(this).fadeIn();
    } else {
      $(this).load(function() {
        $(this).fadeIn();
      });
    }
  });
});

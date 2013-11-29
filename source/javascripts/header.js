$(document).ready(function () {
  var footerPos = $('footer').offset().top,
      header = $('.header-content'),
      headerHeight = header.height();

  $(this).scroll(function () {
    if ($(document).scrollTop() > footerPos - headerHeight - 25) {
      header.slideUp('fast');
    } else {
      header.slideDown('fast');
    }
  });
});

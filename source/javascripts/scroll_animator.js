$(document).ready(function () {
  var anchors = $('a[href*=#]'),
      samePathAndHost = function (anchor) {
        return location.pathname.replace(/^\//,'') === anchor.pathname.replace(/^\//,'') && location.hostname === anchor.hostname;
      };

  anchors.click(function() {
    var $target,
        targetOffset;

    if (samePathAndHost(this)) {
      $target = $(this.hash);

      $target = $target.length && $target || $('[name=' + this.hash.slice(1) +']');

      if ($target.length) {
        targetOffset = $target.offset().top;

        $('html,body').animate({scrollTop: targetOffset}, 900);

        return false;
      }
    }
  });
});

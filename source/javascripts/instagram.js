(function ($) {
  $.fn.instagram = function (options) {
    this.api = 'https://clapclapexcitement-gram.herokuapp.com/recent-media',

    this.config = $.extend({
      template: '#instagram-template',
      count: 8
    }, options);

    this.get = function () {
      var self = this;

      $.ajax({
        type: 'GET',
        cache: false,
        url: self.api,
        success: function (res) {
          var items = self._getItems(res),
              html = _.template($(self.config.template).html(), { items: items });

          self.append(html);
        }
      });
    };

    this._getItems = function (data) {
      var self = this,
          items = [],
          length = data.length < self.config.count ? data.length : self.config.count,
          i;

      for(i=0; i<length; i++) {
        items.push({
          url: data[i].permalink,
          imgSrc: data[i].media_url
        });
      }

      return items;
    };

    this.get();

    return this;
  };
})(jQuery);

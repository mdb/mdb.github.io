(function ($) {
  $.fn.instagram = function (options) {
    this.api = "https://api.instagram.com/v1",

    this.config = $.extend({
      userId: null,
      accessToken: null,
      template: "#instagram-template",
      show: 8,
    }, options);

    this.get = function () {
      var self = this;

      $.ajax({
        type: "GET",
        dataType: "jsonp",
        cache: false,
        url: self._buildRequestURL(),
        success: function (res) {
          var items = self._getItems(res),
              html = _.template($(self.config.template).html(), { items: items });

          self.append(html);
        }
      });
    };

    this._getItems = function (data) {
      var items = [],
          length = data.data.length < this.config.show ? data.data.length : this.config.show,
          i;

      for(i=0; i<length; i++) {
        items.push({
          url: data.data[i].link,
          imgSrc: data.data[i].images.thumbnail.url
        });
      }

      return items;
    };

    this._buildRequestParamsString = function (paramsObj) {
      return '?' + $.param(paramsObj);
    };

    this._buildRequestParamsObj = function () {
      var params = {};

      params.access_token = this.config.accessToken;
      params.show = this.config.show;

      return params;
    };

    this._buildRequestURL = function () {
      var url = this.api,
          uid = this.config.userId,
          params = this._buildRequestParamsString(this._buildRequestParamsObj());

      return url + "/users/" + uid + "/media/recent" + params;
    };

    this.get();

    return this;
  };
})(jQuery);

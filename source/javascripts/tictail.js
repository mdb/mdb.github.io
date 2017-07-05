document.addEventListener('DOMContentLoaded', function(event) {
  fetch('https://api.tictail.com/v1.24/stores/5ka2/products')
    .then(function(resp) {
      return resp.json();
    }).then(function(data) {
      var items = data.slice(0, 4).map(function(item) {
            return {
              name: item.title,
              price: item.price/100,
              description: item.description,
              url: item.store_url + '/product/' + item.slug,
              imgSrc: item.images.filter((image) => { return image.original_height === 300 })[0].url
            };
          }),
          html = _.template(document.querySelector('script#tiendah-template').innerHTML, { items: items });

      document.querySelector('.tiendah').innerHTML = html;
    });
});

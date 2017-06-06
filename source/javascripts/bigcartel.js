document.addEventListener('DOMContentLoaded', function(event) {
  fetch('https://api.bigcartel.com/tiendah/products.json?limit=4')
    .then(function(resp) {
      return resp.json();
    }).then(function(data) {
      var items = data.map(function(item) {
            return {
              name: item.name,
              price: item.price,
              description: item.description,
              url: 'https://tiendah.bigcartel.com' + item.url,
              imgSrc: item.images[0].secure_url
            };
          }),
          html = _.template(document.querySelector('script#tiendah-template').innerHTML, { items: items });

      document.querySelector('.tiendah').innerHTML = html;
    });
});

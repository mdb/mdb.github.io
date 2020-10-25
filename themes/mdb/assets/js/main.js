document.addEventListener('DOMContentLoaded', () => {
  function populateIGFeeds(data) {
    let footer = document.querySelector('footer ul.ig-feed'),
        gallery = document.querySelector('ul.gallery.ig-feed'),
        images = data.slice(0, 8).map(image => {
          return `<li class="item"><a class="thumbnail" href="${image.permalink}"><img src="${image.media_url}" /></a></li>`;
        });

    footer.innerHTML = images.join('');

    if (gallery) {
      gallery.innerHTML = images.join('');
    }
  }

  fetch('https://clapclapexcitement-gram.herokuapp.com/recent-media')
    .then(response => response.json())
    .then(data => {
      populateIGFeeds(data);
    });
});

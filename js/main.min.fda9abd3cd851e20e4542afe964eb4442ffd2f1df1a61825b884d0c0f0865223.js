document.addEventListener("DOMContentLoaded",()=>{function n(e){const t=document.querySelectorAll("ul.ig-feed"),n=e.slice(0,8).map(e=>`
          <li class="item">
            <a class="thumbnail" href="${e.permalink}">
              <img src="${e.media_url}" />
            </a>
          </li>`).join('');t.forEach(e=>e.innerHTML=n)}fetch("https://mikeball.info/ig-feed/ig/media.json").then(e=>e.json()).then(n);function s(e){const t=document.querySelectorAll("ul.store-feed"),n=e.slice(0,4).map(e=>{const t=`https://tiendah.bigcartel.com/${e.url}`;return`
          <li class="item">
            <a class="thumbnail" href="${t}">
              <img src="${e.images[0].secure_url}" />
            </a>
            <div class="details">
              <aside>$${e.price}</aside>
              <h2><a href="${t}">${e.name}</a></h2>
              <p>${e.description}</p>
              <p><a href="${t}">Buy print</a></p>
            </div>
          </li>`}).join('');t.forEach(e=>e.innerHTML=n)}fetch("https://api.bigcartel.com/tiendah/products.json").then(e=>e.json()).then(s);const t=document.getElementsByTagName("button")[0],e=t.parentElement;t.addEventListener("click",()=>{if(e.className===''){e.className="toggled";return}e.className=''})})
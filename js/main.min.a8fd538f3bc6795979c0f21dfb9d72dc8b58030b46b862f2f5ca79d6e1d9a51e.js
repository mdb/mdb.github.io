document.addEventListener("DOMContentLoaded",()=>{function s(n){let s=document.querySelector("footer ul.ig-feed"),e=document.querySelector("ul.gallery.ig-feed"),t=n.slice(0,8).map(e=>`<li class="item"><a class="thumbnail" href="${e.permalink}"><img src="${e.media_url}" /></a></li>`);s.innerHTML=t.join(''),e&&(e.innerHTML=t.join(''))}fetch("https://mikeball.info/ig-feed/ig/media.json").then(e=>e.json()).then(s);let e=document.querySelector("ul.gallery.store-feed");if(!e)return;function o(t){let n=document.querySelector("footer ul.store-feed");e=document.querySelector("ul.gallery.store-feed"),items=t.slice(0,4).map(e=>{let t=`https://tiendah.bigcartel.com/${e.url}`;return`
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
            </li>`}),n.innerHTML=items.join(''),e&&(e.innerHTML=items.join(''))}fetch("https://api.bigcartel.com/tiendah/products.json").then(e=>e.json()).then(o);let n=document.getElementsByTagName("button")[0],t=n.parentElement;n.addEventListener("click",()=>{if(t.className===''){t.className="toggled";return}t.className=''})})
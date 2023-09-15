document.addEventListener("DOMContentLoaded",()=>{function t(e){e.style.transition="opacity 2s",e.style.opacity="1"}function s(){const e=document.getElementsByTagName("img");for(let n of e)n.complete&&t(n),n.addEventListener("load",()=>{t(n)})}function r(e){const t=document.querySelectorAll("ul.ig-feed"),n=e.slice(0,12).map(e=>`
          <li class="item">
            <a class="thumbnail" href="${e.permalink}">
              <img src="${e.media_url}" />
            </a>
          </li>`).join("");t.forEach(e=>e.innerHTML=n)}function c(){return fetch("https://mikeball.info/ig-feed/feeds/instagram-media.json").then(e=>e.json()).then(r)}function o(e){const t=document.querySelectorAll("ul.store-feed"),n=e.slice(0,4).map(e=>{const t=`https://tiendah.bigcartel.com/${e.url}`;return`
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
          </li>`}).join("");t.forEach(e=>e.innerHTML=n)}function i(){return fetch("https://api.bigcartel.com/tiendah/products.json").then(e=>e.json()).then(o)}function a(e){const t=document.querySelectorAll("ul.gh-feed"),n=e.map(e=>`
          <li class="item">
            <a href="${e.url}">
              ${e.repo}
            </a>
          </li>`).join("");t.forEach(e=>e.innerHTML=n)}function l(){return fetch("https://mikeball.info/ig-feed/feeds/github-contributions.json").then(e=>e.json()).then(a)}Promise.all([c(),i()]).then(s);const n=document.getElementsByTagName("button")[0],e=n.parentElement;n.addEventListener("click",()=>{if(e.className===""){e.className="toggled";return}e.className=""})})
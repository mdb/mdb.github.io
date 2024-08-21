document.addEventListener("DOMContentLoaded",()=>{function t(e){e.style.transition="opacity 2s",e.style.opacity="1"}function n(){const e=document.getElementsByTagName("img");for(let n of e)n.complete&&t(n),n.addEventListener("load",()=>{t(n)})}function i(e){const t=document.querySelectorAll("ul.ig-feed");return t.forEach((t,n)=>{const s=e.data.map(e=>{const t=`ig-${n}-${e.id}`;return`
            <li class="item">
              <a class="thumbnail" href="#${t}">
                <img src="${e.github_media_url}" />
              </a>
              <a href="#/" id="${t}" class="overlay">
                <div class="image">
                  <img src="${e.github_media_url}" />
                </div>
              </a>
            </li>`}).join("");t.innerHTML=t.innerHTML+s}),e}function l(e){const i="button#load-more",s=document.querySelector("body.instagram main");let t=document.querySelector(i);if(!s)return!1;if(t&&t.remove(),e.paging.next&&e.paging.next.includes("-6.json"))return!1;s.innerHTML=`${s.innerHTML}<button id="load-more">Load more</button>`,t=document.querySelector(i);const a="url";t.setAttribute(a,e.paging.next),t.addEventListener("click",e=>{e.stopPropagation();const t=new URL(e.target.getAttribute(a));o(`${t.protocol}//mikeball.info/${t.pathname}`).then(n)})}function o(e){return e=e||"https://mikeball.info/feeder/feeds/instagram-media-0.json",fetch(e).then(e=>e.json()).then(i).then(l)}function a(e){const t=document.querySelectorAll("ul.store-feed"),n=e.slice(0,4).map(e=>{const t=`https://tiendah.bigcartel.com/${e.url}`;return`
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
          </li>`}).join("");t.forEach(e=>e.innerHTML=e.innerHTML+n)}function r(){return fetch("https://api.bigcartel.com/tiendah/products.json").then(e=>e.json()).then(a)}function c(e){const t=document.querySelectorAll("ul.gh-feed"),n=e.map(e=>`
          <li class="item">
            <a href="${e.url}">
              ${e.repo}
            </a>
          </li>`).join("");t.forEach(e=>e.innerHTML=n)}function d(){return fetch("https://mikeball.info/feeder/feeds/github-contributions.json").then(e=>e.json()).then(c)}Promise.all([o(),r()]).then(n);const s=document.getElementsByTagName("button")[0],e=s.parentElement;s.addEventListener("click",()=>{if(e.className===""){e.className="toggled";return}e.className=""})})
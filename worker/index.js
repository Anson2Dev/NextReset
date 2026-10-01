import productScreenshot from '../website/product-2026-10-01.png';
import home from '../website/index.html';
import notFound from '../website/404.html';
import css from '../website/style.css';
import copyScript from '../website/copy.js';
import robots from '../website/robots.txt';
import sitemap from '../website/sitemap.xml';

// Bundle the static website and its product screenshot.
const pages = new Map([
  ['/product-2026-10-01.png', [productScreenshot, 'image/png']],
  ['/', [home, 'text/html']],
  ['/style.css', [css, 'text/css']],
  ['/copy.js', [copyScript, 'text/javascript']],
  ['/robots.txt', [robots, 'text/plain']],
  ['/sitemap.xml', [sitemap, 'application/xml']],
]);

export default {
  fetch(request) {
    const headers = {
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Content-Security-Policy': "default-src 'self'; style-src 'self'; img-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
    };
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', {status: 405, headers: {...headers, Allow: 'GET, HEAD'}});
    }
    const url = new URL(request.url);
    if (url.pathname === '/index.html') {
      url.pathname = '/';
      return new Response(null, {status: 301, headers: {...headers, Location: url.href}});
    }
    const page = pages.get(url.pathname);
    const [body, type] = page ?? [notFound, 'text/html'];
    return new Response(request.method === 'HEAD' ? null : body, {
      status: page ? 200 : 404,
      headers: {...headers, 'Content-Type': type.startsWith('image/') ? type : `${type}; charset=utf-8`, 'Cache-Control': 'public, max-age=300'},
    });
  },
};

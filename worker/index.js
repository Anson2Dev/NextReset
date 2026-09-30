import home from '../website/index.html';
import notFound from '../website/404.html';
import css from '../website/style.css';
import robots from '../website/robots.txt';
import sitemap from '../website/sitemap.xml';

// The site is static. Bundling these small text files also supports direct API deployments.
const pages = new Map([
  ['/', [home, 'text/html']],
  ['/style.css', [css, 'text/css']],
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
      headers: {...headers, 'Content-Type': `${type}; charset=utf-8`, 'Cache-Control': 'public, max-age=300'},
    });
  },
};

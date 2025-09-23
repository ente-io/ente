/** Proxy requests for Stadia Maps tiles and geocoding. */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Handle tiles requests
    const tileMatch = url.pathname.match(/^\/tiles\/([^\/]+)\/(\d+)\/(\d+)\/(\d+)(@2x)?\.(\w+)$/);
    if (tileMatch) {
      const [, style, z, x, y, retina, format] = tileMatch;
      const stadiaUrl = `https://tiles.stadiamaps.com/tiles/${style}/${z}/${x}/${y}${retina || ''}.${format}?api_key=${env.STADIA_API_KEY}`;

      const response = await fetch(stadiaUrl);

      return new Response(response.body, {
        status: response.status,
        headers: {
          ...Object.fromEntries(response.headers),
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=86400',
        }
      });
    }

  // Handle geocoding requests
  const geocodingMatch = url.pathname.match(/^\/geocoding\/(.+)$/);
  if (geocodingMatch) {
    const path = geocodingMatch[1];
    const stadiaUrl = `https://api.stadiamaps.com/geocoding/${path}?${url.searchParams.toString()}&api_key=${env.STADIA_API_KEY}`;

    const response = await fetch(stadiaUrl);
    const data = await response.text();

    return new Response(data, {
      status: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      }
    });
  }

    return new Response('Not found', { status: 404 });
  }
};
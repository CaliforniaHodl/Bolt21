// Cloudflare Pages Function for GitHub OAuth callback

export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const code = url.searchParams.get('code');
  
  if (!code) {
    return new Response('Missing code parameter', { status: 400 });
  }
  
  // Exchange code for access token
  const tokenResponse = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      client_id: env.GITHUB_CLIENT_ID,
      client_secret: env.GITHUB_CLIENT_SECRET,
      code: code,
    }),
  });
  
  const tokenData = await tokenResponse.json();
  
  if (tokenData.error) {
    return new Response(`OAuth error: ${tokenData.error_description}`, { status: 400 });
  }
  
  // Return HTML that posts the token back to Decap CMS
  const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Authorizing...</title>
</head>
<body>
  <script>
    (function() {
      const token = "${tokenData.access_token}";
      const provider = "github";
      
      // Post message to parent window (Decap CMS)
      if (window.opener) {
        window.opener.postMessage(
          'authorization:' + provider + ':success:' + JSON.stringify({ token: token, provider: provider }),
          window.location.origin
        );
        window.close();
      }
    })();
  </script>
  <p>Authorizing, please wait...</p>
</body>
</html>
  `;
  
  return new Response(html, {
    headers: { 'Content-Type': 'text/html' },
  });
}

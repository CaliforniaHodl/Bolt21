// Cloudflare Pages Function for Decap CMS GitHub OAuth
// Environment variables needed:
// - GITHUB_CLIENT_ID
// - GITHUB_CLIENT_SECRET

export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  
  // Redirect to GitHub OAuth
  const clientId = env.GITHUB_CLIENT_ID;
  const redirectUri = `${url.origin}/api/callback`;
  const scope = 'repo,user';
  
  const authUrl = `https://github.com/login/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scope}`;
  
  return Response.redirect(authUrl, 302);
}

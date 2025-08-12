---
title: General troubleshooting cases - Self-hosting
description: Fixing various errors when trying to self host Ente
---

# Troubleshooting

## Functionality not working on self hosted instance

If some specific functionality (e.g. album listing, video playback) does not
work on your self hosted instance, it is possible that you have set _some_, but
not _all_ needed CSP headers (by default, CSP is not enabled).

To expand on it - by default, currently the generated build does not enable CSP
headers. The generated build includes a \_headers file that Cloudflare will use
to set HTTP response headers, but even these do not enable CSP, it is set to a
report only mode.

However, your web server might be setting some CSP policy. If so, then you will
need to ensure that all necessary CSP headers are set.

You can see the current
[\_headers](https://github.com/ente-io/ente/blob/main/web/apps/photos/public/_headers)
file contents to use a template for your CSP policy. The
`Content-Security-Policy-Report-Only` value will show you the CSP headers in
"dry run" report-only mode we're setting - you can use that as a template,
tweaking it as per your setup.

How do you know if this is the problem you're facing? The browser console
_might_ be giving you errors when you try to open the page and perform the
corresponding function.

> Refused to load https://subdomain.example.org/... because it does not appear
> in the script-src directive of the Content Security Policy.

This is not guaranteed, each browsers handles CSP errors differently, and some
may silently swallow it.

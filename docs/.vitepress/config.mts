import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Ente Photos Help",
  description: "Ente Product Documentation",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Photos', link: '/photos/index' },
      { text: 'Authenticator', link: '/authenticator/index' }
    ],

    sidebar: {
      '/': sidebarphotos(),
      '/photos/': sidebarphotos(),
      '/common/': sidebarphotos(),
      '/authenticator/': sidebarAuth()
  },


    socialLinks: [
      { icon: 'github', link: 'https://github.com/ente-io/' }
    ]
  }
})

function sidebarphotos() {
  return [
    {
      text: 'Examples',
      items: [
        { text: 'Markdown Examples', link: '/markdown-examples' },
        { text: 'Runtime API Examples', link: '/api-examples' }
      ]
    },
    {
      text: 'User Guide',
      items: [
           {
              text: 'Features',
              collapsed: true,
              // link: '/photos/features/',
              items: [
                  { text: 'Archive', link: '/photos/features/archive' },
                  { text: 'Hidden', link: '/photos/features/hidden' },
                  { text: 'Family Plan', link: '/photos/features/family-plan' },
                  { text: 'Map', link: '/photos/features/map' },
                  { text: 'Location Tags', link: '/photos/features/location' },
                  { text: 'Collect Photos', link: '/photos/features/collect' },
                  { text: 'Public link', link: '/photos/features/public-link' },
                  { text: 'Quick link', link: '/photos/features/quick-link' },
                  { text: 'Referral Plan', link: '/photos/features/referral' },
                  { text: 'Live & Motion Photos', link: '/photos/features/live-photos' },

              ]
          },
        ]
    },
  ]
}

function sidebarAuth() {
  return [
    {
      text: 'Examples',
      items: [
        { text: 'Markdown Examples', link: '/markdown-examples' },
        { text: 'Runtime API Examples', link: '/api-examples' }
      ]
    }
  ]
}
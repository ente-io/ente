import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Ente Docs",
  description: "Guide for ente.io apps",
  themeConfig: {
    editLink: {
      pattern: 'https://github.com/ente-io/docs/edit/main/docs/:path'
    },
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Photos', link: '/photos/index' },
      { text: 'Authenticator', link: '/authenticator/index' }
    ],

    sidebar: {
      '/': sidebarPhotos(),
      '/photos/': sidebarPhotos(),
      '/common/': sidebarPhotos(),
      '/authenticator/': sidebarAuth()
  },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ente-io/docs/' }
    ]
  }
})

function sidebarPhotos() {
  return [
    {
      text: 'Troubleshoot',
      collapsed: true,
      link: '/photos/troubleshooting/files-not-uploading',
      items: [
        { text: 'Files not uploading', link: '/photos/troubleshooting/files-not-uploading' },
        { text: 'Failed to play video', link: '/photos/troubleshooting/video-not-playing' },
        { text: 'Report bug', link: '/photos/troubleshooting/report-bug' },
      ]
    },
    {
      text: 'User Guide',
      items: [
           {
              text: 'Features',
              collapsed: true,
              items: [
                  { text: 'Family Plan', link: '/photos/features/family-plan' },
                  { text: 'Albums', link: '/photos/features/albums' },
                  { text: 'Archive', link: '/photos/features/archive' },
                  { text: 'Hidden', link: '/photos/features/hidden' },
                  { text: 'Map', link: '/photos/features/map' },
                  { text: 'Location Tags', link: '/photos/features/location' },
                  { text: 'Collect Photos', link: '/photos/features/collect' },
                  { text: 'Public links', link: '/photos/features/public-links' },
                  { text: 'Quick link', link: '/photos/features/quick-link' },
                  { text: 'Watch folder', link: '/photos/features/watch-folder' },
                  { text: 'Trash', link: '/photos/features/trash' },
                  { text: 'Uncategorized', link: '/photos/features/uncategorized' },
                  { text: 'Referral Plan', link: '/photos/features/referral' },
                  { text: 'Live & Motion Photos', link: '/photos/features/live-photos' },
              ]
          },
          {
            text: 'Import',
            collapsed: true,
            link: '/photos/import/index',
            items: [
                { text: 'Watch folder', link: '/photos/features/watch-folder' },
                
            ]
        },
        ]
    },
  ]
}

function sidebarAuth() {
  return [
    {
      text: 'FAQ',
      link: '/authenticator/faq/faq',
      
    },
    {
      text: 'Contribute',
      link: '/authenticator/support/contribute'
  
      
    }
  ]
}
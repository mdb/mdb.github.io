module.exports = {
  siteMetadata: {
    title: 'Mike Ball',
    author: 'Mike Ball',
    description: 'Recent projects, blog, and information',
    siteUrl: 'http://mikeball.info',
  },
  plugins: [
    `gatsby-transformer-sharp`,
    `gatsby-plugin-sharp`,
    {
      resolve: `gatsby-source-filesystem`,
      options: {
        path: `${__dirname}/content`,
        name: `content`,
      },
    },
    {
      resolve: `gatsby-source-filesystem`,
      options: {
        path: `${__dirname}/content/assets`,
        name: `assets`,
      },
    },
    {
      resolve: `gatsby-transformer-remark`,
      options: {
        plugins: [
          {
            resolve: `gatsby-remark-images`,
            options: {
              maxWidth: 590,
            },
          },
          {
            resolve: `gatsby-remark-responsive-iframe`,
            options: {
              wrapperStyle: `margin-bottom: 1.0725rem`,
            },
          },
          `gatsby-remark-prismjs`,
          `gatsby-remark-copy-linked-files`,
          `gatsby-remark-smartypants`,
        ],
      },
    },
    {
      resolve: `gatsby-plugin-google-analytics`,
      options: {
        //trackingId: `ADD YOUR TRACKING ID HERE`,
      },
    },
    {
      resolve: `gatsby-plugin-feed`,
      options: {
        feeds: [{
          output: '/rss.xml',
          query: `
            {
              allMarkdownRemark(
                filter: {
                  frontmatter: {
                    published: { ne: false }
                  },
                  fields: {
                    slug: { glob: "/blog/*" }
                  }
                },
                sort: { fields: [frontmatter___date], order: DESC }
              ) {
                edges {
                  node {
                    excerpt
                    fields {
                      slug
                    }
                    frontmatter {
                      date(formatString: "MMMM DD, YYYY")
                      title
                      teaser
                      tags
                    }
                  }
                }
              }
            }
          `
        }]
      }
    },
    {
      resolve: `gatsby-plugin-manifest`,
      options: {
        name: `mikeball.info`,
        short_name: `mikeball.info`,
        start_url: `/`,
        background_color: `#ffffff`,
        theme_color: `#663399`,
        display: `minimal-ui`,
      }
    },
    `gatsby-plugin-react-helmet`,
    {
      resolve: `gatsby-plugin-typography`,
      options: {
        pathToConfigModule: `src/utils/typography`,
      },
    },
  ],
}

// TODO: build out 404
import React from 'react'
import { graphql } from 'gatsby'
import Layout from '../components/layout'

class NotFound extends React.Component {
  render() {
    const { data } = this.props
    const siteTitle = data.site.siteMetadata.title

    return (
      <Layout title={siteTitle}>
      <h1>Not found</h1>
      </Layout>
    )
  }
}

export default NotFound

export const pageQuery = graphql`
  query {
    site {
      siteMetadata {
        title
      }
    }
    posts: allMarkdownRemark(
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
            title
            teaser
            tags
            thumbnail {
              childImageSharp {
                fluid {
                  ...GatsbyImageSharpFluid
                }
              }
            }
          }
        }
      }
    }
    projects: allMarkdownRemark(
      filter: {
        frontmatter: {
          published: { ne: false }
        },
        fields: {
          slug: { glob: "/projects/*" }
        }
      },
      sort: { fields: [frontmatter___date], order: DESC },
    ) {
      edges {
        node {
          excerpt
          fields {
            slug
          }
          frontmatter {
            title
            tags
            thumbnail {
              childImageSharp {
                fluid(maxWidth: 800) {
                  ...GatsbyImageSharpFluid
                }
              }
            }
          }
        }
      }
    }
  }
`

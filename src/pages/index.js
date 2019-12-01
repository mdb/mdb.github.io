import React from 'react'
import { graphql } from 'gatsby'
import Layout from '../components/layout'
import ProductList from '../components/product-list'
import Instagram from '../components/instagram'
import BlogPostList from '../components/blog-post-list'
import ProjectList from '../components/project-list'

class Index extends React.Component {
  render() {
    const { data } = this.props
    const siteTitle = data.site.siteMetadata.title

    return (
      <Layout title={siteTitle}>
        <Instagram />
        <ProductList />
        <BlogPostList posts={data.posts.edges} />
        <ProjectList projects={data.projects.edges} />
      </Layout>
    )
  }
}

export default Index

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
      sort: { fields: [frontmatter___date], order: DESC },
      limit: 4
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
      limit: 4
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

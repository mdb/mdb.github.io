import React from 'react'
import { graphql } from 'gatsby'
import Layout from '../components/layout'
import ProjectList from '../components/project-list'

const ProjectsIndex = ({ pageContext, data }) => {
  return (
    <Layout location={data.location} title={data.site.siteMetadata.title}>
      <ProjectList projects={data.projects.edges} />
    </Layout>
  )
}

export default ProjectsIndex

export const pageQuery = graphql`
  query {
    site {
      siteMetadata {
        title
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

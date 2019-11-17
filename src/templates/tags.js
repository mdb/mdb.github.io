import React from 'react'
import { Link, graphql } from 'gatsby'
import Layout from '../components/layout'

const Tags = ({ pageContext, data }) => {
  const { tag, allTagsUrl } = pageContext
  const { edges, totalCount } = data.allMarkdownRemark
  const descriptor = allTagsUrl && allTagsUrl.includes('blog') ? 'blog post' : 'project'
  const pathPrefix = allTagsUrl && allTagsUrl.includes('blog') ? '/blog' : '/projects'

  const tagHeader = `${totalCount} ${descriptor}${
    totalCount === 1 ? "" : "s"
  } tagged with "${tag}"`

  return (
    <Layout title={data.site.siteMetadata.title}>
      <h1>{tagHeader}</h1>
      <ul>
        {edges.map(({ node }) => {
          const { slug } = node.fields
          const { title } = node.frontmatter

          return (
            <li key={slug}>
              <Link to={`${pathPrefix}${slug}`}>{title}</Link>
            </li>
          )
        })}
      </ul>
      <Link to={allTagsUrl}>All tags</Link>
    </Layout>
  )
}

export default Tags

export const pageQuery = graphql`
  query($tag: String, $glob: String) {
    site {
      siteMetadata {
        title
      }
    }
    allMarkdownRemark(
      limit: 2000
      sort: { fields: [frontmatter___date], order: DESC }
      filter: {
        frontmatter: {
          tags: { in: [$tag] }
          published: { ne: false }
        }
        fields: {
          slug: { glob: $glob }
        }
      }
    ) {
      totalCount
      edges {
        node {
          fields {
            slug
          }
          frontmatter {
            title
          }
        }
      }
    }
  }
`

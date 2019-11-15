import React from 'react'
import { graphql, Link } from 'gatsby'
import Layout from '../components/layout'

const TagsIndex = ({ pageContext, data }) => {
  const pathPrefix = pageContext.glob.includes('blog') ? '/blog' : '/projects'

  return (
    <Layout title={data.site.siteMetadata.title}>
      <ul>
        {pageContext.tags.map(tag => (
          <li key={tag.fieldValue}>
            <Link to={`${pathPrefix}/tags/${tag.fieldValue}/`}>
              {tag.fieldValue} ({tag.totalCount})
            </Link>
          </li>
        ))}
      </ul>
    </Layout>
  )
}

export default TagsIndex

export const pageQuery = graphql`
  query {
    site {
      siteMetadata {
        title
      }
    }
  }
`

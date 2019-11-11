import React from 'react'
import { Link } from 'gatsby'
import Img from 'gatsby-image'
import { rhythm } from '../utils/typography'

class ProjectList extends React.Component {
  render() {
    return (
      <div>
        {this.props.projects.map(({ node }) => {
          const title = node.frontmatter.title || node.fields.slug

          return (
            <article key={node.fields.slug}>
              <header>
                <h3
                  style={{
                    marginBottom: rhythm(1 / 4),
                  }}
                >
                  <Link style={{ boxShadow: `none` }} to={node.fields.slug}>
                    {title}
                  </Link>
                </h3>
                <small>{node.frontmatter.date}</small>
                <Img fluid={node.frontmatter.thumbnail.childImageSharp.fluid} />
              </header>
            </article>
          )
        })}
      </div>
    )
  }
}

export default ProjectList

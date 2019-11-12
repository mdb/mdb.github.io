import React from 'react'
import { Link } from 'gatsby'
import { rhythm } from '../utils/typography'
import Thumbnail from './thumbnail'

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
                <Thumbnail fields={node.fields} frontmatter={node.frontmatter} />
              </header>
            </article>
          )
        })}
      </div>
    )
  }
}

export default ProjectList

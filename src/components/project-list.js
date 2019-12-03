import React from 'react'
import { Link } from 'gatsby'
import { rhythm, secondaryColor, secondaryFont } from '../utils/typography'
import TagList from './tag-list'
import Thumbnail from './thumbnail'
import styles from './project-list.module.css'

class ProjectList extends React.Component {
  render() {
    return (
      <div className={styles.gallery}>
        {this.props.projects.map(({ node }) => {
          const title = node.frontmatter.title || node.fields.slug

          return (
            <article key={node.fields.slug}>
              <Thumbnail fields={node.fields} frontmatter={node.frontmatter} />
              <header>
                <small
                  style={{
                    fontSize: rhythm(3/7),
                    marginBottom: rhythm(1/3),
                    marginTop: rhythm(1/2),
                    color: secondaryColor,
                    fontFamily: secondaryFont
                  }}
                >Project</small>
                <h3
                  style={{
                    fontSize: rhythm(4/7),
                    marginBottom: rhythm(1/3),
                  }}
                >
                  <Link style={{ boxShadow: `none` }} to={node.fields.slug}>
                    {title}
                  </Link>
                </h3>
                <TagList tags={node.frontmatter.tags} />
              </header>
            </article>
          )
        })}
      </div>
    )
  }
}

export default ProjectList

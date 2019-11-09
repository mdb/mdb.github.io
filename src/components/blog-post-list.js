import React from 'react'
import { Link } from 'gatsby'
import { rhythm } from '../utils/typography'
import TagList from './tag-list'

class BlogPostList extends React.Component {
  render() {
    return (
      <div>
        {this.props.posts.map(({ node }) => {
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
                <TagList tags={node.frontmatter.tags} />
              </header>
              <section>
                <p>{node.frontmatter.teaser}</p>
              </section>
            </article>
          )
        })}
      </div>
    )
  }
}

export default BlogPostList

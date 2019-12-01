import React from 'react'
import { Link } from 'gatsby'
import TagList from './tag-list'
import Thumbnail from './thumbnail'

class BlogPostList extends React.Component {
  render() {
    return (
      <div>
        {this.props.posts.map(({ node }) => {
          const title = node.frontmatter.title || node.fields.slug

          return (
            <article key={node.fields.slug}>
              <small>{node.frontmatter.date}</small>
              <Thumbnail fields={node.fields} frontmatter={node.frontmatter} />
              <header>
                <h3>
                  <Link to={node.fields.slug}>
                    {title}
                  </Link>
                </h3>
                <p>{node.frontmatter.teaser}</p>
                <TagList tags={node.frontmatter.tags} />
              </header>
            </article>
          )
        })}
      </div>
    )
  }
}

export default BlogPostList

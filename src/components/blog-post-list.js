import React from 'react'
import { Link } from 'gatsby'
import TagList from './tag-list'
import Thumbnail from './thumbnail'
import styles from './blog-post-list.module.css'
import { rhythm, secondaryColor, secondaryFont } from '../utils/typography'

class BlogPostList extends React.Component {
  render() {
    return (
      <div className={styles.gallery}>
        {this.props.posts.map(({ node }) => {
          const title = node.frontmatter.title || node.fields.slug

          return (
            <article key={node.fields.slug}>
              <Thumbnail fields={node.fields} frontmatter={node.frontmatter} />
              <header>
                <small
                  style={{
                    fontSize: rhythm(2/5),
                    marginBottom: rhythm(1/3),
                    marginTop: rhythm(1/2),
                    color: secondaryColor,
                    fontFamily: secondaryFont
                  }}
                >{node.frontmatter.date}</small>
                <h3
                  style={{
                    fontSize: rhythm(4/7),
                    marginBottom: rhythm(1/3),
                  }}
                >
                  <Link to={node.fields.slug}>
                    {title}
                  </Link>
                </h3>
                <p
                  style={{
                    fontSize: rhythm(1/2),
                    marginBottom: rhythm(1/3),
                    color: secondaryColor
                  }}
                >{node.frontmatter.teaser}</p>
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

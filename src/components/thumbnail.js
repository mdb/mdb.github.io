import React from 'react'
import { Link } from 'gatsby'
import Img from 'gatsby-image'

class Thumbnail extends React.Component {
  render() {
    return (
      <div>
        <Link to={this.props.fields.slug}>
          <Img fluid={this.props.frontmatter.thumbnail.childImageSharp.fluid} />
        </Link>
      </div>
    )
  }
}

export default Thumbnail

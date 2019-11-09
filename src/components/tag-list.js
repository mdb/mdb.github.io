import React from 'react'
import { Link } from 'gatsby'

class TagList extends React.Component {
  render() {
    return (
      <ul>
        {this.props.tags.map(tag => {
          return(
            <li key={tag}>
              <Link to={`/tags/${tag}`}>
                {tag}
              </Link>
            </li>
          )
        })}
      </ul>
    )
  }
}

export default TagList

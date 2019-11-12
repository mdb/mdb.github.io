import React from 'react'
import { Link } from 'gatsby'
import tagStyles from './tag-list.module.css'

class TagList extends React.Component {
  render() {
    return (
      <ul className={tagStyles.tags}>
        {this.props.tags.map(tag => {
          return(
            <li className={tagStyles.tag} key={tag}>
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

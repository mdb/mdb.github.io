import React from 'react'
import ExternalThumbnail from './external-thumbnail'
import styles from './instagram.module.css'

class Instagram extends React.Component {
  itemStyles() {
    return this.props.igLoaded ? styles.loaded : styles.loading
  }

  render() {
    const items = this.props.igItems

    return (
      <ul className={styles.gallery}>
        {items.map((item, i) => {
          const text = item.caption ? item.caption.text : ''

          return (
            <li className={this.itemStyles()} key={item.link + '-' + i}>
              <ExternalThumbnail link={item.link} alt={text} imageUrl={item.images.standard_resolution.url} />
            </li>
          )
        })}
      </ul>
    )
  }
}

export default Instagram

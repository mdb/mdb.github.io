import React from 'react'
import ExternalThumbnail from './external-thumbnail'
import styles from './instagram.module.css'

class Instagram extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      loaded: false,
      items: new Array(8).fill().map(x => ({
        caption: 'loading',
        link: '/',
        images: {
          standard_resolution: {
            url: '/loading_indicator.gif'
          }
        }
      }))
    }
  }

  componentDidMount() {
    fetch('https://clapclapexcitement-gram.herokuapp.com/recent-media')
      .then(res => res.json())
      .then(result => {
        this.setState({
          loaded: true,
          items: result
        })
      })
  }

  itemStyles() {
    return this.state.loaded ? styles.loaded : styles.loading
  }

  render() {
    const { items } = this.state

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

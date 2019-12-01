import React from 'react'
import ExternalThumbnail from './external-thumbnail'
import instagramStyles from './instagram.module.css'

class Instagram extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      items: []
    }
  }

  componentDidMount() {
    fetch('https://clapclapexcitement-gram.herokuapp.com/recent-media')
      .then(res => res.json())
      .then(result => {
        this.setState({ items: result })
      })
  }

  render() {
    const { items } = this.state

    if (!items.length) {
      return ''
    }

    return (
      <ul className={instagramStyles.gallery}>
        {items.map(item => {
          const text = item.caption ? item.caption.text : ''

          return (
            <li key={item.link}>
              <ExternalThumbnail link={item.link} alt={text} imageUrl={item.images.standard_resolution.url} />
            </li>
          )
        })}
      </ul>
    )
  }
}

export default Instagram

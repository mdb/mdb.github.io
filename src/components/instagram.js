import React from 'react'

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
      <ul>
        {items.map(item => {
          const text = item.caption ? item.caption.text : ''

          return(
            <li>
              <a href={item.link}>
                <img alt={text} src={item.images.standard_resolution.url} />
              </a>
            </li>
          )
        })}
      </ul>
    )
  }
}

export default Instagram

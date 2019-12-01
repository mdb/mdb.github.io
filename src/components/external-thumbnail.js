import React from 'react'

class ExternalThumbnail extends React.Component {
  render() {
    return (
      <div>
        <a href={this.props.link}>
          <img alt={this.props.alt} src={this.props.imageUrl} />
        </a>
      </div>
    )
  }
}

export default ExternalThumbnail

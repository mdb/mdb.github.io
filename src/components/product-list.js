import React from 'react'
import ExternalThumbnail from './external-thumbnail'
import productListStyles from './product-list.module.css'

class ProductList extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      products: []
    }
  }

  componentDidMount() {
    fetch('https://api.bigcartel.com/tiendah/products.json')
      .then(res => res.json())
      .then(result => {
        this.setState({ products: result })
      })
  }

  render() {
    const { products } = this.state

    if (!products.length) {
      return ''
    }

    return (
      <ul className={productListStyles.gallery}>
        {products.map(prod => {
          const link = `https://tiendah.bigcartel.com/product/${prod.permalink}`

          return(
            <li key={prod.permalink}>
              <ExternalThumbnail link={link} alt={prod.name} imageUrl={prod.images[0].url} />
              <div className="details">
                <h2><a href={link}>{prod.name}</a></h2>
                <p>{prod.description}</p>
              </div>
            </li>
          )
        })}
      </ul>
    )
  }
}

export default ProductList

import React from 'react'
import { Link } from 'gatsby'
import layoutStyles from './layout.module.css'

class Layout extends React.Component {
  render() {
    const { title, children } = this.props

    return (
      <div className={layoutStyles.layout}>
        <header>
          <h1>
            <Link to={`/`}>
              {title}
            </Link>
          </h1>
        </header>
        <main>{children}</main>
        <footer>
        </footer>
      </div>
    )
  }
}

export default Layout

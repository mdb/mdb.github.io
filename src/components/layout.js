import React from 'react'
import { Link } from 'gatsby'
import layoutStyles from './layout.module.css'

class Layout extends React.Component {
  render() {
    const { children } = this.props

    return (
      <div>
        <header className={layoutStyles.header}>
          <h1 className={layoutStyles.mark}>
            <Link to={`/`}>
              Mike Ball
            </Link>
          </h1>
        </header>
        <main className={layoutStyles.main}>{children}</main>
        <footer className={layoutStyles.footer}>
          <section>
            <h2>Mike Ball</h2>
            <p>I live in Philadelphia and work as a multi-disciplinary software developer and designer.</p>
            <p>I am especially excited to work with journalists, artists, and nonprofits. I like to work in JavaScript, Ruby, Golang, new technologies, and on open source projects. Interested in working with me? Get in touch.</p>
          </section>
        </footer>
      </div>
    )
  }
}

export default Layout

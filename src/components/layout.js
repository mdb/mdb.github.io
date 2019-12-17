import React from 'react'
import { Link } from 'gatsby'
import styles from './layout.module.css'
import Instagram from '../components/instagram'

class Layout extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      loaded: false,
      igItems: new Array(8).fill().map(x => ({
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
          igItems: result
        })
      })
  }

  childrenWithProps() {
    return React.Children.map(this.props.children, (child, i) => {
      return React.cloneElement(child, {
        igItems: this.state.igItems,
        igLoaded: this.state.loaded
      })
    })
  }

  render() {
    const { title } = this.props

    return (
      <div>
        <header className={styles.header}>
          <h1 className={styles.mark}>
            <Link to={`/`}>
              {title}
            </Link>
          </h1>
        </header>
        <main className={styles.main}>{this.childrenWithProps()}</main>
        <footer className={styles.footer}>
          <section>
            <div className={styles.quarterColumn}>
              <h2>{title}</h2>
              <p>I live in Philadelphia and work as a multi-disciplinary software developer and graphic artist.</p>
              <p>I am especially excited to work with artists, journalists, and organizations with big ideas. I like to work on collaborative teams leveraging cloud native technologies, and on open source projects. Interested in working with me? Get in touch.</p>
            </div>
            <div className={styles.halfColumn}>
              <h2>Instagram</h2>
              <Instagram igItems={this.state.igItems} igLoaded={this.state.loaded} />
            </div>
            <div className={styles.quarterColumn}>
              <h2>Etc.</h2>
              <ul>
                <li>
                  <a href='TODO'>Resume</a>
                </li>
                <li>
                  <a href='http://github.com/mdb'>GitHub</a>
                </li>
                <li>
                  <a href='https://instagram.com/clapclapexcitement'>Instagram</a>
                </li>
                <li>
                  <a href='http://twitter.com/clapexcitement'>Twitter</a>
                </li>
                <li>
                  <a href='https://www.linkedin.com/in/mikedball/'>LinkedIn</a>
                </li>
                <li>
                  <a href='/rss.xml'>RSS Feed</a>
                </li>
              </ul>
            </div>
          </section>
        </footer>
      </div>
    )
  }
}

export default Layout

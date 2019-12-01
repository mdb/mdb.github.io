const path = require('path')
const { createFilePath } = require('gatsby-source-filesystem')

exports.createPages = async ({ graphql, actions }) => {
  const { createPage } = actions
  const tagTemplate = path.resolve(`./src/templates/tags.js`)
  const tagsIndexTemplate = path.resolve(`./src/templates/tags-index.js`)
  const blogIndexTemplate = path.resolve(`./src/templates/blog-index.js`)
  const blogPostTemplate = path.resolve(`./src/templates/blog-post.js`)
  const projectsIndexTemplate = path.resolve(`./src/templates/projects-index.js`)
  const projectTemplate = path.resolve(`./src/templates/project.js`)
  const result = await graphql(`
    {
      postsRemark: allMarkdownRemark(
        filter: {
          fields: {
            slug: { glob: "/blog/*" }
          }
        }
        sort: { fields: [frontmatter___date], order: DESC }
        limit: 1000
      ) {
        edges {
          node {
            fields {
              slug
            }
            frontmatter {
              title
            }
          }
        }
      }

      projectsRemark: allMarkdownRemark(
        filter: {
          fields: {
            slug: { glob: "/projects/*" }
          }
        }
        sort: { fields: [frontmatter___date], order: DESC }
        limit: 1000
      ) {
        edges {
          node {
            fields {
              slug
            }
            frontmatter {
              title
            }
          }
        }
      }

      tagsGroup: allMarkdownRemark(limit: 2000) {
        group(field: frontmatter___tags) {
          fieldValue
          totalCount
        }
      }

      blogTagsGroup: allMarkdownRemark(
        limit: 2000,
        filter: {
          fields: {
            slug: { glob: "/blog/*" }
          }
        }
      ) {
        group(field: frontmatter___tags) {
          fieldValue
          totalCount
        }
      }

      projectTagsGroup: allMarkdownRemark(
        limit: 2000,
        filter: {
          fields: {
            slug: { glob: "/projects/*" }
          }
        }
      ) {
        group(field: frontmatter___tags) {
          fieldValue
          totalCount
        }
      }
    }
  `)

  if (result.errors) {
    throw result.errors
  }

  const postsIndex = result.data.postsRemark.edges
  createPage({
    path: `/blog`,
    component: blogIndexTemplate,
    context: {
      posts: postsIndex
    }
  })

  const posts = result.data.postsRemark.edges
  posts.forEach((post, index) => {
    const previous = index === posts.length - 1 ? null : posts[index + 1].node
    const next = index === 0 ? null : posts[index - 1].node

    createPage({
      path: post.node.fields.slug,
      component: blogPostTemplate,
      context: {
        slug: post.node.fields.slug,
        previous,
        next,
      },
    })
  })

  const projectsIndex = result.data.projectsRemark.edges
  createPage({
    path: `/projects`,
    component: projectsIndexTemplate,
    context: {
      posts: projectsIndex
    }
  })

  const projects = result.data.projectsRemark.edges
  projects.forEach((proj, index) => {
    const previous = index === projects.length - 1 ? null : projects[index + 1].node
    const next = index === 0 ? null : projects[index - 1].node

    createPage({
      path: proj.node.fields.slug,
      component: projectTemplate,
      context: {
        slug: proj.node.fields.slug,
        previous,
        next,
      },
    })
  })

  const tags = result.data.tagsGroup.group
  tags.forEach(tag => {
    createPage({
      path: `/tags/${tag.fieldValue}/`,
      component: tagTemplate,
      context: {
        tag: tag.fieldValue,
      },
    })
  })

  createPage({
    path: `/blog/tags`,
    component: tagsIndexTemplate,
    context: {
      tags: result.data.blogTagsGroup.group,
      glob: '/blog/*'
    }
  })

  const blogTags = result.data.blogTagsGroup.group
  blogTags.forEach(tag => {
    createPage({
      path: `/blog/tags/${tag.fieldValue}/`,
      component: tagTemplate,
      context: {
        tag: tag.fieldValue,
        glob: '/blog/*',
        allTagsUrl: '/blog/tags'
      },
    })
  })

  createPage({
    path: `/projects/tags`,
    component: tagsIndexTemplate,
    context: {
      tags: result.data.projectTagsGroup.group,
      glob: '/projects/*'
    }
  })

  const projectTags = result.data.projectTagsGroup.group
  projectTags.forEach(tag => {
    createPage({
      path: `/projects/tags/${tag.fieldValue}/`,
      component: tagTemplate,
      context: {
        tag: tag.fieldValue,
        glob: '/projects/*',
        allTagsUrl: '/projects/tags'
      },
    })
  })
}

exports.onCreateNode = ({ node, actions, getNode }) => {
  const { createNodeField } = actions

  if (node.internal.type === `MarkdownRemark`) {
    const value = createFilePath({ node, getNode })
    createNodeField({
      name: `slug`,
      node,
      value,
    })
  }
}

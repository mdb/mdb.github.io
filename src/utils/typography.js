import Typography from 'typography'

const typography = new Typography({
  baseFontSize: '20px',
  headerWeight: '200',
  headerFontFamily: ['Georgia', 'serif'],
  bodyFontFamily: ['Georgia', 'serif']
})

// Hot reload typography in development.
if (process.env.NODE_ENV !== `production`) {
  typography.injectStyles()
}

export default typography
export const rhythm = typography.rhythm
export const scale = typography.scale

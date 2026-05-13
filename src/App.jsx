import Cursor    from './components/Cursor'
import Navbar    from './components/Navbar'
import Hero      from './components/Hero'
import About     from './components/About'
import Experience from './components/Experience'
import Projects  from './components/Projects'
import Skills    from './components/Skills'
import Contact   from './components/Contact'
import Footer    from './components/Footer'

export default function App() {
  return (
    <div className="relative min-h-screen bg-brand-bg text-brand-text">

      {/* Noise texture overlay */}
      <div className="noise-overlay" />

      {/* Custom cursor (hidden on touch devices via CSS) */}
      <Cursor />

      {/* Navigation */}
      <Navbar />

      {/* Main content */}
      <main>
        <Hero />
        <About />
        <Experience />
        <Projects />
        <Skills />
        <Contact />
      </main>

      {/* Footer */}
      <Footer />

      {/* Back to top button */}
      <BackToTop />
    </div>
  )
}

/* ── Back to top ─────────────────────────────────────── */
import { useEffect, useState } from 'react'

function BackToTop() {
  const [show, setShow] = useState(false)

  useEffect(() => {
    const onScroll = () => setShow(window.scrollY > 600)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <button
      onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
      aria-label="Back to top"
      className={`fixed bottom-8 right-8 z-50 w-11 h-11 rounded-xl border border-brand-border bg-brand-card flex items-center justify-center text-brand-muted hover:text-brand-accent hover:border-brand-accent transition-all duration-300 ${
        show ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'
      }`}
    >
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5" />
      </svg>
    </button>
  )
}

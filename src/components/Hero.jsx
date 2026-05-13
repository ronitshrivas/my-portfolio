import { useTyped } from '../hooks/useTyped'
import { PERSONAL } from '../config'
import photo from '../assets/photo.jpeg'    

const ROLES = [
  'Flutter Developer',
  'Mobile App Developer',
  'Cross-Platform Dev',
]

// Social icons inline SVG components
const GithubIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"/>
  </svg>
)

const LinkedinIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
  </svg>
)

const FacebookIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
  </svg>
)

const InstagramIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
  </svg>
)

const WhatsappIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
  </svg>
)

export default function Hero() {
  const typed = useTyped(ROLES, 90, 2200)
  const wa = PERSONAL.whatsapp
  const waUrl = `https://wa.me/${wa.number}?text=${encodeURIComponent(wa.message)}`

  return (
    <section id="hero" className="relative min-h-screen flex items-center overflow-hidden">

      {/* Background blobs */}
      <div className="blob w-96 h-96 opacity-20 -top-20 -left-20"
           style={{ background: 'radial-gradient(circle, #5B8DEF, transparent 70%)' }} />
      <div className="blob w-80 h-80 opacity-15 bottom-20 right-10"
           style={{ background: 'radial-gradient(circle, #8B5CF6, transparent 70%)' }} />
      <div className="blob w-64 h-64 opacity-10 top-1/2 right-1/3"
           style={{ background: 'radial-gradient(circle, #00E5CC, transparent 70%)' }} />

      {/* Grid background */}
      <div className="absolute inset-0 opacity-20"
           style={{ backgroundImage: "url(\"data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%232A2A3E' fill-opacity='0.6'%3E%3Cpath d='M0 0h60v1H0zM0 0v60h1V0z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\")" }} />

      {/* Floating particles */}
      {[...Array(20)].map((_, i) => (
        <div
          key={i}
          className="absolute w-1 h-1 rounded-full opacity-30"
          style={{
            background: i % 3 === 0 ? '#5B8DEF' : i % 3 === 1 ? '#00E5CC' : '#8B5CF6',
            left: `${Math.random() * 100}%`,
            top:  `${Math.random() * 100}%`,
            animation: `floatDot ${4 + Math.random() * 4}s ease-in-out ${Math.random() * 3}s infinite`,
          }}
        />
      ))}

      <div className="relative z-10 max-w-6xl mx-auto px-6 pt-28 pb-16 w-full">
        <div className="grid lg:grid-cols-2 gap-16 items-center">

          {/* Left: Text */}
          <div>
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-brand-border bg-brand-surface/60 mb-8 animate-fade-in">
              <span className="w-2 h-2 rounded-full bg-brand-cyan animate-pulse-slow" />
              <span className="font-mono text-xs text-brand-muted">Available for work</span>
            </div>

            {/* Name */}
            <h1 className="font-display font-extrabold text-5xl sm:text-6xl lg:text-7xl leading-none mb-4 animate-fade-up"
                style={{ animationDelay: '0.1s', animationFillMode: 'both' }}>
              <span className="text-brand-text">Ronit</span>
              <br />
              <span className="gradient-text text-glow">Shrivastav</span>
            </h1>

            {/* Typed role */}
            <div className="h-10 mb-6 flex items-center"
                 style={{ animationDelay: '0.2s', animationFillMode: 'both' }}>
              <span className="font-mono text-lg text-brand-accent">{typed}</span>
              <span className="typed-cursor ml-1" />
            </div>

            {/* Tagline */}
<p className="text-brand-muted text-lg leading-relaxed max-w-md mb-2 animate-fade-up"
   style={{ animationDelay: '0.3s', animationFillMode: 'both' }}>
  {PERSONAL.tagline}
</p>
<p className="text-brand-muted text-lg leading-relaxed max-w-md mb-10 animate-fade-up"
   style={{ animationDelay: '0.35s', animationFillMode: 'both' }}>
  {PERSONAL.subtagline}
</p>
            {/* CTA buttons */}
            <div className="flex flex-wrap gap-4 mb-12 animate-fade-up"
                 style={{ animationDelay: '0.4s', animationFillMode: 'both' }}>
              <a href="#projects" className="btn-primary">
                View My Work
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </a>
              <a href="#contact" className="btn-outline">
                Contact Me
              </a>
            </div>

            {/* Social links */}
            <div className="flex items-center gap-3 animate-fade-up"
                 style={{ animationDelay: '0.5s', animationFillMode: 'both' }}>
              <span className="font-mono text-xs text-brand-muted mr-1">Find me on</span>

              <a href={PERSONAL.github} target="_blank" rel="noopener noreferrer"
                 className="social-icon" aria-label="GitHub">
                <GithubIcon />
              </a>

              <a href={PERSONAL.linkedin} target="_blank" rel="noopener noreferrer"
                 className="social-icon" aria-label="LinkedIn">
                <LinkedinIcon />
              </a>

              <a href={PERSONAL.facebook} target="_blank" rel="noopener noreferrer"
                 className="social-icon" aria-label="Facebook">
                <FacebookIcon />
              </a>

              <a href={PERSONAL.instagram} target="_blank" rel="noopener noreferrer"
                 className="social-icon" aria-label="Instagram">
                <InstagramIcon />
              </a>

              <a href={waUrl} target="_blank" rel="noopener noreferrer"
                 className="social-icon" aria-label="WhatsApp">
                <WhatsappIcon />
              </a>
            </div>
          </div>

          {/* Right: Avatar card */}
          <div className="flex justify-center lg:justify-end animate-float">
            <div className="relative">
              {/* Rotating ring */}
              <div className="absolute inset-0 rounded-full border border-brand-accent/20 animate-spin-slow" />
              <div className="absolute -inset-4 rounded-full border border-dashed border-brand-border/30 animate-spin-slow"
                   style={{ animationDirection: 'reverse', animationDuration: '30s' }} />

              {/* Avatar circle */}
              <div className="relative w-72 h-72 rounded-full overflow-hidden border-2 border-brand-border glow-blue"
                   style={{ background: 'linear-gradient(135deg, #1A1A26 0%, #12121A 100%)' }}>

                {/* ✅ Fixed: using imported photo variable instead of hardcoded path */}
                <img
                  src={photo}
                  alt="Ronit Shrivastav"
                  className="w-full h-full object-cover"
                />

                {/* Shimmer overlay */}
                <div className="absolute inset-0 opacity-10"
                     style={{ background: 'linear-gradient(135deg, transparent 40%, rgba(91,141,239,0.5) 100%)' }} />
              </div>

              {/* Floating badges */}
          

              <div className="absolute -top-4 -right-8 bg-brand-card border border-brand-border rounded-xl px-4 py-2 glow-cyan">
                <p className="font-mono text-xs text-brand-muted">Experience</p>
                <p className="font-display font-bold text-brand-cyan">1.5+ Years</p>
              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  )
}
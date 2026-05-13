import { useReveal } from '../hooks/useReveal'

const highlights = [
  { label: 'Apps on Play Store', value: '3+' },
  { label: 'Years as Developer', value: '1.5+' },
  
]

export default function About() {
  const { ref, visible } = useReveal()

  return (
    <section id="about" className="py-28 relative overflow-hidden">

      {/* Subtle bg accent */}
      <div className="blob w-64 h-64 opacity-10 top-0 right-0"
           style={{ background: 'radial-gradient(circle, #8B5CF6, transparent 70%)' }} />

      <div className="max-w-6xl mx-auto px-6">

        {/* Section label */}
        <div className="flex items-center gap-3 mb-4">
          <span className="font-mono text-xs text-brand-accent uppercase tracking-widest">01 / About</span>
          <div className="flex-1 h-px bg-brand-border max-w-xs" />
        </div>

        <h2 className="font-display font-extrabold text-4xl sm:text-5xl text-brand-text mb-16">
          Who I <span className="gradient-text">Am</span>
        </h2>

        <div ref={ref} className={`grid lg:grid-cols-2 gap-16 items-start transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}>

          {/* Left: Text */}
          <div>
<p className="text-brand-muted text-lg leading-relaxed mb-6">
  I'm <span className="text-brand-text font-medium">Ronit Shrivastav</span>, a Flutter Developer 
  with production experience building and shipping apps to the Play Store. I turn ideas into 
  polished, real-world applications — handling everything from UI to API integration.
</p>
<p className="text-brand-muted text-lg leading-relaxed mb-6">
  I've shipped across multiple domains —{' '}
  <span className="text-brand-accent">event management</span>,{' '}
  <span className="text-brand-cyan">social media</span>,{' '}
  <span className="text-brand-accent">E-learning</span>,{' '}
  <span className="text-brand-accent">Messaging</span>,{' '}
  <span className="text-brand-cyan">E-commerce with payment gateway integration</span>,{' '}
  <span className="text-brand-accent">Bluetooth hardware</span>, and{' '}
  <span className="text-brand-cyan">inventory management ERPs</span>.
</p>
<p className="text-brand-muted text-lg leading-relaxed mb-10">
  I write clean, maintainable code with a focus on performance and user experience. 
  Whether it's a startup MVP or a full-scale enterprise app — I deliver.
</p>

            {/* Education */}
            <div className="bg-brand-card border border-brand-border rounded-xl p-6">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-brand-accent/10 border border-brand-accent/20 flex items-center justify-center flex-shrink-0">
                  {/* Graduation cap icon */}
                  <svg className="w-5 h-5 text-brand-accent" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4.26 10.147a60.436 60.436 0 00-.491 6.347A48.627 48.627 0 0112 20.904a48.627 48.627 0 018.232-4.41 60.46 60.46 0 00-.491-6.347m-15.482 0a50.57 50.57 0 00-2.658-.813A59.905 59.905 0 0112 3.493a59.902 59.902 0 0110.399 5.84c-.896.248-1.783.52-2.658.814m-15.482 0A50.697 50.697 0 0112 13.489a50.702 50.702 0 017.74-3.342M6.75 15a.75.75 0 100-1.5.75.75 0 000 1.5zm0 0v-3.675A55.378 55.378 0 0112 8.443m-7.007 11.55A5.981 5.981 0 006.75 15.75v-1.5" />
                  </svg>
                </div>
                <div>
                  <p className="font-mono text-xs text-brand-muted mb-1">Education</p>
                  <h3 className="font-display font-bold text-brand-text text-lg">
                    Bachelor in Computer Science & Information Technology
                  </h3>
                  <p className="text-brand-muted text-sm">National Infotech College</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="font-mono text-xs text-brand-muted">Apr 2022 — 2026</span>
                    <span className="px-2 py-0.5 rounded-full text-xs font-mono bg-brand-cyan/10 text-brand-cyan border border-brand-cyan/20">
                      Completed
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right: Stats */}
          <div>
            <div className="grid grid-cols-2 gap-4 mb-8">
              {highlights.map((h, i) => (
                <div
                  key={h.label}
                  className="bg-brand-card border border-brand-border rounded-xl p-6 card-hover"
                  style={{ transitionDelay: `${i * 80}ms` }}
                >
                  <p className="font-display font-black text-4xl gradient-text mb-1">{h.value}</p>
                  <p className="font-body text-sm text-brand-muted">{h.label}</p>
                </div>
              ))}
            </div>

            {/* Fun facts */}
            <div className="bg-brand-card border border-brand-border rounded-xl p-6 space-y-4">
              <p className="font-mono text-xs text-brand-accent uppercase tracking-widest mb-4">Quick Facts</p>
              {[
                { icon: '📍', text: 'Based in Lalitpur, Nepal' },
                { icon: '📱', text: 'Dart & Flutter specialist' },
                { icon: '🚀', text: '3 apps live on Play Store' },
                { icon: '🎯', text: 'Clean architecture advocate' },
                { icon: '🤝', text: 'Open to full-time & freelance' },
              ].map(f => (
                <div key={f.text} className="flex items-center gap-3">
                  <span className="text-xl">{f.icon}</span>
                  <span className="text-brand-muted text-sm">{f.text}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

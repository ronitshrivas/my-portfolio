import { useReveal } from '../hooks/useReveal'

const experiences = [
  {
    role:        'Flutter Developer',
    company:     'Nepatronix Engineering Solution',
    location:    'Kandebta, Lalitpur',
    period:      'Apr 2024 — Present',
    type:        'Full-time',
    color:       'brand-accent',
    colorHex:    '#5B8DEF',
    highlights: [
      'Building and shipping production-grade Flutter apps for iOS & Android',
      'Developed Event Solution — a multi-role event ticketing app now live on Play Store',
      'Built Innovator — a multi-functional platform combining social media, e-learning, and e-commerce for electronics',
      'Created MBT — a Bluetooth thermal printer app for barcode & QR code generation',
      'Created Vishwas E-Learning — a Ultimate E-Learning app with course management, video streaming, and quizzes',
      'Integrated payment gateways, Google Maps, and real-time Bluetooth communication',
    ],
    tech: ['Flutter', 'Dart', 'RiverPod', 'REST APIs', 'Bluetooth', 'Payment Gateway'],
  },
  {
    role:        'Flutter Developer (Internship)',
    company:     'Agram  Solutions Pvt. Ltd.',
    location:    'Panitanki, Birgunj',
    period:      'July 2022 — Dec 2023',
    type:        'Jr. Flutter Developer',
    color:       'brand-cyan',
    colorHex:    '#00E5CC',
    highlights: [
      'Developed and deployed UI components for the Academic ERP system using Flutter',
      'Worked on inventory management module within the ERP suite',
      'Collaborated with UI/UX designers to implement responsive, user-friendly designs',
      'Integrated Flutter UI with backend systems for seamless data flow (course registration, grading)',
      'Tested and debugged UI across multiple devices for optimal performance',
    ],
    tech: ['Flutter', 'Dart', 'REST APIs', 'Git', 'ERP Systems'],
  },
  {
    role:        'Flutter Developer (Internship)',
    company:     'Agram  Solutions Pvt. Ltd.',
    location:    'Panitanki, Birgunj',
    period:      'April 2022 — July 2022',
    type:        'Internship',
    color:       'brand-cyan',
    colorHex:    '#00E5CC',
    highlights: [
      'Developed and deployed UI components for the Academic ERP system using Flutter',
      'Worked on inventory management module within the ERP suite',
      'Collaborated with UI/UX designers to implement responsive, user-friendly designs',
      'Integrated Flutter UI with backend systems for seamless data flow (course registration, grading)',
      'Tested and debugged UI across multiple devices for optimal performance',
    ],
    tech: ['Flutter', 'Dart', 'REST APIs', 'Git', 'ERP Systems'],
  },
]

function ExperienceCard({ exp, index }) {
  const { ref, visible } = useReveal()

  return (
    <div
      ref={ref}
      className={`relative pl-12 transition-all duration-700 ${visible ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-8'}`}
      style={{ transitionDelay: `${index * 120}ms` }}
    >
      {/* Timeline dot */}
      <div className="absolute left-0 top-6 w-8 h-8 rounded-full border-2 flex items-center justify-center"
           style={{ borderColor: exp.colorHex, background: `${exp.colorHex}15` }}>
        <div className="w-2 h-2 rounded-full" style={{ background: exp.colorHex }} />
      </div>

      <div className="bg-brand-card border border-brand-border rounded-xl p-6 card-hover mb-6">
        {/* Header */}
        <div className="flex flex-wrap items-start justify-between gap-4 mb-5">
          <div>
            <h3 className="font-display font-bold text-xl text-brand-text">{exp.role}</h3>
            <p className="font-mono text-sm mt-0.5" style={{ color: exp.colorHex }}>{exp.company}</p>
            <p className="text-brand-muted text-sm">{exp.location}</p>
          </div>
          <div className="flex flex-col items-end gap-2">
            <span className="font-mono text-xs text-brand-muted">{exp.period}</span>
            <span className="px-3 py-1 rounded-full text-xs font-mono border"
                  style={{ color: exp.colorHex, borderColor: `${exp.colorHex}40`, background: `${exp.colorHex}10` }}>
              {exp.type}
            </span>
          </div>
        </div>

        {/* Bullet points */}
        <ul className="space-y-2 mb-5">
          {exp.highlights.map(h => (
            <li key={h} className="flex items-start gap-3 text-brand-muted text-sm">
              <span className="mt-2 w-1 h-1 rounded-full flex-shrink-0" style={{ background: exp.colorHex }} />
              {h}
            </li>
          ))}
        </ul>

        {/* Tech chips */}
        <div className="flex flex-wrap gap-2">
          {exp.tech.map(t => (
            <span key={t} className="skill-tag">{t}</span>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function Experience() {
  return (
    <section id="experience" className="py-28 relative overflow-hidden">

      <div className="blob w-72 h-72 opacity-10 -bottom-10 -left-10"
           style={{ background: 'radial-gradient(circle, #5B8DEF, transparent 70%)' }} />

      <div className="max-w-6xl mx-auto px-6">

        {/* Section label */}
        <div className="flex items-center gap-3 mb-4">
          <span className="font-mono text-xs text-brand-accent uppercase tracking-widest">02 / Experience</span>
          <div className="flex-1 h-px bg-brand-border max-w-xs" />
        </div>

        <h2 className="font-display font-extrabold text-4xl sm:text-5xl text-brand-text mb-16">
          Where I've <span className="gradient-text">Worked</span>
        </h2>

        {/* Timeline */}
        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-4 top-6 bottom-0 w-px"
               style={{ background: 'linear-gradient(to bottom, #5B8DEF, rgba(91,141,239,0.1))' }} />

          <div className="space-y-2">
            {experiences.map((exp, i) => (
              <ExperienceCard key={exp.company} exp={exp} index={i} />
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

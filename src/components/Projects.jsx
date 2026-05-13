import { useReveal } from '../hooks/useReveal'

const projects = [
  {
    name:        'Event Solution',
    emoji:       '🎟️',
    tagline:     'Multi-role Event Ticketing Platform',
    description: 'A full-featured event ticket booking app with multi-tier authorization (Admin, User, Employee). Built with role-based access control, secure authentication, and smooth UI/UX across iOS and Android.',
    highlights: [
      'Multi-role auth with RBAC',
      'Responsive cross-platform UI',
      'Seamless checkout flow',
    ],
    tech:      ['Flutter', 'Dart', 'RiverPod', 'REST API', 'RBAC'],
    playStore: 'https://play.google.com/store/apps/details?id=com.nepatronix.eventsolutions',
    color:     '#5B8DEF',
    gradient:  'linear-gradient(135deg, #5B8DEF22 0%, transparent 100%)',
  },
  {
    name:        'Innovator',
    emoji:       '🚀',
    tagline:     'Social · E-Learning · E-Commerce Platform',
    description: 'An ambitious multi-functional app combining social networking, e-learning courses, and electronics e-commerce — all in one seamless mobile experience with secure payment integration.',
    highlights: [
      'Social feed + messaging',
      'E-learning module',
      'Payment gateway integration',
    ],
    tech:      ['Flutter', 'Dart', 'RiverPod', 'Payment APIs', 'REST API'],
    playStore: 'https://play.google.com/store/apps/details?id=com.innovation.innovator',
    color:     '#8B5CF6',
    gradient:  'linear-gradient(135deg, #8B5CF622 0%, transparent 100%)',
  },
  {
    name:        'MBT — Mobile Barcode Tool',
    emoji:       '🖨️',
    tagline:     'Bluetooth Thermal Printing App',
    description: 'A utility app for generating and printing barcodes & QR codes via Bluetooth-enabled thermal printers. Users can create custom codes, select label formats, and print in real-time.',
    highlights: [
      'Barcode & QR code generation',
      'Bluetooth printer integration',
      'Custom label format selector',
    ],
    tech:      ['Flutter', 'Dart', 'Bluetooth', 'QR/Barcode Gen'],
    playStore: 'https://play.google.com/store/apps/details?id=com.mbt.barcode_label_designer',
    color:     '#00E5CC',
    gradient:  'linear-gradient(135deg, #00E5CC22 0%, transparent 100%)',
  },
  {
    name:        'Academic ERP',
    emoji:       '🏫',
    tagline:     'University ERP with Inventory Module',
    description: 'Worked on the Flutter frontend for a comprehensive academic ERP system covering course registration, grading, inventory management, and more',
    highlights: [
      'ERP UI components',
      'Inventory management module',
      'Backend API integration',
    ],
    tech:      ['Flutter', 'Dart', 'REST API', 'ERP'],
    playStore: null, // Internal enterprise app
    color:     '#F59E0B',
    gradient:  'linear-gradient(135deg, #F59E0B22 0%, transparent 100%)',
  },
   {
    name:        'Vishwas E-Learning',
    emoji:       '🏫',
    tagline:     'Ultimate E-Learning App',
    description: 'Worked on the Flutter & Firebase frontend for a comprehensive E-Learning app with course management, video streaming, quizzes, and more',
    highlights: [
      'Course management UI',
      'Video streaming functionality',
      'Quiz creation and management',
    ],
    tech:      ['Flutter', 'Dart', 'REST API', 'Firebase', 'E-Learning', 'Video Streaming'],
    playStore:  'https://play.google.com/store/apps/details?id=com.Elearning.vishwas&pcampaignid=web_share', // Internal enterprise app
    color:     '#563c10',
    gradient:  'linear-gradient(135deg, #F59E0B22 0%, transparent 100%)',
  },
]

function ProjectCard({ project, index }) {
  const { ref, visible } = useReveal()

  return (
    <div
      ref={ref}
      className={`relative bg-brand-card border border-brand-border rounded-2xl p-6 card-hover flex flex-col transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}
      style={{ transitionDelay: `${index * 100}ms`, background: project.gradient }}
    >
      {/* Corner accent */}
      <div className="absolute top-0 right-0 w-24 h-24 rounded-tr-2xl rounded-bl-full opacity-10"
           style={{ background: project.color }} />

      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <span className="text-3xl mb-2 block">{project.emoji}</span>
          <h3 className="font-display font-bold text-xl text-brand-text">{project.name}</h3>
          <p className="font-mono text-xs mt-0.5" style={{ color: project.color }}>{project.tagline}</p>
        </div>
        {project.playStore && (
          <a
            href={project.playStore}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-xs font-mono transition-all hover:opacity-80"
            style={{ borderColor: `${project.color}40`, color: project.color, background: `${project.color}10` }}
          >
            <svg className="w-3 h-3" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3.18 23.4a2 2 0 002.17-.27l11.08-6.4L13 13.4 3.18 23.4zM20.5 10.56l-2.3-1.33-3.5 3.17 3.5 3.17 2.33-1.35a2 2 0 000-3.66zM1.07 1.05A2 2 0 001 1.63V22.37a2 2 0 00.07.58L13 12 1.07 1.05zM16.35 4.27L5.35.6A2 2 0 003.18.33L13 10l3.35-5.73z"/>
            </svg>
            Play Store
          </a>
        )}
        {!project.playStore && (
          <span className="px-3 py-1.5 rounded-lg border border-brand-border text-xs font-mono text-brand-muted">
            Enterprise
          </span>
        )}
      </div>

      {/* Description */}
      <p className="text-brand-muted text-sm leading-relaxed mb-4 flex-1">{project.description}</p>

      {/* Highlights */}
      <ul className="space-y-1.5 mb-5">
        {project.highlights.map(h => (
          <li key={h} className="flex items-center gap-2 text-brand-muted text-sm">
            <span className="w-1 h-1 rounded-full" style={{ background: project.color }} />
            {h}
          </li>
        ))}
      </ul>

      {/* Tech stack */}
      <div className="flex flex-wrap gap-2 pt-4 border-t border-brand-border/50">
        {project.tech.map(t => (
          <span key={t} className="skill-tag">{t}</span>
        ))}
      </div>
    </div>
  )
}

export default function Projects() {
  return (
    <section id="projects" className="py-28 relative overflow-hidden">

      <div className="blob w-80 h-80 opacity-10 top-0 right-0"
           style={{ background: 'radial-gradient(circle, #00E5CC, transparent 70%)' }} />

      <div className="max-w-6xl mx-auto px-6">

        {/* Section label */}
        <div className="flex items-center gap-3 mb-4">
          <span className="font-mono text-xs text-brand-accent uppercase tracking-widest">03 / Projects</span>
          <div className="flex-1 h-px bg-brand-border max-w-xs" />
        </div>

        <h2 className="font-display font-extrabold text-4xl sm:text-5xl text-brand-text mb-4">
          What I've <span className="gradient-text">Built</span>
        </h2>
        <p className="text-brand-muted text-lg mb-16 max-w-xl">
          Production apps shipped to real users — from event management to Bluetooth printing.
        </p>

        <div className="grid sm:grid-cols-2 lg:grid-cols-2 gap-6">
          {projects.map((p, i) => (
            <ProjectCard key={p.name} project={p} index={i} />
          ))}
        </div>
      </div>
    </section>
  )
}

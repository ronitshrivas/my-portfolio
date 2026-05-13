import { useReveal } from '../hooks/useReveal'

// ── All skills grouped by category ─────────────────────────────────────────
const skillGroups = [
  {
    category: 'Core Language & Framework',
    icon: '⚡',
    color: '#5B8DEF',
    skills: ['Dart', 'Flutter', 'OOP Concepts',],
  },
  {
    category: 'State Management',
    icon: '🔄',
    color: '#8B5CF6',
    skills: ['RiverPod', 'GetX', 'setState'],
  },
  {
    category: 'Architecture & Design',
    icon: '🏗️',
    color: '#00E5CC',
    skills: ['Clean Architecture', 'MVVM Pattern', 'Repository Pattern', 'Responsive Design', 'Adaptive UI'],
  },
  {
    category: 'Firebase & Backend',
    icon: '🔥',
    color: '#F59E0B',
    skills: ['Firebase Core', 'Firebase Auth', 'Cloud Firestore', 'Firebase Realtime DB', 'Firebase Storage', 'Push Notifications (FCM)','REST APIs',"GraphQL","WebSocket"],
  },
  {
    category: 'Hardware & Device',
    icon: '📡',
    color: '#EC4899',
    skills: ['Bluetooth / BLE', 'Thermal Printer Integration', 'Barcode & QR Generation', 'Camera & Gallery', 'File System', 'Local Notifications'],
  },
  {
    category: 'Maps & Location',
    icon: '🗺️',
    color: '#10B981',
    skills: ['Google Maps SDK', 'Geolocator', 'Geocoding', 'Location Permissions'],
  },
  {
    category: 'Payments & Auth',
    icon: '💳',
    color: '#5B8DEF',
    skills: ['Payment Gateway Integration', 'Khalti', 'eSewa', 'Google Sign-In', 'RBAC (Role-Based Access)'],
  },
  {
    category: 'UI & Animation',
    icon: '🎨',
    color: '#00E5CC',
    skills: ['Custom Widgets', 'Flutter Animations', 'Lottie Animations', 'Shimmer Effects', 'Custom Painter', 'Flutter Themes'],
  },
  {
    category: 'Storage & Database',
    icon: '🗄️',
    color: '#8B5CF6',
    skills: ['Shared Preferences', 'Hive', 'Secure Storage'],
  },
  {
    category: 'Dev Tools & Workflow',
    icon: '🛠️',
    color: '#F59E0B',
    skills: ['Git / GitHub', 'Android Studio', 'VS Code', 'Postman', 'Play Store Deployment', 'App Signing & Release', 'Flutter Localization (l10n)', 'Flavors & Environments'],
  },
]

function SkillCard({ group, index }) {
  const { ref, visible } = useReveal()
  return (
    <div
      ref={ref}
      className={`bg-brand-card border border-brand-border rounded-xl p-6 card-hover transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}
      style={{ transitionDelay: `${index * 60}ms` }}
    >
      <div className="flex items-center gap-2 mb-5 pb-4 border-b border-brand-border/60">
        <span className="text-xl">{group.icon}</span>
        <h3 className="font-display font-bold text-sm text-brand-text leading-tight">{group.category}</h3>
      </div>
      <div className="flex flex-wrap gap-2">
        {group.skills.map(skill => (
          <span
            key={skill}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-mono border transition-all duration-200 hover:scale-105 cursor-default"
            style={{ borderColor: `${group.color}30`, background: `${group.color}08`, color: group.color }}
          >
            <span className="w-1 h-1 rounded-full flex-shrink-0" style={{ background: group.color }} />
            {skill}
          </span>
        ))}
      </div>
    </div>
  )
}

export default function Skills() {
  const { ref: headerRef, visible: headerVisible } = useReveal()
  const total = skillGroups.reduce((acc, g) => acc + g.skills.length, 0)

  return (
    <section id="skills" className="py-28 relative overflow-hidden">
      <div className="blob w-72 h-72 opacity-10 bottom-0 left-0" style={{ background: 'radial-gradient(circle, #8B5CF6, transparent 70%)' }} />
      <div className="blob w-64 h-64 opacity-8 top-20 right-10"  style={{ background: 'radial-gradient(circle, #5B8DEF, transparent 70%)' }} />

      <div className="max-w-6xl mx-auto px-6">
        <div className="flex items-center gap-3 mb-4">
          <span className="font-mono text-xs text-brand-accent uppercase tracking-widest">04 / Skills</span>
          <div className="flex-1 h-px bg-brand-border max-w-xs" />
        </div>

        <div ref={headerRef} className={`mb-16 transition-all duration-700 ${headerVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
          <h2 className="font-display font-extrabold text-4xl sm:text-5xl text-brand-text mb-4">
            My <span className="gradient-text">Toolkit</span>
          </h2>
          <p className="text-brand-muted text-lg max-w-xl">
            Everything I use to build polished, production-grade Flutter apps — from Firebase to Bluetooth.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {skillGroups.map((group, i) => (
            <SkillCard key={group.category} group={group} index={i} />
          ))}
        </div>

        <div className="mt-10 flex flex-wrap items-center justify-center gap-3 py-5 px-8 rounded-2xl border border-brand-border bg-brand-card/50">
          <span className="font-display font-black text-3xl gradient-text">{total}+</span>
          <span className="font-mono text-sm text-brand-muted">Technologies &amp; Tools across</span>
          <span className="font-display font-bold text-brand-text">{skillGroups.length} categories</span>
        </div>
      </div>
    </section>
  )
}
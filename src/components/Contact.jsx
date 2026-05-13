

import { useState, useRef } from 'react'
import { useReveal } from '../hooks/useReveal'
import { PERSONAL, EMAILJS } from '../config'
import emailjs from 'emailjs-com'


const CV_PATH = '/cv/Prashant-Sharma-cv.pdf'

const SOCIAL_LINKS = [
  {
    label: 'Email',
    value: PERSONAL.email,
    href:  `mailto:${PERSONAL.email}`,
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
      </svg>
    ),
    color: '#5B8DEF',
  },
  {
    label: 'Phone',
    value: PERSONAL.phone,
    href:  `tel:${PERSONAL.phone.replace(/\s/g, '')}`,
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z" />
      </svg>
    ),
    color: '#00E5CC',
  },
  {
    label: 'WhatsApp',
    value: 'Chat with me',
    href:  `https://wa.me/${PERSONAL.whatsapp.number}?text=${encodeURIComponent(PERSONAL.whatsapp.message)}`,
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
      </svg>
    ),
    color: '#25D366',
  },
  {
    label: 'LinkedIn',
    value: 'Connect professionally',
    href:  PERSONAL.linkedin,
    icon: (
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
      </svg>
    ),
    color: '#0077B5',
  },
]

export default function Contact() {
  const { ref, visible } = useReveal()
  const formRef = useRef(null)

  const [form, setForm]     = useState({ name: '', email: '', subject: '', message: '' })
  const [status, setStatus] = useState('idle') 
  const [errMsg, setErrMsg] = useState('')

  const handleChange = e => setForm(f => ({ ...f, [e.target.name]: e.target.value }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!form.name || !form.email || !form.message) return
    setStatus('sending')
    setErrMsg('')

   
    try {
      await emailjs.send(
        EMAILJS.serviceId,
        EMAILJS.templateId,
        {
          from_name:  form.name,
          from_email: form.email,
          subject:    form.subject || 'Portfolio Contact',
          message:    form.message,
          to_name:    'Prashant',
        },
        EMAILJS.publicKey
      )
      setStatus('success')
      setForm({ name: '', email: '', subject: '', message: '' })
    } catch (err) {
      console.error('EmailJS error:', err)
      setStatus('error')
      setErrMsg('Could not send message. Please email me directly or reach out on WhatsApp.')
    }
  }

  return (
    <section id="contact" className="py-28 relative overflow-hidden">
      <div className="blob w-80 h-80 opacity-10 top-0 right-0"  style={{ background: 'radial-gradient(circle, #5B8DEF, transparent 70%)' }} />
      <div className="blob w-64 h-64 opacity-10 bottom-0 left-0" style={{ background: 'radial-gradient(circle, #00E5CC, transparent 70%)' }} />

      <div className="max-w-6xl mx-auto px-6">
        {/* Section label */}
        <div className="flex items-center gap-3 mb-4">
          <span className="font-mono text-xs text-brand-accent uppercase tracking-widest">05 / Contact</span>
          <div className="flex-1 h-px bg-brand-border max-w-xs" />
        </div>

        <h2 className="font-display font-extrabold text-4xl sm:text-5xl text-brand-text mb-4">
          Let's <span className="gradient-text">Connect</span>
        </h2>
        <p className="text-brand-muted text-lg mb-16 max-w-xl">
          Have a project in mind or just want to say hi? I'd love to hear from you.
        </p>

        {/* ── CV Banner ─────────────────────────────────────────────────────── */}
        {/*
          ✅ CV PLACEMENT INSTRUCTIONS:
          1. Create a folder: /public/cv/
          2. Drop your PDF there: /public/cv/Prashant-Sharma-CV.pdf
          3. The "Download CV" and "View CV" buttons below will work automatically.
          No code changes needed — just paste the file in the right folder!
        */}
        <div className="mb-12 flex flex-col sm:flex-row items-center justify-between gap-6 p-6 rounded-2xl border border-brand-border bg-brand-card/60"
             style={{ background: 'linear-gradient(135deg, rgba(91,141,239,0.07) 0%, rgba(0,229,204,0.05) 100%)' }}>
          <div className="flex items-center gap-4">
            {/* PDF icon */}
            <div className="w-14 h-14 rounded-xl border border-brand-accent/30 bg-brand-accent/10 flex items-center justify-center flex-shrink-0">
              <svg className="w-7 h-7 text-brand-accent" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
              </svg>
            </div>
            <div>
              <h3 className="font-display font-bold text-brand-text text-lg">My Resume / CV</h3>
              <p className="font-mono text-xs text-brand-muted">Flutter Developer · Ronit Shrivastav</p>
            </div>
          </div>
          <div className="flex items-center gap-3 flex-shrink-0">
            {/* View CV — opens in new tab */}
            <a
              href={CV_PATH}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-outline text-sm py-2.5 px-5"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              View CV
            </a>
            {/* Download CV */}
            <a
              href={CV_PATH}
              download="Prashant-Sharma-CV.pdf"
              className="btn-primary text-sm py-2.5 px-5"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
              </svg>
              Download CV
            </a>
          </div>
        </div>

        {/* ── Main grid ─────────────────────────────────────────────────────── */}
        <div
          ref={ref}
          className={`grid lg:grid-cols-5 gap-12 transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}
        >
          {/* Left: quick contact cards */}
          <div className="lg:col-span-2 space-y-3">
            {SOCIAL_LINKS.map(link => (
              <a
                key={link.label}
                href={link.href}
                target={link.label !== 'Email' && link.label !== 'Phone' ? '_blank' : undefined}
                rel="noopener noreferrer"
                className="flex items-center gap-4 bg-brand-card border border-brand-border rounded-xl p-4 card-hover group"
              >
                <div
                  className="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0"
                  style={{ background: `${link.color}15`, color: link.color }}
                >
                  {link.icon}
                </div>
                <div className="min-w-0">
                  <p className="font-mono text-xs text-brand-muted">{link.label}</p>
                  <p className="font-body text-sm text-brand-text truncate">{link.value}</p>
                </div>
                <svg className="w-4 h-4 ml-auto text-brand-muted group-hover:text-brand-accent transition-colors flex-shrink-0"
                     fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 19.5l15-15m0 0H8.25m11.25 0v11.25" />
                </svg>
              </a>
            ))}

            {/* Location card */}
            <div className="flex items-center gap-4 bg-brand-card border border-brand-border rounded-xl p-4">
              <div className="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0"
                   style={{ background: '#F59E0B15', color: '#F59E0B' }}>
                <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                </svg>
              </div>
              <div>
                <p className="font-mono text-xs text-brand-muted">Location</p>
                <p className="font-body text-sm text-brand-text">{PERSONAL.location}</p>
              </div>
            </div>
          </div>

          {/* Right: contact form */}
          <div className="lg:col-span-3">
            <div className="bg-brand-card border border-brand-border rounded-2xl p-8">
              <h3 className="font-display font-bold text-xl text-brand-text mb-2">Send a Message</h3>
<div className="flex items-center gap-3 mb-6">
  <p className="font-mono text-xs text-brand-muted">
    Fill in the form — I'll reply within 24 hours ✉️
  </p>
  <span className="flex items-center gap-1 px-2 py-0.5 rounded-full border border-green-500/20 bg-green-500/10">
    <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
    <span className="font-mono text-xs text-green-400">Usually replies fast</span>
  </span>
</div>

              {/* ── Success state ── */}
              {status === 'success' ? (
                <div className="flex flex-col items-center justify-center py-12 text-center">
                  <div className="w-16 h-16 rounded-full bg-brand-cyan/10 border border-brand-cyan/30 flex items-center justify-center mb-4">
                    <svg className="w-8 h-8 text-brand-cyan" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <h4 className="font-display font-bold text-brand-text text-xl mb-2">Message Sent! 🎉</h4>
                  <p className="text-brand-muted text-sm mb-6">Thanks for reaching out — I'll get back to you soon.</p>
                  <button onClick={() => setStatus('idle')} className="btn-outline text-sm py-2 px-6">
                    Send Another
                  </button>
                </div>
              ) : (
                /* ── Form ── */
                <form ref={formRef} onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block font-mono text-xs text-brand-muted mb-2">Your Name *</label>
                      <input
                        type="text" name="name" value={form.name} onChange={handleChange}
                        required placeholder="Mark Zuckerberg" className="input-field"
                      />
                    </div>
                    <div>
                      <label className="block font-mono text-xs text-brand-muted mb-2">Your Email *</label>
                      <input
                        type="email" name="email" value={form.email} onChange={handleChange}
                        required placeholder="zuckerberg@example.com" className="input-field"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block font-mono text-xs text-brand-muted mb-2">Subject</label>
                    <input
                      type="text" name="subject" value={form.subject} onChange={handleChange}
                      placeholder="Project collaboration, freelance work..." className="input-field"
                    />
                  </div>

                  <div>
                    <label className="block font-mono text-xs text-brand-muted mb-2">Message *</label>
                    <textarea
                      name="message" value={form.message} onChange={handleChange}
                      required rows={5} placeholder="Tell me about your project or idea..."
                      className="input-field resize-none"
                    />
                  </div>

                  {/* Error message */}
                  {status === 'error' && (
                    <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20">
                      <svg className="w-4 h-4 text-red-400 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth={1.5} viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
                      </svg>
                      <p className="text-red-400 font-mono text-xs">{errMsg}</p>
                    </div>
                  )}

                  {/* Submit */}
                  <button
                    type="submit"
                    disabled={status === 'sending'}
                    className="btn-primary w-full justify-center disabled:opacity-60 disabled:cursor-not-allowed"
                  >
                    {status === 'sending' ? (
                      <>
                        <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        Sending…
                      </>
                    ) : (
                      <>
                        Send Message
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
                        </svg>
                      </>
                    )}
                  </button>
                </form>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
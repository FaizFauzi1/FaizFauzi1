export default function Home() {
  const APP_URL = process.env.NEXT_PUBLIC_APP_URL || 'https://app.eventease.com'

  return (
    <>
      {/* ── Navbar ── */}
      <nav className="navbar">
        <a href="/" className="navbar-logo">
          <span className="navbar-logo-icon">✦</span>
          EventEase
        </a>
        <ul className="navbar-links">
          <li><a href="#features">Features</a></li>
          <li><a href="#how-it-works">How it works</a></li>
          <li><a href="#testimonials">Reviews</a></li>
          <li><a href="#pricing">Pricing</a></li>
        </ul>
        <div className="navbar-cta">
          <a href={`${APP_URL}/login`} className="btn-ghost" style={{ padding: '0.65rem 1.4rem', fontSize: '0.9rem' }}>
            Log in
          </a>
          <a href={`${APP_URL}/register`} className="btn-primary" style={{ padding: '0.65rem 1.4rem', fontSize: '0.9rem' }}>
            Get started free
          </a>
        </div>
      </nav>

      <main>
        {/* ── Hero ── */}
        <section className="hero" aria-label="Hero">
          <div className="container" style={{ position: 'relative', zIndex: 1 }}>
            <div className="hero-badge">
              🇲🇾 &nbsp;Malaysia&apos;s #1 Event Planning Platform
            </div>
            <h1 className="hero-title">
              Plan Your Perfect Event{' '}
              <span className="accent-text">Stress-Free</span>
            </h1>
            <p className="hero-subtitle">
              Discover top-rated vendors, manage your budget, and coordinate every
              detail — all in one beautiful app. From intimate weddings to grand
              corporate galas.
            </p>
            <div className="hero-cta">
              <a href={`${APP_URL}/register`} className="btn-primary">
                Start Planning Free →
              </a>
              <a href="#how-it-works" className="btn-ghost">
                See how it works
              </a>
            </div>
            <div className="hero-trust">
              <div className="hero-avatars" aria-hidden="true">
                <span>FZ</span><span>AY</span><span>KL</span><span>NR</span>
              </div>
              <span>Trusted by <strong>5,000+</strong> event planners in Malaysia</span>
            </div>
          </div>
        </section>

        {/* ── Stats ── */}
        <section className="stats" aria-label="Platform statistics">
          <div className="container">
            <div className="stats-grid">
              <div className="stat-item">
                <div className="stat-number gradient-text">5,000+</div>
                <div className="stat-label">Events Planned</div>
              </div>
              <div className="stat-item">
                <div className="stat-number gradient-text">1,200+</div>
                <div className="stat-label">Verified Vendors</div>
              </div>
              <div className="stat-item">
                <div className="stat-number gradient-text">98%</div>
                <div className="stat-label">Satisfaction Rate</div>
              </div>
              <div className="stat-item">
                <div className="stat-number accent-text">RM 2M+</div>
                <div className="stat-label">Budget Managed</div>
              </div>
            </div>
          </div>
        </section>

        {/* ── Features ── */}
        <section id="features" className="section features" aria-labelledby="features-heading">
          <div className="container">
            <div className="features-header">
              <span className="section-tag">Everything you need</span>
              <h2 id="features-heading" className="section-title gradient-text">
                Your complete event toolkit
              </h2>
              <p className="section-desc">
                From finding the perfect caterer to tracking your budget down to the last
                ringgit — EventEase has every tool you need.
              </p>
            </div>
            <div className="features-grid">
              {[
                {
                  icon: '🔍',
                  title: 'Vendor Discovery',
                  desc: 'Browse 1,200+ verified vendors across photography, catering, floristry, venues, and more. Read reviews and compare quotes instantly.',
                },
                {
                  icon: '💰',
                  title: 'Budget Tracker',
                  desc: 'Set a budget, track every expense, and get real-time alerts when you\'re about to go over. Never get surprised by hidden costs again.',
                },
                {
                  icon: '📅',
                  title: 'Smart Scheduling',
                  desc: 'Coordinate timelines, send invites, and manage RSVPs — all from one unified dashboard that keeps everyone in sync.',
                },
                {
                  icon: '💬',
                  title: 'In-App Messaging',
                  desc: 'Chat directly with vendors, share mood boards, and keep all communications in one thread. No more scattered emails.',
                },
                {
                  icon: '✅',
                  title: 'Task Checklists',
                  desc: 'Stay on track with smart, customisable checklists tailored to your event type, with automated reminders as deadlines approach.',
                },
                {
                  icon: '🗺️',
                  title: 'Guest Management',
                  desc: 'Manage your guest list, send QR code invitations, track arrivals, and assign seating — all from your phone.',
                },
              ].map((f) => (
                <article key={f.title} className="feature-card">
                  <div className="feature-icon" aria-hidden="true">{f.icon}</div>
                  <h3>{f.title}</h3>
                  <p>{f.desc}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── How it works ── */}
        <section id="how-it-works" className="section how-it-works" aria-labelledby="how-heading">
          <div className="container">
            <span className="section-tag">Simple process</span>
            <h2 id="how-heading" className="section-title">
              Plan your event in{' '}
              <span className="gradient-text">4 easy steps</span>
            </h2>
            <div className="steps-grid">
              {[
                { n: '1', title: 'Create your event', desc: 'Set the date, type, and budget for your event in under 2 minutes.' },
                { n: '2', title: 'Discover vendors', desc: 'Browse verified vendors in your area, compare quotes, and book directly.' },
                { n: '3', title: 'Manage everything', desc: 'Track tasks, budget, guest lists, and communications in one place.' },
                { n: '4', title: 'Enjoy your day', desc: 'On the day, use our live dashboard to coordinate and check guests in with QR codes.' },
              ].map((s) => (
                <div key={s.n} className="step-item">
                  <div className="step-number" aria-hidden="true">{s.n}</div>
                  <h3>{s.title}</h3>
                  <p>{s.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Testimonials ── */}
        <section id="testimonials" className="section testimonials" aria-labelledby="testimonials-heading">
          <div className="container">
            <div className="testimonials-header">
              <span className="section-tag">Real stories</span>
              <h2 id="testimonials-heading" className="section-title">
                Loved by planners{' '}
                <span className="accent-text">across Malaysia</span>
              </h2>
              <p className="section-desc">
                Don&apos;t take our word for it — hear from couples and professionals who
                planned their events with EventEase.
              </p>
            </div>
            <div className="testimonials-grid">
              {[
                {
                  stars: '★★★★★',
                  quote: 'EventEase made planning my wedding feel like a breeze. I found our photographer, florist, and caterer all in one app. The budget tracker saved us from overspending!',
                  name: 'Aisha Rahman',
                  role: 'Bride, Kuala Lumpur',
                  initials: 'AR',
                },
                {
                  stars: '★★★★★',
                  quote: 'As a corporate event manager, I plan 20+ events a year. EventEase cut my vendor coordination time by half. The in-app messaging is a game changer.',
                  name: 'Kevin Lim',
                  role: 'Corporate Events Manager, PJ',
                  initials: 'KL',
                },
                {
                  stars: '★★★★★',
                  quote: 'The QR code guest check-in was seamless at our gala dinner. Our guests were impressed, and I had real-time attendance data on my phone the whole night.',
                  name: 'Nurul Hana',
                  role: 'Wedding Planner, Penang',
                  initials: 'NH',
                },
              ].map((t) => (
                <article key={t.name} className="testimonial-card">
                  <div className="testimonial-stars" aria-label="5 stars">{t.stars}</div>
                  <blockquote>&quot;{t.quote}&quot;</blockquote>
                  <div className="testimonial-author">
                    <div className="author-avatar" aria-hidden="true">{t.initials}</div>
                    <div className="author-info">
                      <strong>{t.name}</strong>
                      <span>{t.role}</span>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── CTA Banner ── */}
        <section className="cta-banner" aria-label="Call to action">
          <div className="container" style={{ position: 'relative', zIndex: 1 }}>
            <h2>
              Ready to plan your{' '}
              <span className="gradient-text">perfect event?</span>
            </h2>
            <p>
              Join 5,000+ Malaysian event planners who trust EventEase. It&apos;s free to
              get started — no credit card required.
            </p>
            <div className="cta-buttons">
              <a href={`${APP_URL}/register`} className="btn-primary">
                Get started free →
              </a>
              <a href={`${APP_URL}/login`} className="btn-ghost">
                I already have an account
              </a>
            </div>
          </div>
        </section>
      </main>

      {/* ── Footer ── */}
      <footer className="footer" aria-label="Site footer">
        <div className="container">
          <div className="footer-grid">
            <div className="footer-brand">
              <a href="/" className="navbar-logo" style={{ textDecoration: 'none', display: 'inline-flex' }}>
                <span className="navbar-logo-icon">✦</span>
                EventEase
              </a>
              <p>
                Malaysia&apos;s #1 event planning platform. Connecting vendors and
                planners to create unforgettable experiences.
              </p>
            </div>
            <div className="footer-col">
              <h4>Product</h4>
              <ul>
                <li><a href="#features">Features</a></li>
                <li><a href="#pricing">Pricing</a></li>
                <li><a href={`${APP_URL}`}>Open App</a></li>
                <li><a href="#">Mobile App</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Vendors</h4>
              <ul>
                <li><a href="#">List your business</a></li>
                <li><a href="#">Vendor login</a></li>
                <li><a href="#">Success stories</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Company</h4>
              <ul>
                <li><a href="#">About us</a></li>
                <li><a href="#">Blog</a></li>
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Terms of Service</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <p>© {new Date().getFullYear()} EventEase. All rights reserved.</p>
            <div className="footer-social" aria-label="Social media links">
              <a href="https://instagram.com/eventease" aria-label="Instagram" rel="noopener noreferrer">𝕀</a>
              <a href="https://facebook.com/eventease" aria-label="Facebook" rel="noopener noreferrer">𝔽</a>
              <a href="https://twitter.com/eventease" aria-label="Twitter / X" rel="noopener noreferrer">𝕏</a>
            </div>
          </div>
        </div>
      </footer>
    </>
  )
}

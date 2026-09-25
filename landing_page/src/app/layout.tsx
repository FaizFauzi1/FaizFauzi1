import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: {
    default: 'EventEase — Malaysia\'s #1 Event Planning Platform',
    template: '%s | EventEase',
  },
  description:
    'Plan your dream event with EventEase. Discover top-rated vendors, manage your budget, and coordinate every detail — all in one place. Trusted by thousands across Malaysia.',
  keywords: [
    'event planning Malaysia',
    'wedding planner Kuala Lumpur',
    'vendor booking',
    'event management app',
    'budget tracker events',
    'wedding venues KL',
    'corporate event planner Malaysia',
    'EventEase',
  ],
  authors: [{ name: 'EventEase Team' }],
  creator: 'EventEase',
  publisher: 'EventEase',
  metadataBase: new URL('https://eventease.com'),
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    locale: 'en_MY',
    url: 'https://eventease.com',
    siteName: 'EventEase',
    title: 'EventEase — Plan Your Perfect Event in Malaysia',
    description:
      'Discover top vendors, manage your budget, and plan your dream event with EventEase. Trusted by thousands across Malaysia.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'EventEase — Event Planning Platform',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'EventEase — Plan Your Perfect Event in Malaysia',
    description:
      'Discover top vendors, manage your budget, and plan your dream event with EventEase.',
    images: ['/og-image.png'],
  },
  robots: { index: true, follow: true },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'Organization',
              name: 'EventEase',
              url: 'https://eventease.com',
              logo: 'https://eventease.com/icons/Icon-512.png',
              description: "Malaysia's #1 event planning platform for weddings, corporate events and celebrations.",
              foundingDate: '2025',
              areaServed: 'MY',
              sameAs: [
                'https://facebook.com/eventease',
                'https://instagram.com/eventease',
              ],
            }),
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  )
}

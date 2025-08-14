// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
    compatibilityDate: '2025-05-15',
    devtools: { enabled: true },
    modules: [
        '@nuxt/image',
        '@pinia/nuxt',
        'nuxt-cron'
    ],
    cron: {
        runOnInit: true,
        timeZone: 'America/Toronto',
        jobsDir: 'cron'
    },
    app: {
        head: {
            title: "WGDashboard | Simple dashboard to manage WireGuard VPN",
            htmlAttrs: {
                lang: 'en',
            },
            script: [
                {
                    src: "https://www.googletagmanager.com/gtag/js?id=G-BXCJGLTK17",
                    async: true
                },
                {
                    src: 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-2283617751904576',
                    crossorigin: 'anonymous',
                    async: true
                }
            ],
            link: [
                { rel: 'icon', type: 'image/png', href: 'https://wgdashboard-resources.tor1.cdn.digitaloceanspaces.com/Logos/Logo-2-Rounded-128x128.png' },
            ],
        },
    },
    nitro: {
        storage: {
            local: {
                driver: 'fs',
                base: './.data/db'
            }
        }
    }
})
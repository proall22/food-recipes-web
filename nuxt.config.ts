// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
	compatibilityDate: "2024-04-03",
	devtools: { enabled: false },
	css: ["~/assets/css/main.css"],
	modules: ["@nuxtjs/tailwindcss", "@nuxtjs/google-fonts"],
	ssr: false, // Disable SSR for now to avoid hydration issues
	runtimeConfig: {
		hasuraAdminSecret: process.env.HASURA_ADMIN_SECRET || "myadminsecretkey",
		jwtSecret:
			process.env.JWT_SECRET ||
			"9f3d57c29f03be8f4ad88b19c495345f5d0a219b9f78df6129ab7f60a76d879d",
		public: {
			hasuraEndpoint:
				process.env.HASURA_ENDPOINT || "http://localhost:8080/v1/graphql",
			hasuraWsEndpoint:
				process.env.HASURA_WS_ENDPOINT || "ws://localhost:8080/v1/graphql",
			backendUrl: process.env.BACKEND_URL || "http://localhost:8000",
		},
	},
	googleFonts: {
		families: {
			Inter: [300, 400, 500, 600, 700],
			"Playfair Display": [400, 500, 600, 700],
		},
	},
	tailwindcss: {
		quiet: true,
		configPath: "~/tailwind.config.js",
	},
	build: {
		transpile: ["@apollo/client", "@vue/apollo-composable"],
	},
});

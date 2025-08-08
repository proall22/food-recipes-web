import {
	ApolloClient,
	InMemoryCache,
	createHttpLink,
} from "@apollo/client/core";
import { setContext } from "@apollo/client/link/context";
import { DefaultApolloClient } from "@vue/apollo-composable";

export default defineNuxtPlugin((nuxtApp) => {
	const config = useRuntimeConfig();

	const httpLink = createHttpLink({
		uri: config.public.hasuraEndpoint,
	});

	const authLink = setContext((_, { headers }) => {
		let token = null;
		if (process.client) {
			try {
				token = localStorage.getItem("auth_token");
			} catch (error) {
				console.warn("Could not access localStorage:", error);
			}
		}

		return {
			headers: {
				...headers,
				"x-hasura-admin-secret": "myadminsecretkey", // For development only
				...(token && {
					Authorization: `Bearer ${token}`,
					"X-Hasura-Role": "user",
				}),
			},
		};
	});

	const apolloClient = new ApolloClient({
		link: authLink.concat(httpLink),
		cache: new InMemoryCache(),
		defaultOptions: {
			watchQuery: {
				errorPolicy: "all",
			},
			query: {
				errorPolicy: "all",
			},
		},
	});

	// Provide the Apollo client to the app
	nuxtApp.vueApp.provide(DefaultApolloClient, apolloClient);

	return {
		provide: {
			apollo: apolloClient,
		},
	};
});

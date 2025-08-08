export default defineNuxtRouteMiddleware((to, from) => {
	const { isAuthenticated } = useAuth();

	if (!isAuthenticated.value) {
		throw createError({
			statusCode: 401,
			statusMessage: "You must be logged in to access this page",
		});
	}
});

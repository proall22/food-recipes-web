import { ref, computed } from "vue";

interface User {
	id: string;
	email: string;
	username: string;
	full_name: string;
	avatar_url?: string;
	bio?: string;
}

interface AuthState {
	user: User | null;
	token: string | null;
	isAuthenticated: boolean;
}

const authState = ref<AuthState>({
	user: null,
	token: null,
	isAuthenticated: false,
});

export const useAuth = () => {
	const config = useRuntimeConfig();

	const login = async (email: string, password: string) => {
		try {
			const response = await $fetch(
				`${config.public.backendUrl}/api/v1/auth/login`,
				{
					method: "POST",
					headers: {
						"Content-Type": "application/json",
					},
					body: JSON.stringify({
						email,
						password,
					}),
				}
			);

			if (response.token && response.user) {
				authState.value.user = response.user;
				authState.value.token = response.token;
				authState.value.isAuthenticated = true;

				// Store in localStorage
				if (process.client) {
					localStorage.setItem("auth_token", response.token);
					localStorage.setItem("user", JSON.stringify(response.user));
				}

				return { success: true };
			} else {
				return { success: false, error: "Invalid response from server" };
			}
		} catch (error: any) {
			console.error("Login error:", error);
			let errorMessage = "Login failed";

			if (error.data?.error) {
				errorMessage = error.data.error;
			} else if (error.message) {
				errorMessage = error.message;
			}

			return { success: false, error: errorMessage };
		}
	};

	const register = async (userData: {
		email: string;
		username: string;
		full_name: string;
		password: string;
	}) => {
		try {
			const response = await $fetch(
				`${config.public.backendUrl}/api/v1/auth/register`,
				{
					method: "POST",
					headers: {
						"Content-Type": "application/json",
					},
					body: JSON.stringify(userData),
				}
			);

			if (response.token && response.user) {
				authState.value.user = response.user;
				authState.value.token = response.token;
				authState.value.isAuthenticated = true;

				// Store in localStorage
				if (process.client) {
					localStorage.setItem("auth_token", response.token);
					localStorage.setItem("user", JSON.stringify(response.user));
				}

				return { success: true };
			} else {
				return { success: false, error: "Invalid response from server" };
			}
		} catch (error: any) {
			console.error("Registration error:", error);
			let errorMessage = "Registration failed";

			if (error.data?.error) {
				errorMessage = error.data.error;
			} else if (error.message) {
				errorMessage = error.message;
			}

			return { success: false, error: errorMessage };
		}
	};

	const logout = () => {
		authState.value.user = null;
		authState.value.token = null;
		authState.value.isAuthenticated = false;

		if (process.client) {
			localStorage.removeItem("auth_token");
			localStorage.removeItem("user");
		}

		// Refresh the page to update the UI
		if (process.client) {
			window.location.reload();
		}
	};

	const initAuth = () => {
		if (process.client) {
			const token = localStorage.getItem("auth_token");
			const userStr = localStorage.getItem("user");

			if (token && userStr) {
				try {
					const user = JSON.parse(userStr);
					authState.value.user = user;
					authState.value.token = token;
					authState.value.isAuthenticated = true;
				} catch (error) {
					// Clear invalid data
					localStorage.removeItem("auth_token");
					localStorage.removeItem("user");
				}
			}
		}
	};

	const refreshToken = async () => {
		try {
			const response = await $fetch(
				`${config.public.backendUrl}/api/v1/auth/refresh`,
				{
					method: "POST",
					headers: {
						Authorization: `Bearer ${authState.value.token}`,
					},
				}
			);

			if (response.token) {
				authState.value.token = response.token;

				if (process.client) {
					localStorage.setItem("auth_token", response.token);
				}

				return true;
			}

			return false;
		} catch (error) {
			logout();
			return false;
		}
	};

	return {
		// State
		user: computed(() => authState.value.user),
		token: computed(() => authState.value.token),
		isAuthenticated: computed(() => authState.value.isAuthenticated),

		// Actions
		login,
		register,
		logout,
		initAuth,
		refreshToken,
	};
};

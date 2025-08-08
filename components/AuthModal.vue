<template>
	<div class="fixed inset-0 z-50 overflow-y-auto">
		<div
			class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
		>
			<div class="fixed inset-0 transition-opacity" aria-hidden="true">
				<div
					class="absolute inset-0 bg-gray-500 opacity-75"
					@click="$emit('close')"
				></div>
			</div>

			<div
				class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
			>
				<div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
					<div class="flex justify-between items-center mb-6">
						<h3 class="text-lg font-medium text-gray-900">
							{{ isSignUp ? "Create Account" : "Sign In" }}
						</h3>
						<button
							@click="$emit('close')"
							class="text-gray-400 hover:text-gray-600"
						>
							<svg
								class="w-6 h-6"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M6 18L18 6M6 6l12 12"
								></path>
							</svg>
						</button>
					</div>

					<form @submit.prevent="handleSubmit" class="space-y-4">
						<div
							v-if="error"
							class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded"
						>
							{{ error }}
						</div>

						<div
							v-if="success"
							class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded"
						>
							{{ success }}
						</div>

						<div v-if="isSignUp">
							<label
								for="full_name"
								class="block text-sm font-medium text-gray-700"
								>Full Name</label
							>
							<input
								id="full_name"
								v-model="form.full_name"
								type="text"
								required
								minlength="2"
								maxlength="100"
								class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Enter your full name"
							/>
							<p
								v-if="form.full_name && form.full_name.length < 2"
								class="mt-1 text-sm text-red-600"
							>
								Full name must be at least 2 characters long
							</p>
						</div>

						<div v-if="isSignUp">
							<label
								for="username"
								class="block text-sm font-medium text-gray-700"
								>Username</label
							>
							<input
								id="username"
								v-model="form.username"
								type="text"
								required
								minlength="3"
								maxlength="50"
								pattern="[a-zA-Z0-9_]+"
								class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Choose a username"
							/>
							<p
								v-if="form.username && form.username.length < 3"
								class="mt-1 text-sm text-red-600"
							>
								Username must be at least 3 characters long
							</p>
							<p
								v-if="form.username && !/^[a-zA-Z0-9_]+$/.test(form.username)"
								class="mt-1 text-sm text-red-600"
							>
								Username can only contain letters, numbers, and underscores
							</p>
						</div>

						<div>
							<label for="email" class="block text-sm font-medium text-gray-700"
								>Email</label
							>
							<input
								id="email"
								v-model="form.email"
								type="email"
								required
								class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Enter your email"
							/>
						</div>

						<div>
							<label
								for="password"
								class="block text-sm font-medium text-gray-700"
								>Password</label
							>
							<input
								id="password"
								v-model="form.password"
								type="password"
								required
								minlength="6"
								class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Enter your password"
							/>
							<p
								v-if="form.password && form.password.length < 6"
								class="mt-1 text-sm text-red-600"
							>
								Password must be at least 6 characters long
							</p>
						</div>

						<div v-if="isSignUp">
							<label
								for="confirmPassword"
								class="block text-sm font-medium text-gray-700"
								>Confirm Password</label
							>
							<input
								id="confirmPassword"
								v-model="form.confirmPassword"
								type="password"
								required
								class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Confirm your password"
							/>
							<p
								v-if="
									form.confirmPassword && form.password !== form.confirmPassword
								"
								class="mt-1 text-sm text-red-600"
							>
								Passwords do not match
							</p>
						</div>

						<button
							type="submit"
							class="w-full btn-primary"
							:disabled="loading || !isFormValid"
							:class="{
								'opacity-50 cursor-not-allowed': loading || !isFormValid,
							}"
						>
							{{
								loading
									? "Processing..."
									: isSignUp
									? "Create Account"
									: "Sign In"
							}}
						</button>
					</form>

					<div class="mt-6 text-center">
						<p class="text-sm text-gray-600">
							{{
								isSignUp ? "Already have an account?" : "Don't have an account?"
							}}
							<button
								@click="toggleMode"
								class="text-primary-600 hover:text-primary-500 font-medium"
							>
								{{ isSignUp ? "Sign In" : "Sign Up" }}
							</button>
						</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
defineEmits(["close"]);

const { login, register } = useAuth();

const isSignUp = ref(false);
const loading = ref(false);
const error = ref("");
const success = ref("");

const form = ref({
	full_name: "",
	username: "",
	email: "",
	password: "",
	confirmPassword: "",
});

const isFormValid = computed(() => {
	if (isSignUp.value) {
		return (
			form.value.full_name.length >= 2 &&
			form.value.username.length >= 3 &&
			/^[a-zA-Z0-9_]+$/.test(form.value.username) &&
			form.value.email.includes("@") &&
			form.value.password.length >= 6 &&
			form.value.password === form.value.confirmPassword
		);
	} else {
		return form.value.email.includes("@") && form.value.password.length >= 6;
	}
});

const toggleMode = () => {
	isSignUp.value = !isSignUp.value;
	error.value = "";
	success.value = "";
	form.value = {
		full_name: "",
		username: "",
		email: "",
		password: "",
		confirmPassword: "",
	};
};

const handleSubmit = async () => {
	error.value = "";
	success.value = "";

	if (!isFormValid.value) {
		error.value = "Please fill in all required fields correctly";
		return;
	}

	if (isSignUp.value && form.value.password !== form.value.confirmPassword) {
		error.value = "Passwords do not match";
		return;
	}

	loading.value = true;

	try {
		let result;

		if (isSignUp.value) {
			result = await register({
				email: form.value.email,
				username: form.value.username,
				full_name: form.value.full_name,
				password: form.value.password,
			});
		} else {
			result = await login(form.value.email, form.value.password);
		}

		if (result.success) {
			if (isSignUp.value) {
				success.value = "Account created successfully! Please sign in to continue.";
				setTimeout(() => {
					// Switch to login mode after successful signup
					isSignUp.value = false;
					success.value = "";
					form.value = {
						full_name: "",
						username: "",
						email: form.value.email, // Keep email for convenience
						password: "",
						confirmPassword: "",
					};
				}, 2000);
			} else {
				success.value = "Logged in successfully!";
				setTimeout(() => {
					$emit("close");
					// Navigate to dashboard after login
					navigateTo("/dashboard");
				}, 1500);
			}
		} else {
			error.value = result.error || "An error occurred";
		}
	} catch (err) {
		error.value = "An unexpected error occurred. Please try again.";
		console.error("Auth error:", err);
	} finally {
		loading.value = false;
	}
};
</script>

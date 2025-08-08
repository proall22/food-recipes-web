<template>
	<div class="py-8">
		<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="mb-8">
				<nav class="flex mb-4" aria-label="Breadcrumb">
					<ol class="flex items-center space-x-4">
						<li>
							<NuxtLink to="/" class="text-gray-500 hover:text-gray-700">Home</NuxtLink>
						</li>
						<li><ChevronRightIcon class="w-4 h-4 text-gray-400" /></li>
						<li>
							<NuxtLink to="/recipes" class="text-gray-500 hover:text-gray-700">Recipes</NuxtLink>
						</li>
						<li><ChevronRightIcon class="w-4 h-4 text-gray-400" /></li>
						<li>
							<NuxtLink :to="`/recipes/${recipeId}`" class="text-gray-500 hover:text-gray-700">
								{{ recipe?.title }}
							</NuxtLink>
						</li>
						<li><ChevronRightIcon class="w-4 h-4 text-gray-400" /></li>
						<li class="text-gray-900 font-medium">Purchase</li>
					</ol>
				</nav>

				<h1 class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4">
					Purchase Recipe
				</h1>
			</div>

			<div v-if="loading" class="animate-pulse">
				<div class="h-64 bg-gray-300 rounded-xl mb-6"></div>
				<div class="h-8 bg-gray-300 rounded mb-4"></div>
				<div class="h-32 bg-gray-300 rounded"></div>
			</div>

			<div v-else-if="recipe" class="space-y-8">
				<!-- Recipe Preview -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
					<div class="md:flex">
						<div class="md:w-1/3">
							<img
								:src="recipe.featured_image_url || 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400'"
								:alt="recipe.title"
								class="w-full h-48 md:h-full object-cover"
							/>
						</div>
						<div class="p-6 md:w-2/3">
							<h2 class="text-2xl font-bold font-serif text-gray-900 mb-2">
								{{ recipe.title }}
							</h2>
							<p class="text-gray-600 mb-4">{{ recipe.description }}</p>
							
							<div class="flex items-center space-x-4 text-sm text-gray-500 mb-4">
								<div class="flex items-center">
									<ClockIcon class="w-4 h-4 mr-1" />
									{{ recipe.prep_time + (recipe.cook_time || 0) }}m
								</div>
								<div class="flex items-center">
									<UsersIcon class="w-4 h-4 mr-1" />
									{{ recipe.servings }} servings
								</div>
								<div class="flex items-center">
									<StarIcon class="w-4 h-4 mr-1" />
									{{ (recipe.average_rating || 0).toFixed(1) }}
								</div>
							</div>

							<div class="flex items-center justify-between">
								<div class="text-3xl font-bold text-primary-600">
									${{ recipe.price }}
								</div>
								<div class="text-sm text-gray-500">
									by {{ recipe.user.full_name }}
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Payment Form -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<h3 class="text-xl font-semibold text-gray-900 mb-6">Payment Details</h3>
					
					<form @submit.prevent="handlePurchase" class="space-y-6">
						<div>
							<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
								Email Address
							</label>
							<input
								id="email"
								v-model="paymentForm.email"
								type="email"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								:placeholder="user?.email"
							/>
						</div>

						<div>
							<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
								Phone Number
							</label>
							<input
								id="phone"
								v-model="paymentForm.phone"
								type="tel"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="+251912345678"
							/>
						</div>

						<div>
							<label for="firstName" class="block text-sm font-medium text-gray-700 mb-2">
								First Name
							</label>
							<input
								id="firstName"
								v-model="paymentForm.firstName"
								type="text"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<div>
							<label for="lastName" class="block text-sm font-medium text-gray-700 mb-2">
								Last Name
							</label>
							<input
								id="lastName"
								v-model="paymentForm.lastName"
								type="text"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>

						<!-- Order Summary -->
						<div class="border-t border-gray-200 pt-6">
							<h4 class="text-lg font-medium text-gray-900 mb-4">Order Summary</h4>
							<div class="flex justify-between items-center mb-2">
								<span class="text-gray-600">Recipe: {{ recipe.title }}</span>
								<span class="font-medium">${{ recipe.price }}</span>
							</div>
							<div class="flex justify-between items-center mb-2">
								<span class="text-gray-600">Processing Fee</span>
								<span class="font-medium">$0.00</span>
							</div>
							<div class="border-t border-gray-200 pt-2">
								<div class="flex justify-between items-center">
									<span class="text-lg font-semibold text-gray-900">Total</span>
									<span class="text-lg font-semibold text-primary-600">${{ recipe.price }}</span>
								</div>
							</div>
						</div>

						<div class="flex space-x-4">
							<NuxtLink :to="`/recipes/${recipeId}`" class="btn-secondary flex-1 text-center">
								Cancel
							</NuxtLink>
							<button
								type="submit"
								:disabled="processing"
								class="btn-primary flex-1"
							>
								{{ processing ? 'Processing...' : `Pay $${recipe.price}` }}
							</button>
						</div>
					</form>
				</div>

				<!-- Payment Methods -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<h3 class="text-lg font-semibold text-gray-900 mb-4">Secure Payment</h3>
					<div class="flex items-center space-x-4 text-sm text-gray-600">
						<div class="flex items-center">
							<ShieldCheckIcon class="w-5 h-5 text-green-500 mr-2" />
							SSL Encrypted
						</div>
						<div class="flex items-center">
							<CreditCardIcon class="w-5 h-5 text-blue-500 mr-2" />
							Chapa Secure
						</div>
						<div class="flex items-center">
							<LockClosedIcon class="w-5 h-5 text-gray-500 mr-2" />
							100% Safe
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
import {
	ChevronRightIcon,
	ClockIcon,
	UsersIcon,
	StarIcon,
	ShieldCheckIcon,
	CreditCardIcon,
	LockClosedIcon,
} from "@heroicons/vue/24/outline";

// Protect this route
definePageMeta({
	middleware: "auth",
});

const route = useRoute();
const { user } = useAuth();
const recipeId = route.params.id;

const recipe = ref(null);
const loading = ref(true);
const processing = ref(false);

const paymentForm = ref({
	email: "",
	phone: "",
	firstName: "",
	lastName: "",
});

// Load recipe data
onMounted(async () => {
	try {
		// TODO: Replace with actual GraphQL query
		await new Promise(resolve => setTimeout(resolve, 1000));
		
		recipe.value = {
			id: recipeId,
			title: "Premium Chocolate Soufflé",
			description: "An elegant French dessert with step-by-step instructions",
			featured_image_url: "https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=400",
			price: 9.99,
			prep_time: 30,
			cook_time: 25,
			servings: 4,
			average_rating: 4.8,
			user: {
				full_name: "Chef Marie",
			},
		};

		// Pre-fill form with user data
		if (user.value) {
			paymentForm.value.email = user.value.email;
			const nameParts = user.value.full_name?.split(' ') || [];
			paymentForm.value.firstName = nameParts[0] || '';
			paymentForm.value.lastName = nameParts.slice(1).join(' ') || '';
		}
	} catch (error) {
		console.error("Failed to load recipe:", error);
	} finally {
		loading.value = false;
	}
});

const handlePurchase = async () => {
	processing.value = true;
	
	try {
		// TODO: Implement Chapa payment integration
		const paymentData = {
			recipe_id: recipeId,
			amount: recipe.value.price,
			email: paymentForm.value.email,
			phone: paymentForm.value.phone,
			first_name: paymentForm.value.firstName,
			last_name: paymentForm.value.lastName,
			callback_url: `${window.location.origin}/payment/callback`,
			return_url: `${window.location.origin}/recipes/${recipeId}`,
		};

		// Simulate payment processing
		await new Promise(resolve => setTimeout(resolve, 2000));
		
		// Redirect to success page or back to recipe
		navigateTo(`/recipes/${recipeId}?purchased=true`);
	} catch (error) {
		console.error("Payment failed:", error);
		alert("Payment failed. Please try again.");
	} finally {
		processing.value = false;
	}
};

// Meta tags
useHead({
	title: `Purchase Recipe - RecipeHub`,
	meta: [
		{ name: "description", content: "Purchase premium recipe access" },
	],
});
</script>
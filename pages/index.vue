<template>
	<div>
		<!-- Hero Section -->
		<section
			class="relative bg-gradient-to-br from-primary-50 to-secondary-50 py-20"
		>
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
					<div>
						<h1
							class="text-4xl md:text-6xl font-bold font-serif text-gray-900 mb-6"
						>
							Discover & Share
							<span class="text-primary-600">Amazing Recipes</span>
						</h1>
						<p class="text-xl text-gray-600 mb-8 leading-relaxed">
							Join our community of food lovers. Explore thousands of delicious
							recipes, share your culinary creations, and connect with fellow
							food enthusiasts.
						</p>
						<div class="flex flex-col sm:flex-row gap-4">
							<NuxtLink
								to="/recipes"
								class="btn-primary text-lg px-8 py-3 text-center"
							>
								Explore Recipes
							</NuxtLink>
							<NuxtLink
								to="/create-recipe"
								class="btn-secondary text-lg px-8 py-3 text-center"
							>
								Share Your Recipe
							</NuxtLink>
						</div>
					</div>
					<div class="relative">
						<div class="grid grid-cols-2 gap-4">
							<img
								src="https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400"
								alt="Delicious pasta"
								class="rounded-xl shadow-lg"
							/>
							<img
								src="https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=400"
								alt="Fresh salad"
								class="rounded-xl shadow-lg mt-8"
							/>
							<img
								src="https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=400"
								alt="Gourmet burger"
								class="rounded-xl shadow-lg -mt-8"
							/>
							<img
								src="https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=400"
								alt="Dessert"
								class="rounded-xl shadow-lg"
							/>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Categories Section -->
		<section class="py-20">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="text-center mb-16">
					<h2
						class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
					>
						Browse by Category
					</h2>
					<p class="text-xl text-gray-600 max-w-2xl mx-auto">
						Find the perfect recipe for any occasion
					</p>
				</div>

				<div
					v-if="categoriesLoading"
					class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6"
				>
					<div v-for="i in 6" :key="i" class="animate-pulse">
						<div class="bg-gray-300 h-24 rounded-xl"></div>
					</div>
				</div>
				<div v-else-if="categoriesError" class="text-center py-12">
					<div class="text-red-500 text-lg">
						Error loading categories: {{ categoriesError.message }}
					</div>
				</div>
				<div
					v-else
					class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6"
				>
					<NuxtLink
						v-for="category in categories"
						:key="category.id"
						:to="`/recipes?category=${category.slug}`"
						class="group cursor-pointer"
					>
						<div
							class="card p-6 text-center group-hover:shadow-lg transition-all duration-300"
						>
							<div
								class="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-primary-100 to-secondary-100 flex items-center justify-center group-hover:scale-110 transition-transform duration-300"
							>
								<span class="text-2xl">{{ category.icon }}</span>
							</div>
							<h3 class="font-semibold text-gray-900 mb-2">
								{{ category.name }}
							</h3>
							<p class="text-sm text-gray-600">{{ category.description }}</p>
						</div>
					</NuxtLink>
				</div>
			</div>
		</section>

		<!-- Featured Recipes -->
		<section class="py-20 bg-white">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="flex justify-between items-center mb-16">
					<div>
						<h2
							class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
						>
							Featured Recipes
						</h2>
						<p class="text-xl text-gray-600">
							Hand-picked favorites from our community
						</p>
					</div>
					<NuxtLink to="/recipes" class="btn-secondary"> View All </NuxtLink>
				</div>

				<div
					v-if="recipesLoading"
					class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
				>
					<div v-for="i in 6" :key="i" class="animate-pulse">
						<div class="bg-gray-300 h-48 rounded-xl mb-4"></div>
						<div class="h-4 bg-gray-300 rounded mb-2"></div>
						<div class="h-4 bg-gray-300 rounded w-3/4"></div>
					</div>
				</div>
				<div v-else-if="recipesError" class="text-center py-12">
					<div class="text-red-500 text-lg">
						Error loading recipes: {{ recipesError.message }}
					</div>
				</div>
				<div
					v-else
					class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
				>
					<RecipeCard
						v-for="recipe in featuredRecipes"
						:key="recipe.id"
						:recipe="recipe"
					/>
				</div>
			</div>
		</section>

		<!-- Stats Section -->
		<section class="py-20 bg-gray-900 text-white">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
					<div>
						<div class="text-4xl font-bold text-primary-400 mb-2">
							{{ totalRecipes }}+
						</div>
						<div class="text-gray-300">Recipes</div>
					</div>
					<div>
						<div class="text-4xl font-bold text-primary-400 mb-2">
							{{ totalUsers }}+
						</div>
						<div class="text-gray-300">Home Chefs</div>
					</div>
					<div>
						<div class="text-4xl font-bold text-primary-400 mb-2">
							{{ totalRatings }}+
						</div>
						<div class="text-gray-300">Recipe Ratings</div>
					</div>
					<div>
						<div class="text-4xl font-bold text-primary-400 mb-2">100+</div>
						<div class="text-gray-300">Countries</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Newsletter -->
		<section class="py-20">
			<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
				<h2
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					Stay Updated
				</h2>
				<p class="text-xl text-gray-600 mb-8">
					Get the latest recipes and cooking tips delivered to your inbox
				</p>
				<form
					@submit.prevent="subscribeNewsletter"
					class="flex flex-col sm:flex-row gap-4 max-w-md mx-auto"
				>
					<input
						v-model="newsletterEmail"
						type="email"
						placeholder="Enter your email"
						required
						class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
					/>
					<button
						type="submit"
						class="btn-primary px-8 py-3"
						:disabled="subscribing"
					>
						{{ subscribing ? "Subscribing..." : "Subscribe" }}
					</button>
				</form>
			</div>
		</section>
	</div>
</template>

<script setup>
import { useCategories, useRecipes } from "~/composables/useGraphQL";

// Meta tags
useHead({
	title: "RecipeHub - Discover & Share Amazing Recipes",
	meta: [
		{
			name: "description",
			content:
				"Join our community of food lovers. Explore thousands of delicious recipes, share your culinary creations, and connect with fellow food enthusiasts.",
		},
	],
});

// Initialize data
const categories = ref([]);
const featuredRecipes = ref([]);
const categoriesLoading = ref(true);
const recipesLoading = ref(true);
const categoriesError = ref(null);
const recipesError = ref(null);

// Stats
const totalRecipes = ref(10);
const totalUsers = ref(5);
const totalRatings = ref(50);

// Newsletter subscription
const newsletterEmail = ref("");
const subscribing = ref(false);

const subscribeNewsletter = async () => {
	subscribing.value = true;
	try {
		// Implement newsletter subscription logic
		await new Promise((resolve) => setTimeout(resolve, 1000)); // Simulate API call
		newsletterEmail.value = "";
		// Show success message
	} catch (error) {
		console.error("Newsletter subscription failed:", error);
	} finally {
		subscribing.value = false;
	}
};

// Load data on mount
onMounted(async () => {
	try {
		// Load categories
		const { getCategories } = useCategories();
		const categoriesQuery = getCategories();

		// Watch for categories data
		watch(
			() => categoriesQuery.result.value,
			(newResult) => {
				if (newResult?.categories) {
					categories.value = newResult.categories;
					categoriesLoading.value = false;
				}
			},
			{ immediate: true }
		);

		watch(
			() => categoriesQuery.error.value,
			(error) => {
				if (error) {
					categoriesError.value = error;
					categoriesLoading.value = false;
				}
			},
			{ immediate: true }
		);

		// Load recipes
		const { getPopularRecipes } = useRecipes();
		const recipesQuery = getPopularRecipes(6);

		// Watch for recipes data
		watch(
			() => recipesQuery.result.value,
			(newResult) => {
				if (newResult?.recipes) {
					featuredRecipes.value = newResult.recipes;
					recipesLoading.value = false;
				}
			},
			{ immediate: true }
		);

		watch(
			() => recipesQuery.error.value,
			(error) => {
				if (error) {
					recipesError.value = error;
					recipesLoading.value = false;
				}
			},
			{ immediate: true }
		);
	} catch (error) {
		console.error("Error loading data:", error);
		categoriesLoading.value = false;
		recipesLoading.value = false;
	}
});
</script>

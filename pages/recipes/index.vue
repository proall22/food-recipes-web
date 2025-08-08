<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Header -->
			<div class="mb-8">
				<h1
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					All Recipes
				</h1>
				<p class="text-xl text-gray-600">
					Discover amazing recipes from our community
				</p>
			</div>

			<!-- Filters -->
			<div
				class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
			>
				<div class="grid grid-cols-1 md:grid-cols-4 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2"
							>Filter by Category</label
						>
						<select
							v-model="filters.category"
							@change="applyFilters"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						>
							<option value="">All Categories</option>
							<option
								v-for="category in categories"
								:key="category.id"
								:value="category.id"
							>
								{{ category.name }}
							</option>
						</select>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2"
							>Max Prep Time</label
						>
						<select
							v-model="filters.prepTime"
							@change="applyFilters"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						>
							<option value="">Any Time</option>
							<option value="15">Under 15 min</option>
							<option value="30">Under 30 min</option>
							<option value="60">Under 1 hour</option>
							<option value="120">Under 2 hours</option>
						</select>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2"
							>Difficulty</label
						>
						<select
							v-model="filters.difficulty"
							@change="applyFilters"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						>
							<option value="">All Levels</option>
							<option value="Easy">Easy</option>
							<option value="Medium">Medium</option>
							<option value="Hard">Hard</option>
						</select>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2"
							>Sort By</label
						>
						<select
							v-model="filters.sortBy"
							@change="applyFilters"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						>
							<option value="newest">Newest</option>
							<option value="popular">Most Popular</option>
							<option value="rating">Highest Rated</option>
							<option value="prepTime">Prep Time</option>
							<option value="title">Alphabetical</option>
						</select>
					</div>
				</div>

				<!-- Additional Filters -->
				<div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">
							Filter by Ingredients
						</label>
						<input
							v-model="filters.ingredients"
							@input="debouncedSearch"
							type="text"
							placeholder="e.g., chicken, tomato, cheese"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">
							Recipe Type
						</label>
						<select
							v-model="filters.recipeType"
							@change="applyFilters"
							class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
						>
							<option value="">All Recipes</option>
							<option value="free">Free Recipes</option>
							<option value="premium">Premium Recipes</option>
						</select>
					</div>

					<div class="flex items-end">
						<button
							@click="clearFilters"
							class="w-full btn-secondary"
						>
							Clear Filters
						</button>
					</div>
				</div>

				<!-- Search Bar -->
				<div class="mt-4">
					<div class="relative">
						<div
							class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
						>
							<MagnifyingGlassIcon class="h-5 w-5 text-gray-400" />
						</div>
						<input
							v-model="searchQuery"
							@input="debouncedSearch"
							type="text"
							placeholder="Search recipes by title or ingredients..."
							class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
						/>
					</div>
				</div>
			</div>

			<!-- Active Filters Display -->
			<div v-if="hasActiveFilters" class="mb-6">
				<div class="flex flex-wrap items-center gap-2">
					<span class="text-sm font-medium text-gray-700">Active filters:</span>
					<span
						v-if="filters.category"
						class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-primary-100 text-primary-800"
					>
						{{ getCategoryName(filters.category) }}
						<button @click="filters.category = ''; applyFilters()" class="ml-2 text-primary-600 hover:text-primary-800">
							×
						</button>
					</span>
					<span
						v-if="filters.difficulty"
						class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
					>
						{{ filters.difficulty }}
						<button @click="filters.difficulty = ''; applyFilters()" class="ml-2 text-blue-600 hover:text-blue-800">
							×
						</button>
					</span>
					<span
						v-if="filters.prepTime"
						class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"
					>
						Under {{ filters.prepTime }}min
						<button @click="filters.prepTime = ''; applyFilters()" class="ml-2 text-green-600 hover:text-green-800">
							×
						</button>
					</span>
					<span
						v-if="filters.ingredients"
						class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
					>
						{{ filters.ingredients }}
						<button @click="filters.ingredients = ''; applyFilters()" class="ml-2 text-yellow-600 hover:text-yellow-800">
							×
						</button>
					</span>
					<button
						@click="clearFilters"
						class="text-sm text-gray-500 hover:text-gray-700 underline"
					>
						Clear all
					</button>
				</div>
			</div>

			<!-- Recipe Grid -->
			<div v-if="!loading && recipes.length > 0" class="mb-4">
				<p class="text-sm text-gray-600">
					Showing {{ recipes.length }} of {{ totalRecipes }} recipes
				</p>
			</div>

			<div
				v-if="loading"
				class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
			>
				<div v-for="i in 9" :key="i" class="animate-pulse">
					<div class="bg-gray-300 h-48 rounded-xl mb-4"></div>
					<div class="h-4 bg-gray-300 rounded mb-2"></div>
					<div class="h-4 bg-gray-300 rounded w-3/4"></div>
				</div>
			</div>
			<div v-else-if="recipes.length === 0" class="text-center py-12">
				<MagnifyingGlassIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
				<div class="text-gray-500 text-lg mb-2">
					{{ searchQuery || hasActiveFilters ? 'No recipes found matching your criteria.' : 'No recipes available.' }}
				</div>
				<p class="text-gray-400 mb-6">
					{{ searchQuery || hasActiveFilters ? 'Try adjusting your search or filters.' : 'Be the first to share a recipe!' }}
				</p>
				<NuxtLink to="/create-recipe" class="btn-primary mt-4 inline-block">
					{{ searchQuery || hasActiveFilters ? 'Create Recipe' : 'Create Your First Recipe' }}
				</NuxtLink>
			</div>
			<div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
				<RecipeCard
					v-for="recipe in recipes"
					:key="recipe.id"
					:recipe="recipe"
				/>
			</div>

			<!-- Load More -->
			<div v-if="hasMore && !loading" class="text-center mt-12">
				<button
					@click="loadMore"
					:disabled="loadingMore"
					class="btn-secondary px-8 py-3"
				>
					{{ loadingMore ? "Loading..." : "Load More Recipes" }}
				</button>
			</div>
		</div>
	</div>
</template>

<script setup>
import { MagnifyingGlassIcon } from "@heroicons/vue/24/outline";
import { useCategories, useRecipes } from "~/composables/useGraphQL";

// Meta tags
useHead({
	title: "All Recipes - RecipeHub",
	meta: [
		{
			name: "description",
			content:
				"Browse and discover amazing recipes from our community of food lovers.",
		},
	],
});

const route = useRoute();
const { getCategories } = useCategories();
const { getRecipes, searchRecipes } = useRecipes();

// Get categories for filter
const categoriesQuery = getCategories();
const categories = computed(
	() => categoriesQuery.result.value?.categories || []
);

// Reactive data
const recipes = ref([]);
const loading = ref(false);
const loadingMore = ref(false);
const hasMore = ref(true);
const currentOffset = ref(0);
const totalRecipes = ref(0);
const limit = 12;
const searchQuery = ref("");

const filters = ref({
	category: "",
	prepTime: "",
	difficulty: "",
	sortBy: "newest",
	ingredients: "",
	recipeType: "",
});

const hasActiveFilters = computed(() => {
	return filters.value.category || 
		   filters.value.prepTime || 
		   filters.value.difficulty || 
		   filters.value.ingredients ||
		   filters.value.recipeType ||
		   searchQuery.value;
});

const getCategoryName = (categoryId) => {
	const category = categories.value.find(c => c.id === categoryId);
	return category ? category.name : '';
};

const clearFilters = () => {
	filters.value = {
		category: "",
		prepTime: "",
		difficulty: "",
		sortBy: "newest",
		ingredients: "",
		recipeType: "",
	};
	searchQuery.value = "";
	loadRecipes(true);
};

// Build GraphQL variables from filters
const buildVariables = (reset = true) => {
	const offset = reset ? 0 : currentOffset.value;
	const where = {};
	const orderBy = [];

	// Category filter
	if (filters.value.category) {
		where.category_id = { _eq: filters.value.category };
	}

	// Prep time filter
	if (filters.value.prepTime) {
		where.prep_time = { _lte: parseInt(filters.value.prepTime) };
	}

	// Difficulty filter
	if (filters.value.difficulty) {
		where.difficulty = { _eq: filters.value.difficulty };
	}

	// Recipe type filter
	if (filters.value.recipeType === 'free') {
		where.is_premium = { _eq: false };
	} else if (filters.value.recipeType === 'premium') {
		where.is_premium = { _eq: true };
	}

	// Ingredients filter (this would need to be implemented with a more complex query)
	if (filters.value.ingredients) {
		// This is a simplified version - in reality, you'd want to join with ingredients table
		where._or = [
			{ title: { _ilike: `%${filters.value.ingredients}%` } },
			{ description: { _ilike: `%${filters.value.ingredients}%` } }
		];
	}

	// Sort order
	switch (filters.value.sortBy) {
		case "popular":
			orderBy.push({ total_likes: "desc" });
			break;
		case "rating":
			orderBy.push({ average_rating: "desc" });
			break;
		case "prepTime":
			orderBy.push({ prep_time: "asc" });
			break;
		case "title":
			orderBy.push({ title: "asc" });
			break;
		default:
			orderBy.push({ created_at: "desc" });
	}

	return {
		limit,
		offset,
		where,
		order_by: orderBy,
	};
};

const loadRecipes = async (reset = true) => {
	if (reset) {
		loading.value = true;
		currentOffset.value = 0;
	} else {
		loadingMore.value = true;
	}

	try {
		const variables = buildVariables(reset);

		let result;
		if (searchQuery.value.trim()) {
			const { result: searchResult } = searchRecipes(searchQuery.value.trim());
			result = searchResult;
		} else {
			const { result: recipesResult } = getRecipes(variables);
			result = recipesResult;
		}

		await nextTick();

		if (result.value) {
			const newRecipes = searchQuery.value.trim()
				? result.value.search_recipes || []
				: result.value.recipes || [];

			if (reset) {
				recipes.value = newRecipes;
			} else {
				recipes.value.push(...newRecipes);
			}

			hasMore.value = newRecipes.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load recipes:", error);
	} finally {
		loading.value = false;
		loadingMore.value = false;
	}
};

const applyFilters = () => {
	loadRecipes(true);
};

const loadMore = () => {
	loadRecipes(false);
};

// Debounced search
let searchTimeout;
const debouncedSearch = () => {
	clearTimeout(searchTimeout);
	searchTimeout = setTimeout(() => {
		loadRecipes(true);
	}, 500);
};

// Initialize filters from URL params
onMounted(() => {
	if (route.query.category) {
		filters.value.category = route.query.category;
	}
	loadRecipes();
});

// Watch for route changes
watch(
	() => route.query,
	(newQuery) => {
		if (newQuery.category && newQuery.category !== filters.value.category) {
			filters.value.category = newQuery.category;
			loadRecipes(true);
		}
	}
);
</script>

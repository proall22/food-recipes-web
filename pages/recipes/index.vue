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
							>Category</label
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
							>Prep Time</label
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
						</select>
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

			<!-- Recipe Grid -->
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
				<div class="text-gray-500 text-lg">
					No recipes found matching your criteria.
				</div>
				<NuxtLink to="/create-recipe" class="btn-primary mt-4 inline-block">
					Create Your First Recipe
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
const limit = 12;
const searchQuery = ref("");

const filters = ref({
	category: "",
	prepTime: "",
	difficulty: "",
	sortBy: "newest",
});

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

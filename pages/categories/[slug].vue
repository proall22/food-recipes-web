<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Category Header -->
			<div v-if="loading" class="animate-pulse mb-8">
				<div class="h-8 bg-gray-300 rounded mb-4 w-1/3"></div>
				<div class="h-4 bg-gray-300 rounded w-2/3"></div>
			</div>
			<div v-else-if="category" class="mb-8">
				<nav class="flex mb-4" aria-label="Breadcrumb">
					<ol class="flex items-center space-x-4">
						<li>
							<NuxtLink to="/" class="text-gray-500 hover:text-gray-700">Home</NuxtLink>
						</li>
						<li><ChevronRightIcon class="w-4 h-4 text-gray-400" /></li>
						<li>
							<NuxtLink to="/categories" class="text-gray-500 hover:text-gray-700">Categories</NuxtLink>
						</li>
						<li><ChevronRightIcon class="w-4 h-4 text-gray-400" /></li>
						<li class="text-gray-900 font-medium">{{ category.name }}</li>
					</ol>
				</nav>

				<div class="flex items-center space-x-4 mb-6">
					<div class="w-16 h-16 rounded-full bg-gradient-to-br from-primary-100 to-secondary-100 flex items-center justify-center">
						<span class="text-3xl">{{ category.icon }}</span>
					</div>
					<div>
						<h1 class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-2">
							{{ category.name }} Recipes
						</h1>
						<p class="text-xl text-gray-600">{{ category.description }}</p>
					</div>
				</div>

				<div class="flex items-center justify-between">
					<p class="text-gray-500">
						{{ totalRecipes }} {{ totalRecipes === 1 ? 'recipe' : 'recipes' }} found
					</p>
					<select
						v-model="sortBy"
						@change="loadRecipes(true)"
						class="border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
					>
						<option value="newest">Newest First</option>
						<option value="popular">Most Popular</option>
						<option value="rating">Highest Rated</option>
						<option value="prepTime">Quick & Easy</option>
					</select>
				</div>
			</div>

			<!-- Recipes Grid -->
			<div
				v-if="recipesLoading"
				class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
			>
				<div v-for="i in 9" :key="i" class="animate-pulse">
					<div class="bg-gray-300 h-48 rounded-xl mb-4"></div>
					<div class="h-4 bg-gray-300 rounded mb-2"></div>
					<div class="h-4 bg-gray-300 rounded w-3/4"></div>
				</div>
			</div>
			<div v-else-if="recipes.length === 0" class="text-center py-12">
				<div class="text-6xl mb-4">{{ category?.icon || '🍽️' }}</div>
				<div class="text-gray-500 text-lg mb-2">No {{ category?.name.toLowerCase() }} recipes yet</div>
				<p class="text-gray-400 mb-6">Be the first to share a {{ category?.name.toLowerCase() }} recipe!</p>
				<NuxtLink to="/create-recipe" class="btn-primary">
					Create Recipe
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
			<div v-if="hasMore && !recipesLoading" class="text-center mt-12">
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
import { ChevronRightIcon } from "@heroicons/vue/24/outline";
import { useCategories, useRecipes } from "~/composables/useGraphQL";

const route = useRoute();
const categorySlug = route.params.slug;

// Reactive data
const category = ref(null);
const recipes = ref([]);
const loading = ref(true);
const recipesLoading = ref(false);
const loadingMore = ref(false);
const hasMore = ref(true);
const totalRecipes = ref(0);
const currentOffset = ref(0);
const sortBy = ref("newest");
const limit = 12;

// Load category data
const loadCategory = async () => {
	try {
		// TODO: Replace with actual GraphQL query
		const { getCategories } = useCategories();
		const { result } = getCategories();
		
		await nextTick();
		
		if (result.value?.categories) {
			category.value = result.value.categories.find(c => c.slug === categorySlug);
		}

		if (category.value) {
			// Set page title
			useHead({
				title: `${category.value.name} Recipes - RecipeHub`,
				meta: [
					{
						name: "description",
						content: `Discover delicious ${category.value.name.toLowerCase()} recipes shared by our community.`,
					},
				],
			});
		}
	} catch (error) {
		console.error("Failed to load category:", error);
		throw createError({
			statusCode: 404,
			statusMessage: "Category not found",
		});
	} finally {
		loading.value = false;
	}
};

// Load recipes for this category
const { getRecipes } = useRecipes();

const loadRecipes = async (reset = true) => {
	if (reset) {
		recipesLoading.value = true;
		currentOffset.value = 0;
		recipes.value = [];
	} else {
		loadingMore.value = true;
	}

	try {
		const orderBy = getOrderBy();
		const { result } = await getRecipes({
			limit,
			offset: currentOffset.value,
			where: {
				category: { slug: { _eq: categorySlug } },
				is_published: { _eq: true },
			},
			order_by: orderBy,
		});

		if (result.value?.recipes) {
			if (reset) {
				recipes.value = result.value.recipes;
				totalRecipes.value = result.value.recipes.length; // This should come from aggregate query
			} else {
				recipes.value.push(...result.value.recipes);
			}

			hasMore.value = result.value.recipes.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load recipes:", error);
	} finally {
		recipesLoading.value = false;
		loadingMore.value = false;
	}
};

const getOrderBy = () => {
	switch (sortBy.value) {
		case "popular":
			return [{ total_likes: "desc" }, { created_at: "desc" }];
		case "rating":
			return [{ average_rating: "desc" }, { created_at: "desc" }];
		case "prepTime":
			return [{ prep_time: "asc" }, { created_at: "desc" }];
		default:
			return [{ created_at: "desc" }];
	}
};

const loadMore = () => {
	loadRecipes(false);
};

// Load data on mount
onMounted(async () => {
	await loadCategory();
	if (category.value) {
		loadRecipes();
	}
});
</script>
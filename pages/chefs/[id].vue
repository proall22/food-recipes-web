<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Chef Profile Header -->
			<div v-if="loading" class="animate-pulse">
				<div class="bg-gray-300 h-64 rounded-xl mb-8"></div>
			</div>
			<div
				v-else-if="chef"
				class="bg-white rounded-xl shadow-sm border border-gray-200 p-8 mb-8"
			>
				<div
					class="flex flex-col md:flex-row items-center md:items-start gap-8"
				>
					<div
						class="w-32 h-32 rounded-full overflow-hidden bg-gray-200 flex-shrink-0"
					>
						<img
							v-if="chef.avatar_url"
							:src="chef.avatar_url"
							:alt="chef.full_name"
							class="w-full h-full object-cover"
						/>
						<div
							v-else
							class="w-full h-full flex items-center justify-center bg-primary-100 text-primary-600 text-4xl font-bold"
						>
							{{ chef.full_name?.charAt(0) || "U" }}
						</div>
					</div>

					<div class="flex-1 text-center md:text-left">
						<h1
							class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-2"
						>
							{{ chef.full_name }}
						</h1>
						<p class="text-xl text-gray-600 mb-4">@{{ chef.username }}</p>
						<p v-if="chef.bio" class="text-gray-700 mb-6">{{ chef.bio }}</p>

						<div
							class="flex flex-wrap justify-center md:justify-start gap-6 text-sm"
						>
							<div class="text-center">
								<div class="text-2xl font-bold text-primary-600">
									{{ chef.recipe_count || 0 }}
								</div>
								<div class="text-gray-500">Recipes</div>
							</div>
							<div class="text-center">
								<div class="text-2xl font-bold text-primary-600">
									{{ chef.total_likes || 0 }}
								</div>
								<div class="text-gray-500">Likes</div>
							</div>
							<div class="text-center">
								<div class="text-2xl font-bold text-primary-600">
									{{ chef.followers_count || 0 }}
								</div>
								<div class="text-gray-500">Followers</div>
							</div>
						</div>
					</div>

					<div v-if="!isOwnProfile" class="flex flex-col gap-3">
						<button class="btn-primary">Follow</button>
						<button class="btn-secondary">Message</button>
					</div>
				</div>
			</div>

			<!-- Chef's Recipes -->
			<div class="mb-8">
				<div class="flex justify-between items-center mb-6">
					<h2 class="text-2xl font-bold font-serif text-gray-900">
						{{ chef?.full_name }}'s Recipes
					</h2>

					<!-- Filter Options -->
					<select
						v-model="recipeSort"
						@change="loadRecipes"
						class="border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
					>
						<option value="newest">Newest</option>
						<option value="popular">Most Popular</option>
						<option value="rating">Highest Rated</option>
					</select>
				</div>

				<!-- Recipes Grid -->
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
				<div v-else-if="recipes.length === 0" class="text-center py-12">
					<div class="text-gray-500 text-lg">No recipes found.</div>
				</div>
				<div
					v-else
					class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
				>
					<RecipeCard
						v-for="recipe in recipes"
						:key="recipe.id"
						:recipe="recipe"
					/>
				</div>

				<!-- Load More Recipes -->
				<div v-if="hasMoreRecipes && !recipesLoading" class="text-center mt-12">
					<button
						@click="loadMoreRecipes"
						:disabled="loadingMoreRecipes"
						class="btn-secondary px-8 py-3"
					>
						{{ loadingMoreRecipes ? "Loading..." : "Load More Recipes" }}
					</button>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
import { useRecipes } from "~/composables/useGraphQL";

const route = useRoute();
const { user } = useAuth();

// Reactive data
const chef = ref(null);
const loading = ref(true);
const recipes = ref([]);
const recipesLoading = ref(false);
const loadingMoreRecipes = ref(false);
const hasMoreRecipes = ref(true);
const currentOffset = ref(0);
const recipeSort = ref("newest");
const limit = 9;

const isOwnProfile = computed(() => user.value?.id === chef.value?.id);

// Load chef profile
const loadChef = async () => {
	try {
		const { data } = await $fetch("/api/graphql", {
			method: "POST",
			body: {
				query: `
          query GetChef($id: uuid!) {
            users_by_pk(id: $id) {
              id
              username
              full_name
              avatar_url
              bio
              created_at
              recipe_count
              total_likes
              followers_count
            }
          }
        `,
				variables: {
					id: route.params.id,
				},
			},
		});

		chef.value = data?.users_by_pk;

		if (chef.value) {
			// Set page title
			useHead({
				title: `${chef.value.full_name} - RecipeHub`,
				meta: [
					{
						name: "description",
						content: `Discover amazing recipes by ${chef.value.full_name} on RecipeHub.`,
					},
				],
			});
		}
	} catch (error) {
		console.error("Failed to load chef:", error);
		throw createError({
			statusCode: 404,
			statusMessage: "Chef not found",
		});
	} finally {
		loading.value = false;
	}
};

// Load chef's recipes
const { getRecipes } = useRecipes();

const loadRecipes = async (reset = true) => {
	if (reset) {
		recipesLoading.value = true;
		currentOffset.value = 0;
		recipes.value = [];
	} else {
		loadingMoreRecipes.value = true;
	}

	try {
		const orderBy = getRecipeOrderBy();
		const { result } = await getRecipes({
			limit,
			offset: currentOffset.value,
			where: {
				user_id: { _eq: route.params.id },
				is_published: { _eq: true },
			},
			order_by: orderBy,
		});

		if (result.value?.recipes) {
			if (reset) {
				recipes.value = result.value.recipes;
			} else {
				recipes.value.push(...result.value.recipes);
			}

			hasMoreRecipes.value = result.value.recipes.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load recipes:", error);
	} finally {
		recipesLoading.value = false;
		loadingMoreRecipes.value = false;
	}
};

const getRecipeOrderBy = () => {
	switch (recipeSort.value) {
		case "popular":
			return [{ total_likes: "desc" }, { created_at: "desc" }];
		case "rating":
			return [{ average_rating: "desc" }, { created_at: "desc" }];
		default:
			return [{ created_at: "desc" }];
	}
};

const loadMoreRecipes = () => {
	loadRecipes(false);
};

// Load data on mount
onMounted(async () => {
	await loadChef();
	if (chef.value) {
		loadRecipes();
	}
});
</script>

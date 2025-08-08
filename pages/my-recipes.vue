<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Header -->
			<div class="flex justify-between items-center mb-8">
				<div>
					<h1
						class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
					>
						My Recipes
					</h1>
					<p class="text-xl text-gray-600">Manage your recipe collection</p>
				</div>
				<NuxtLink to="/create-recipe" class="btn-primary">
					<PlusIcon class="w-5 h-5 mr-2" />
					Create New Recipe
				</NuxtLink>
			</div>

			<!-- Filter Tabs -->
			<div
				class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
			>
				<div class="flex flex-wrap gap-4">
					<button
						v-for="tab in tabs"
						:key="tab.key"
						@click="
							activeTab = tab.key;
							loadRecipes();
						"
						:class="[
							'px-4 py-2 rounded-lg font-medium transition-colors',
							activeTab === tab.key
								? 'bg-primary-600 text-white'
								: 'bg-gray-100 text-gray-700 hover:bg-gray-200',
						]"
					>
						{{ tab.label }} ({{ tab.count || 0 }})
					</button>
				</div>
			</div>

			<!-- Recipes Grid -->
			<div
				v-if="loading"
				class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
			>
				<div v-for="i in 6" :key="i" class="animate-pulse">
					<div class="bg-gray-300 h-48 rounded-xl mb-4"></div>
					<div class="h-4 bg-gray-300 rounded mb-2"></div>
					<div class="h-4 bg-gray-300 rounded w-3/4"></div>
				</div>
			</div>
			<div v-else-if="recipes.length === 0" class="text-center py-12">
				<div class="text-gray-500 text-lg mb-4">
					{{ getEmptyMessage() }}
				</div>
				<NuxtLink to="/create-recipe" class="btn-primary">
					Create Your First Recipe
				</NuxtLink>
			</div>
			<div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
				<div
					v-for="recipe in recipes"
					:key="recipe.id"
					class="recipe-card relative"
				>
					<RecipeCard :recipe="recipe" />

					<!-- Recipe Actions -->
					<div class="absolute top-3 left-3 flex space-x-2">
						<NuxtLink
							:to="`/recipes/${recipe.id}/edit`"
							class="w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all duration-200"
						>
							<PencilIcon class="w-4 h-4 text-gray-600" />
						</NuxtLink>
						<button
							@click="deleteRecipe(recipe.id)"
							class="w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all duration-200 text-red-600"
						>
							<TrashIcon class="w-4 h-4" />
						</button>
					</div>

					<!-- Status Badge -->
					<div class="absolute bottom-3 right-3">
						<span
							:class="[
								'text-xs font-medium px-2 py-1 rounded-full',
								recipe.is_published
									? 'bg-green-100 text-green-800'
									: 'bg-yellow-100 text-yellow-800',
							]"
						>
							{{ recipe.is_published ? "Published" : "Draft" }}
						</span>
					</div>
				</div>
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
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/vue/24/outline";
import { useRecipes } from "~/composables/useGraphQL";

// Protect this route
definePageMeta({
	middleware: "auth",
});

// Meta tags
useHead({
	title: "My Recipes - RecipeHub",
	meta: [
		{
			name: "description",
			content: "Manage your recipe collection on RecipeHub.",
		},
	],
});

const { user } = useAuth();
const { getRecipes, deleteRecipe: deleteRecipeMutation } = useRecipes();

// Reactive data
const recipes = ref([]);
const loading = ref(false);
const loadingMore = ref(false);
const hasMore = ref(true);
const currentOffset = ref(0);
const limit = 12;
const activeTab = ref("all");

const tabs = ref([
	{ key: "all", label: "All Recipes", count: 0 },
	{ key: "published", label: "Published", count: 0 },
	{ key: "drafts", label: "Drafts", count: 0 },
	{ key: "premium", label: "Premium", count: 0 },
]);

// Build where clause based on active tab
const buildWhereClause = () => {
	const baseWhere = { user_id: { _eq: user.value?.id } };

	switch (activeTab.value) {
		case "published":
			return { ...baseWhere, is_published: { _eq: true } };
		case "drafts":
			return { ...baseWhere, is_published: { _eq: false } };
		case "premium":
			return { ...baseWhere, is_premium: { _eq: true } };
		default:
			return baseWhere;
	}
};

// Load recipes
const loadRecipes = async (reset = true) => {
	if (reset) {
		loading.value = true;
		currentOffset.value = 0;
		recipes.value = [];
	} else {
		loadingMore.value = true;
	}

	try {
		const { result } = await getRecipes({
			limit,
			offset: currentOffset.value,
			where: buildWhereClause(),
			order_by: [{ created_at: "desc" }],
		});

		if (result.value?.recipes) {
			if (reset) {
				recipes.value = result.value.recipes;
			} else {
				recipes.value.push(...result.value.recipes);
			}

			hasMore.value = result.value.recipes.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load recipes:", error);
	} finally {
		loading.value = false;
		loadingMore.value = false;
	}
};

// Load recipe counts for tabs
const loadRecipeCounts = async () => {
	try {
		// This would be actual GraphQL queries to get counts
		tabs.value[0].count = recipes.value.length; // All
		tabs.value[1].count = recipes.value.filter((r) => r.is_published).length; // Published
		tabs.value[2].count = recipes.value.filter((r) => !r.is_published).length; // Drafts
		tabs.value[3].count = recipes.value.filter((r) => r.is_premium).length; // Premium
	} catch (error) {
		console.error("Failed to load recipe counts:", error);
	}
};

const loadMore = () => {
	loadRecipes(false);
};

const deleteRecipe = async (recipeId) => {
	if (
		!confirm(
			"Are you sure you want to delete this recipe? This action cannot be undone."
		)
	) {
		return;
	}

	try {
		await deleteRecipeMutation().mutate({ id: recipeId });
		recipes.value = recipes.value.filter((r) => r.id !== recipeId);
		loadRecipeCounts();
	} catch (error) {
		console.error("Failed to delete recipe:", error);
		alert("Failed to delete recipe. Please try again.");
	}
};

const getEmptyMessage = () => {
	switch (activeTab.value) {
		case "published":
			return "No published recipes yet.";
		case "drafts":
			return "No draft recipes.";
		case "premium":
			return "No premium recipes yet.";
		default:
			return "No recipes yet.";
	}
};

// Load recipes on mount
onMounted(() => {
	if (user.value) {
		loadRecipes();
	}
});

// Watch for recipe changes to update counts
watch(
	recipes,
	() => {
		loadRecipeCounts();
	},
	{ deep: true }
);
</script>

<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Header -->
			<div class="mb-8">
				<h1
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					Recipe Categories
				</h1>
				<p class="text-xl text-gray-600">
					Explore recipes by category and find your next favorite dish
				</p>
			</div>

			<!-- Categories Grid -->
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
			<div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
				<NuxtLink
					v-for="category in categories"
					:key="category.id"
					:to="`/recipes?category=${category.slug}`"
					class="group cursor-pointer"
				>
					<div
						class="card overflow-hidden group-hover:shadow-lg transition-all duration-300"
					>
						<div
							class="h-48 bg-gradient-to-br from-primary-100 to-secondary-100 flex items-center justify-center group-hover:scale-105 transition-transform duration-300"
						>
							<span class="text-6xl">{{ category.icon }}</span>
						</div>
						<div class="p-6">
							<h3 class="text-xl font-semibold text-gray-900 mb-2">
								{{ category.name }}
							</h3>
							<p class="text-gray-600 mb-4">{{ category.description }}</p>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-500"
									>{{ category.recipe_count || 0 }} recipes</span
								>
								<span
									class="text-primary-600 font-medium group-hover:text-primary-700"
								>
									Explore →
								</span>
							</div>
						</div>
					</div>
				</NuxtLink>
			</div>
		</div>
	</div>
</template>

<script setup>
import { useCategories } from "~/composables/useGraphQL";

// Meta tags
useHead({
	title: "Recipe Categories - RecipeHub",
	meta: [
		{
			name: "description",
			content:
				"Browse recipes by category. Find breakfast, lunch, dinner, dessert recipes and more.",
		},
	],
});

// Get categories from GraphQL
const { getCategories } = useCategories();
const { result, loading } = getCategories();
const categories = computed(() => result.value?.categories || []);
</script>

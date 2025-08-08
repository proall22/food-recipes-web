<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Welcome Header -->
			<div class="mb-8">
				<div class="flex items-center justify-between">
					<div>
						<h1 class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-2">
							Welcome back, {{ user?.full_name || user?.username }}!
						</h1>
						<p class="text-xl text-gray-600">
							Manage your recipes and discover new favorites
						</p>
					</div>
					<NuxtLink to="/create-recipe" class="btn-primary">
						<PlusIcon class="w-5 h-5 mr-2" />
						Create Recipe
					</NuxtLink>
				</div>
			</div>

			<!-- Quick Stats -->
			<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center">
						<div class="p-3 rounded-full bg-primary-100">
							<BookOpenIcon class="w-6 h-6 text-primary-600" />
						</div>
						<div class="ml-4">
							<p class="text-sm font-medium text-gray-500">My Recipes</p>
							<p class="text-2xl font-bold text-gray-900">{{ userStats.recipes }}</p>
						</div>
					</div>
				</div>

				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center">
						<div class="p-3 rounded-full bg-red-100">
							<HeartIcon class="w-6 h-6 text-red-600" />
						</div>
						<div class="ml-4">
							<p class="text-sm font-medium text-gray-500">Total Likes</p>
							<p class="text-2xl font-bold text-gray-900">{{ userStats.totalLikes }}</p>
						</div>
					</div>
				</div>

				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center">
						<div class="p-3 rounded-full bg-yellow-100">
							<StarIcon class="w-6 h-6 text-yellow-600" />
						</div>
						<div class="ml-4">
							<p class="text-sm font-medium text-gray-500">Avg Rating</p>
							<p class="text-2xl font-bold text-gray-900">{{ userStats.avgRating.toFixed(1) }}</p>
						</div>
					</div>
				</div>

				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center">
						<div class="p-3 rounded-full bg-blue-100">
							<BookmarkIcon class="w-6 h-6 text-blue-600" />
						</div>
						<div class="ml-4">
							<p class="text-sm font-medium text-gray-500">Bookmarks</p>
							<p class="text-2xl font-bold text-gray-900">{{ userStats.bookmarks }}</p>
						</div>
					</div>
				</div>
			</div>

			<!-- Quick Actions -->
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8">
				<h2 class="text-xl font-semibold text-gray-900 mb-4">Quick Actions</h2>
				<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
					<NuxtLink
						to="/create-recipe"
						class="flex items-center p-4 border border-gray-200 rounded-lg hover:border-primary-300 hover:bg-primary-50 transition-colors"
					>
						<PlusIcon class="w-8 h-8 text-primary-600 mr-3" />
						<div>
							<h3 class="font-medium text-gray-900">Create Recipe</h3>
							<p class="text-sm text-gray-500">Share your culinary creation</p>
						</div>
					</NuxtLink>

					<NuxtLink
						to="/recipes"
						class="flex items-center p-4 border border-gray-200 rounded-lg hover:border-primary-300 hover:bg-primary-50 transition-colors"
					>
						<MagnifyingGlassIcon class="w-8 h-8 text-primary-600 mr-3" />
						<div>
							<h3 class="font-medium text-gray-900">Browse Recipes</h3>
							<p class="text-sm text-gray-500">Discover new favorites</p>
						</div>
					</NuxtLink>

					<NuxtLink
						to="/bookmarks"
						class="flex items-center p-4 border border-gray-200 rounded-lg hover:border-primary-300 hover:bg-primary-50 transition-colors"
					>
						<BookmarkIcon class="w-8 h-8 text-primary-600 mr-3" />
						<div>
							<h3 class="font-medium text-gray-900">My Bookmarks</h3>
							<p class="text-sm text-gray-500">View saved recipes</p>
						</div>
					</NuxtLink>
				</div>
			</div>

			<!-- Recent Activity -->
			<div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
				<!-- My Recent Recipes -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center justify-between mb-6">
						<h2 class="text-xl font-semibold text-gray-900">My Recent Recipes</h2>
						<NuxtLink to="/my-recipes" class="text-primary-600 hover:text-primary-700 text-sm font-medium">
							View All
						</NuxtLink>
					</div>

					<div v-if="recentRecipes.length === 0" class="text-center py-8">
						<BookOpenIcon class="w-12 h-12 text-gray-300 mx-auto mb-3" />
						<p class="text-gray-500">No recipes yet</p>
						<NuxtLink to="/create-recipe" class="text-primary-600 hover:text-primary-700 text-sm font-medium">
							Create your first recipe
						</NuxtLink>
					</div>

					<div v-else class="space-y-4">
						<div
							v-for="recipe in recentRecipes"
							:key="recipe.id"
							class="flex items-center space-x-4 p-3 rounded-lg hover:bg-gray-50"
						>
							<img
								:src="recipe.featured_image_url || 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=100'"
								:alt="recipe.title"
								class="w-12 h-12 rounded-lg object-cover"
							/>
							<div class="flex-1 min-w-0">
								<NuxtLink
									:to="`/recipes/${recipe.id}`"
									class="font-medium text-gray-900 hover:text-primary-600 truncate block"
								>
									{{ recipe.title }}
								</NuxtLink>
								<div class="flex items-center space-x-4 text-sm text-gray-500">
									<span class="flex items-center">
										<HeartIcon class="w-4 h-4 mr-1" />
										{{ recipe.total_likes || 0 }}
									</span>
									<span class="flex items-center">
										<StarIcon class="w-4 h-4 mr-1" />
										{{ (recipe.average_rating || 0).toFixed(1) }}
									</span>
								</div>
							</div>
							<span
								:class="recipe.is_published ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'"
								class="px-2 py-1 text-xs font-medium rounded-full"
							>
								{{ recipe.is_published ? 'Published' : 'Draft' }}
							</span>
						</div>
					</div>
				</div>

				<!-- Recent Bookmarks -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex items-center justify-between mb-6">
						<h2 class="text-xl font-semibold text-gray-900">Recent Bookmarks</h2>
						<NuxtLink to="/bookmarks" class="text-primary-600 hover:text-primary-700 text-sm font-medium">
							View All
						</NuxtLink>
					</div>

					<div v-if="recentBookmarks.length === 0" class="text-center py-8">
						<BookmarkIcon class="w-12 h-12 text-gray-300 mx-auto mb-3" />
						<p class="text-gray-500">No bookmarks yet</p>
						<NuxtLink to="/recipes" class="text-primary-600 hover:text-primary-700 text-sm font-medium">
							Browse recipes
						</NuxtLink>
					</div>

					<div v-else class="space-y-4">
						<div
							v-for="bookmark in recentBookmarks"
							:key="bookmark.id"
							class="flex items-center space-x-4 p-3 rounded-lg hover:bg-gray-50"
						>
							<img
								:src="bookmark.recipe.featured_image_url || 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=100'"
								:alt="bookmark.recipe.title"
								class="w-12 h-12 rounded-lg object-cover"
							/>
							<div class="flex-1 min-w-0">
								<NuxtLink
									:to="`/recipes/${bookmark.recipe.id}`"
									class="font-medium text-gray-900 hover:text-primary-600 truncate block"
								>
									{{ bookmark.recipe.title }}
								</NuxtLink>
								<p class="text-sm text-gray-500">
									by {{ bookmark.recipe.user.full_name }}
								</p>
							</div>
							<div class="flex items-center space-x-2 text-sm text-gray-500">
								<StarIcon class="w-4 h-4" />
								{{ (bookmark.recipe.average_rating || 0).toFixed(1) }}
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
import {
	PlusIcon,
	BookOpenIcon,
	HeartIcon,
	StarIcon,
	BookmarkIcon,
	MagnifyingGlassIcon,
} from "@heroicons/vue/24/outline";

// Protect this route - only authenticated users can access
definePageMeta({
	middleware: "auth",
});

// Meta tags
useHead({
	title: "Dashboard - RecipeHub",
	meta: [
		{
			name: "description",
			content: "Your personal recipe dashboard on RecipeHub.",
		},
	],
});

const { user } = useAuth();

// Reactive data
const userStats = ref({
	recipes: 0,
	totalLikes: 0,
	avgRating: 0,
	bookmarks: 0,
});

const recentRecipes = ref([]);
const recentBookmarks = ref([]);
const loading = ref(true);

// Load dashboard data
const loadDashboardData = async () => {
	try {
		// TODO: Replace with actual GraphQL queries
		// For now, using mock data
		userStats.value = {
			recipes: 3,
			totalLikes: 24,
			avgRating: 4.2,
			bookmarks: 8,
		};

		recentRecipes.value = [
			{
				id: "1",
				title: "Chocolate Chip Cookies",
				featured_image_url: "https://images.pexels.com/photos/230325/pexels-photo-230325.jpeg?auto=compress&cs=tinysrgb&w=100",
				total_likes: 15,
				average_rating: 4.5,
				is_published: true,
			},
			{
				id: "2",
				title: "Spaghetti Carbonara",
				featured_image_url: "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=100",
				total_likes: 9,
				average_rating: 4.0,
				is_published: false,
			},
		];

		recentBookmarks.value = [
			{
				id: "1",
				recipe: {
					id: "3",
					title: "Classic Pancakes",
					featured_image_url: "https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=100",
					average_rating: 4.8,
					user: {
						full_name: "John Smith",
					},
				},
			},
		];
	} catch (error) {
		console.error("Failed to load dashboard data:", error);
	} finally {
		loading.value = false;
	}
};

// Load data on mount
onMounted(() => {
	if (user.value) {
		loadDashboardData();
	}
});
</script>
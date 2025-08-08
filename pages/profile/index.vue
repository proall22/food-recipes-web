<template>
	<div class="py-8">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Profile Header -->
			<div
				class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden mb-8"
			>
				<div
					class="h-32 bg-gradient-to-br from-primary-100 to-secondary-100"
				></div>
				<div class="relative px-8 pb-8">
					<!-- Avatar -->
					<div class="absolute -top-16 left-8">
						<div class="relative">
							<img
								v-if="user?.avatar_url"
								:src="user.avatar_url"
								:alt="user.full_name"
								class="w-32 h-32 rounded-full object-cover border-4 border-white shadow-lg"
							/>
							<div
								v-else
								class="w-32 h-32 bg-white rounded-full flex items-center justify-center border-4 border-white shadow-lg"
							>
								<span class="text-4xl font-bold text-gray-600">
									{{ user?.full_name?.charAt(0) || "U" }}
								</span>
							</div>
							<button
								@click="showAvatarUpload = true"
								class="absolute bottom-2 right-2 w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center hover:bg-primary-700 transition-colors"
							>
								<CameraIcon class="w-4 h-4" />
							</button>
						</div>
					</div>

					<!-- Profile Info -->
					<div class="pt-20">
						<div
							class="flex flex-col md:flex-row md:items-center md:justify-between"
						>
							<div class="mb-4 md:mb-0">
								<h1 class="text-3xl font-bold font-serif text-gray-900 mb-2">
									{{ user?.full_name }}
								</h1>
								<p class="text-gray-600 mb-4">
									{{ user?.bio || "No bio added yet" }}
								</p>

								<!-- Stats -->
								<div class="flex items-center space-x-6 text-sm text-gray-500">
									<div class="flex items-center space-x-1">
										<BookOpenIcon class="w-5 h-5" />
										<span>{{ userStats.recipes }} recipes</span>
									</div>
									<div class="flex items-center space-x-1">
										<HeartIcon class="w-5 h-5" />
										<span>{{ userStats.likes }} likes</span>
									</div>
									<div class="flex items-center space-x-1">
										<BookmarkIcon class="w-5 h-5" />
										<span>{{ userStats.bookmarks }} bookmarks</span>
									</div>
								</div>
							</div>

							<!-- Edit Button -->
							<button @click="showEditModal = true" class="btn-primary">
								<PencilIcon class="w-4 h-4 mr-2" />
								Edit Profile
							</button>
						</div>
					</div>
				</div>
			</div>

			<!-- Tabs -->
			<div class="mb-8">
				<nav class="flex space-x-8" aria-label="Tabs">
					<button
						v-for="tab in tabs"
						:key="tab.id"
						@click="activeTab = tab.id"
						:class="
							activeTab === tab.id
								? 'border-primary-500 text-primary-600'
								: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
						"
						class="whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors"
					>
						{{ tab.name }}
						<span
							v-if="tab.count !== undefined"
							class="ml-2 bg-gray-100 text-gray-900 py-0.5 px-2.5 rounded-full text-xs"
						>
							{{ tab.count }}
						</span>
					</button>
				</nav>
			</div>

			<!-- Tab Content -->
			<div class="space-y-8">
				<!-- My Recipes Tab -->
				<div v-if="activeTab === 'recipes'">
					<div class="flex items-center justify-between mb-6">
						<h2 class="text-2xl font-bold font-serif text-gray-900">
							My Recipes
						</h2>
						<NuxtLink to="/create-recipe" class="btn-primary">
							<PlusIcon class="w-4 h-4 mr-2" />
							Create Recipe
						</NuxtLink>
					</div>

					<div v-if="myRecipes.length === 0" class="text-center py-12">
						<BookOpenIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
						<h3 class="text-lg font-medium text-gray-900 mb-2">
							No recipes yet
						</h3>
						<p class="text-gray-500 mb-6">
							Start sharing your favorite recipes with the community
						</p>
						<NuxtLink to="/create-recipe" class="btn-primary"
							>Create Your First Recipe</NuxtLink
						>
					</div>

					<div
						v-else
						class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
					>
						<div
							v-for="recipe in myRecipes"
							:key="recipe.id"
							class="recipe-card"
						>
							<div class="relative">
								<img
									:src="
										recipe.featured_image_url ||
										'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400'
									"
									:alt="recipe.title"
									class="w-full h-48 object-cover"
								/>
								<div class="absolute top-3 right-3 flex space-x-2">
									<NuxtLink
										:to="`/recipes/${recipe.id}/edit`"
										class="w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all"
									>
										<PencilIcon class="w-4 h-4 text-gray-600" />
									</NuxtLink>
									<button
										@click="deleteRecipe(recipe.id)"
										class="w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all"
									>
										<TrashIcon class="w-4 h-4 text-red-600" />
									</button>
								</div>
								<div class="absolute bottom-3 left-3">
									<span
										:class="
											recipe.is_published ? 'bg-green-500' : 'bg-yellow-500'
										"
										class="text-white text-xs font-medium px-2 py-1 rounded-full"
									>
										{{ recipe.is_published ? "Published" : "Draft" }}
									</span>
								</div>
							</div>

							<div class="p-6">
								<h3 class="text-xl font-semibold text-gray-900 mb-2 font-serif">
									{{ recipe.title }}
								</h3>
								<p class="text-gray-600 mb-4 line-clamp-2">
									{{ recipe.description }}
								</p>

								<div
									class="flex items-center justify-between text-sm text-gray-500"
								>
									<div class="flex items-center space-x-4">
										<div class="flex items-center space-x-1">
											<HeartIcon class="w-4 h-4" />
											<span>{{ recipe.total_likes || 0 }}</span>
										</div>
										<div class="flex items-center space-x-1">
											<ChatBubbleLeftIcon class="w-4 h-4" />
											<span>{{ recipe.total_comments || 0 }}</span>
										</div>
									</div>
									<span>{{ formatDate(recipe.created_at) }}</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Bookmarks Tab -->
				<div v-if="activeTab === 'bookmarks'">
					<h2 class="text-2xl font-bold font-serif text-gray-900 mb-6">
						Bookmarked Recipes
					</h2>

					<div v-if="bookmarkedRecipes.length === 0" class="text-center py-12">
						<BookmarkIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
						<h3 class="text-lg font-medium text-gray-900 mb-2">
							No bookmarks yet
						</h3>
						<p class="text-gray-500 mb-6">Save recipes you want to try later</p>
						<NuxtLink to="/recipes" class="btn-primary"
							>Browse Recipes</NuxtLink
						>
					</div>

					<div
						v-else
						class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
					>
						<RecipeCard
							v-for="recipe in bookmarkedRecipes"
							:key="recipe.id"
							:recipe="recipe"
						/>
					</div>
				</div>

				<!-- Liked Recipes Tab -->
				<div v-if="activeTab === 'liked'">
					<h2 class="text-2xl font-bold font-serif text-gray-900 mb-6">
						Liked Recipes
					</h2>

					<div v-if="likedRecipes.length === 0" class="text-center py-12">
						<HeartIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
						<h3 class="text-lg font-medium text-gray-900 mb-2">
							No liked recipes yet
						</h3>
						<p class="text-gray-500 mb-6">
							Like recipes to show your appreciation
						</p>
						<NuxtLink to="/recipes" class="btn-primary"
							>Browse Recipes</NuxtLink
						>
					</div>

					<div
						v-else
						class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
					>
						<RecipeCard
							v-for="recipe in likedRecipes"
							:key="recipe.id"
							:recipe="recipe"
						/>
					</div>
				</div>
			</div>
		</div>

		<!-- Edit Profile Modal -->
		<div v-if="showEditModal" class="fixed inset-0 z-50 overflow-y-auto">
			<div
				class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
			>
				<div class="fixed inset-0 transition-opacity" aria-hidden="true">
					<div
						class="absolute inset-0 bg-gray-500 opacity-75"
						@click="showEditModal = false"
					></div>
				</div>

				<div
					class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
				>
					<form
						@submit.prevent="updateProfile"
						class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4"
					>
						<div class="mb-6">
							<h3 class="text-lg font-medium text-gray-900 mb-4">
								Edit Profile
							</h3>

							<div class="space-y-4">
								<div>
									<label
										for="fullName"
										class="block text-sm font-medium text-gray-700 mb-2"
										>Full Name</label
									>
									<input
										id="fullName"
										v-model="editForm.full_name"
										type="text"
										required
										class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
									/>
								</div>

								<div>
									<label
										for="username"
										class="block text-sm font-medium text-gray-700 mb-2"
										>Username</label
									>
									<input
										id="username"
										v-model="editForm.username"
										type="text"
										required
										class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
									/>
								</div>

								<div>
									<label
										for="bio"
										class="block text-sm font-medium text-gray-700 mb-2"
										>Bio</label
									>
									<textarea
										id="bio"
										v-model="editForm.bio"
										rows="3"
										class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
										placeholder="Tell us about yourself..."
									></textarea>
								</div>
							</div>
						</div>

						<div class="flex justify-end space-x-3">
							<button
								type="button"
								@click="showEditModal = false"
								class="btn-secondary"
							>
								Cancel
							</button>
							<button type="submit" :disabled="updating" class="btn-primary">
								{{ updating ? "Updating..." : "Update Profile" }}
							</button>
						</div>
					</form>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup>
import {
	CameraIcon,
	BookOpenIcon,
	HeartIcon,
	BookmarkIcon,
	PencilIcon,
	PlusIcon,
	TrashIcon,
	ChatBubbleLeftIcon,
} from "@heroicons/vue/24/outline";

// Protect this route - only authenticated users can access
definePageMeta({
	middleware: "auth",
});

const { user } = useAuth();

const activeTab = ref("recipes");
const showEditModal = ref(false);
const showAvatarUpload = ref(false);
const updating = ref(false);

const editForm = ref({
	full_name: "",
	username: "",
	bio: "",
});

const userStats = ref({
	recipes: 0,
	likes: 0,
	bookmarks: 0,
});

const myRecipes = ref([]);
const bookmarkedRecipes = ref([]);
const likedRecipes = ref([]);

const tabs = computed(() => [
	{ id: "recipes", name: "My Recipes", count: userStats.value.recipes },
	{ id: "bookmarks", name: "Bookmarks", count: userStats.value.bookmarks },
	{ id: "liked", name: "Liked", count: userStats.value.likes },
]);

// Methods
const formatDate = (dateString) => {
	return new Date(dateString).toLocaleDateString("en-US", {
		year: "numeric",
		month: "short",
		day: "numeric",
	});
};

const updateProfile = async () => {
	updating.value = true;
	try {
		// TODO: Implement profile update
		console.log("Updating profile:", editForm.value);
		await new Promise((resolve) => setTimeout(resolve, 1000));
		showEditModal.value = false;
	} catch (error) {
		console.error("Failed to update profile:", error);
	} finally {
		updating.value = false;
	}
};

const deleteRecipe = async (recipeId) => {
	if (!confirm("Are you sure you want to delete this recipe?")) return;

	try {
		// TODO: Implement recipe deletion
		console.log("Deleting recipe:", recipeId);
		myRecipes.value = myRecipes.value.filter(
			(recipe) => recipe.id !== recipeId
		);
		userStats.value.recipes--;
	} catch (error) {
		console.error("Failed to delete recipe:", error);
	}
};

// Load user data
onMounted(async () => {
	try {
		// Initialize edit form with user data
		if (user.value) {
			editForm.value = {
				full_name: user.value.full_name || "",
				username: user.value.username || "",
				bio: user.value.bio || "",
			};
		}

		// TODO: Load user stats and recipes from GraphQL
		userStats.value = {
			recipes: 3,
			likes: 24,
			bookmarks: 8,
		};

		myRecipes.value = [
			{
				id: "1",
				title: "My Famous Chocolate Cake",
				description: "Rich and moist chocolate cake that everyone loves",
				featured_image_url:
					"https://images.pexels.com/photos/291528/pexels-photo-291528.jpeg?auto=compress&cs=tinysrgb&w=400",
				is_published: true,
				total_likes: 15,
				total_comments: 8,
				created_at: "2025-01-20T10:00:00Z",
			},
			{
				id: "2",
				title: "Quick Pasta Salad",
				description: "Perfect for summer picnics and potlucks",
				featured_image_url:
					"https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400",
				is_published: false,
				total_likes: 0,
				total_comments: 0,
				created_at: "2025-01-18T14:30:00Z",
			},
		];
	} catch (error) {
		console.error("Failed to load profile data:", error);
	}
});

// Meta tags
useHead({
	title: "My Profile - RecipeHub",
	meta: [
		{
			name: "description",
			content: "Manage your profile and recipes on RecipeHub",
		},
	],
});
</script>

<style scoped>
.line-clamp-2 {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}
</style>

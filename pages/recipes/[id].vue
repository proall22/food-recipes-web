<template>
	<div class="py-8">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Recipe Header -->
			<div v-if="loading" class="animate-pulse">
				<div class="bg-gray-300 h-64 rounded-xl mb-8"></div>
				<div class="h-8 bg-gray-300 rounded mb-4"></div>
				<div class="h-4 bg-gray-300 rounded w-3/4 mb-8"></div>
			</div>
			<div v-else-if="recipe" class="mb-8">
				<!-- Recipe Image -->
				<div class="relative h-64 md:h-96 rounded-xl overflow-hidden mb-6">
					<img
						:src="
							recipe.featured_image_url ||
							'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=800'
						"
						:alt="recipe.title"
						class="w-full h-full object-cover"
					/>
					<div class="absolute inset-0 bg-black bg-opacity-30 flex items-end">
						<div class="p-6 text-white">
							<div class="flex items-center space-x-2 mb-2">
								<span
									v-if="recipe.category"
									class="bg-primary-600 text-white text-sm font-medium px-3 py-1 rounded-full"
								>
									{{ recipe.category.name }}
								</span>
								<span
									v-if="recipe.is_premium"
									class="bg-yellow-500 text-white text-sm font-medium px-3 py-1 rounded-full"
								>
									Premium - ${{ recipe.price }}
								</span>
							</div>
							<h1 class="text-3xl md:text-4xl font-bold font-serif mb-2">
								{{ recipe.title }}
							</h1>
							<p class="text-lg opacity-90">{{ recipe.description }}</p>
						</div>
					</div>
				</div>

				<!-- Recipe Meta -->
				<div class="flex flex-wrap items-center justify-between gap-4 mb-8">
					<div class="flex items-center space-x-6">
						<NuxtLink
							:to="`/chefs/${recipe.user.id}`"
							class="flex items-center space-x-3 hover:text-primary-600"
						>
							<div class="w-12 h-12 rounded-full overflow-hidden bg-gray-200">
								<img
									v-if="recipe.user.avatar_url"
									:src="recipe.user.avatar_url"
									:alt="recipe.user.full_name"
									class="w-full h-full object-cover"
								/>
								<div
									v-else
									class="w-full h-full flex items-center justify-center bg-primary-100 text-primary-600 font-bold"
								>
									{{ recipe.user.full_name?.charAt(0) || "U" }}
								</div>
							</div>
							<div>
								<div class="font-medium">{{ recipe.user.full_name }}</div>
								<div class="text-sm text-gray-500">
									@{{ recipe.user.username }}
								</div>
							</div>
						</NuxtLink>

						<div class="flex items-center space-x-1">
							<StarIcon
								v-for="i in 5"
								:key="i"
								:class="
									i <= Math.floor(recipe.average_rating || 0)
										? 'text-yellow-400 fill-current'
										: 'text-gray-300'
								"
								class="w-5 h-5"
							/>
							<span class="text-sm text-gray-600 ml-2"
								>{{ (recipe.average_rating || 0).toFixed(1) }} ({{
									recipe.total_ratings || 0
								}}
								reviews)</span
							>
						</div>
					</div>

					<div class="flex items-center space-x-4">
						<button
							@click="toggleLike"
							class="flex items-center space-x-2 text-gray-600 hover:text-red-500"
						>
							<HeartIcon
								:class="isLiked ? 'text-red-500 fill-current' : ''"
								class="w-5 h-5"
							/>
							<span>{{ recipe.total_likes || 0 }}</span>
						</button>
						<button
							@click="toggleBookmark"
							class="flex items-center space-x-2 text-gray-600 hover:text-primary-600"
						>
							<BookmarkIcon
								:class="isBookmarked ? 'text-primary-600 fill-current' : ''"
								class="w-5 h-5"
							/>
							<span>Save</span>
						</button>
						<button
							class="flex items-center space-x-2 text-gray-600 hover:text-gray-800"
						>
							<ShareIcon class="w-5 h-5" />
							<span>Share</span>
						</button>
					</div>
				</div>

				<!-- Recipe Info Cards -->
				<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
					<div
						class="bg-white rounded-lg border border-gray-200 p-4 text-center"
					>
						<ClockIcon class="w-6 h-6 text-primary-600 mx-auto mb-2" />
						<div class="text-sm text-gray-500">Prep Time</div>
						<div class="font-semibold">{{ recipe.prep_time }}m</div>
					</div>
					<div
						class="bg-white rounded-lg border border-gray-200 p-4 text-center"
					>
						<FireIcon class="w-6 h-6 text-primary-600 mx-auto mb-2" />
						<div class="text-sm text-gray-500">Cook Time</div>
						<div class="font-semibold">{{ recipe.cook_time || 0 }}m</div>
					</div>
					<div
						class="bg-white rounded-lg border border-gray-200 p-4 text-center"
					>
						<UsersIcon class="w-6 h-6 text-primary-600 mx-auto mb-2" />
						<div class="text-sm text-gray-500">Servings</div>
						<div class="font-semibold">{{ recipe.servings || 1 }}</div>
					</div>
					<div
						class="bg-white rounded-lg border border-gray-200 p-4 text-center"
					>
						<ChartBarIcon class="w-6 h-6 text-primary-600 mx-auto mb-2" />
						<div class="text-sm text-gray-500">Difficulty</div>
						<div class="font-semibold">{{ recipe.difficulty }}</div>
					</div>
				</div>

				<!-- Premium Recipe Purchase -->
				<div
					v-if="recipe.is_premium && !hasPurchased"
					class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 mb-8"
				>
					<div class="flex items-center justify-between">
						<div>
							<h3 class="text-lg font-semibold text-yellow-800 mb-2">
								Premium Recipe
							</h3>
							<p class="text-yellow-700">
								Purchase this recipe to access the full ingredients list and
								cooking instructions.
							</p>
						</div>
						<button @click="purchaseRecipe" class="btn-primary">
							Buy for ${{ recipe.price }}
						</button>
					</div>
				</div>

				<!-- Ingredients -->
				<div
					v-if="!recipe.is_premium || hasPurchased"
					class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
				>
					<h2 class="text-2xl font-bold font-serif text-gray-900 mb-6">
						Ingredients
					</h2>
					<ul class="space-y-3">
						<li
							v-for="ingredient in recipe.ingredients"
							:key="ingredient.id"
							class="flex items-center"
						>
							<div class="w-2 h-2 bg-primary-600 rounded-full mr-4"></div>
							<span class="font-medium mr-2"
								>{{ ingredient.amount }} {{ ingredient.unit }}</span
							>
							<span>{{ ingredient.name }}</span>
							<span v-if="ingredient.notes" class="text-gray-500 ml-2"
								>({{ ingredient.notes }})</span
							>
						</li>
					</ul>
				</div>

				<!-- Instructions -->
				<div
					v-if="!recipe.is_premium || hasPurchased"
					class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
				>
					<h2 class="text-2xl font-bold font-serif text-gray-900 mb-6">
						Instructions
					</h2>
					<div class="space-y-6">
						<div v-for="step in recipe.steps" :key="step.id" class="flex gap-4">
							<div
								class="flex-shrink-0 w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center font-bold"
							>
								{{ step.step_number }}
							</div>
							<div class="flex-1">
								<p class="text-gray-700 leading-relaxed">
									{{ step.instruction }}
								</p>
								<img
									v-if="step.image_url"
									:src="step.image_url"
									:alt="`Step ${step.step_number}`"
									class="mt-3 rounded-lg max-w-sm"
								/>
							</div>
						</div>
					</div>
				</div>

				<!-- Rating Section -->
				<div
					v-if="isAuthenticated && (!recipe.is_premium || hasPurchased)"
					class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
				>
					<h3 class="text-lg font-semibold text-gray-900 mb-4">
						Rate this Recipe
					</h3>
					<div class="flex items-center space-x-2 mb-4">
						<button
							v-for="i in 5"
							:key="i"
							@click="rateRecipe(i)"
							class="focus:outline-none"
						>
							<StarIcon
								:class="
									i <= userRating
										? 'text-yellow-400 fill-current'
										: 'text-gray-300 hover:text-yellow-400'
								"
								class="w-6 h-6 cursor-pointer"
							/>
						</button>
						<span v-if="userRating" class="text-sm text-gray-600 ml-2"
							>You rated {{ userRating }} stars</span
						>
					</div>
				</div>

				<!-- Comments Section -->
				<div 
					v-if="!recipe.is_premium || hasPurchased"
					class="bg-white rounded-xl shadow-sm border border-gray-200 p-6"
				>
					<h3 class="text-lg font-semibold text-gray-900 mb-6">
						Comments ({{ recipe.total_comments || 0 }})
					</h3>

					<!-- Add Comment Form -->
					<div v-if="isAuthenticated" class="mb-6">
						<form @submit.prevent="addComment" class="space-y-4">
							<textarea
								v-model="newComment"
								rows="3"
								placeholder="Share your thoughts about this recipe..."
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							></textarea>
							<button
								type="submit"
								:disabled="!newComment.trim() || submittingComment"
								class="btn-primary"
							>
								{{ submittingComment ? "Posting..." : "Post Comment" }}
							</button>
						</form>
					</div>
					
					<div v-else class="mb-6 p-4 bg-gray-50 rounded-lg text-center">
						<p class="text-gray-600 mb-3">Sign in to leave a comment</p>
						<button @click="$router.push('/?auth=login')" class="btn-primary">
							Sign In
						</button>
					</div>

					<!-- Comments List -->
					<div class="space-y-6">
						<div
							v-for="comment in comments"
							:key="comment.id"
							class="flex gap-4"
						>
							<div
								class="w-10 h-10 rounded-full overflow-hidden bg-gray-200 flex-shrink-0"
							>
								<img
									v-if="comment.user.avatar_url"
									:src="comment.user.avatar_url"
									:alt="comment.user.full_name"
									class="w-full h-full object-cover"
								/>
								<div
									v-else
									class="w-full h-full flex items-center justify-center bg-primary-100 text-primary-600 font-bold text-sm"
								>
									{{ comment.user.full_name?.charAt(0) || "U" }}
								</div>
							</div>
							<div class="flex-1">
								<div class="flex items-center space-x-2 mb-1">
									<span class="font-medium">{{ comment.user.full_name }}</span>
									<span class="text-sm text-gray-500">{{
										formatDate(comment.created_at)
									}}</span>
								</div>
								<p class="text-gray-700">{{ comment.content }}</p>
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
	HeartIcon,
	BookmarkIcon,
	ShareIcon,
	StarIcon,
	ClockIcon,
	FireIcon,
	UsersIcon,
	ChartBarIcon,
} from "@heroicons/vue/24/outline";
import { useRecipes, useRecipeInteractions } from "~/composables/useGraphQL";
import { usePayments } from "~/composables/usePayments";
import { useNotifications } from "~/composables/useNotifications";

const route = useRoute();
const { user, isAuthenticated } = useAuth();
const { checkRecipePurchase } = usePayments();
const { notifyRecipeLiked, notifyRecipeCommented, notifyRecipeRated } = useNotifications();

// Reactive data
const recipe = ref(null);
const loading = ref(true);
const isLiked = ref(false);
const isBookmarked = ref(false);
const hasPurchased = ref(false);
const userRating = ref(0);
const comments = ref([]);
const newComment = ref("");
const submittingComment = ref(false);

// Load recipe
const { getRecipeById } = useRecipes();

const loadRecipe = async () => {
	try {
		const { result } = getRecipeById(route.params.id);
		
		// Watch for data changes
		watch(result, (newResult) => {
			if (newResult?.recipes_by_pk) {
				recipe.value = newResult.recipes_by_pk;
				
				// Set page title
				useHead({
					title: `${recipe.value.title} - RecipeHub`,
					meta: [{ name: "description", content: recipe.value.description }],
				});
			}
		}, { immediate: true });

		// Load user interactions if authenticated
		if (isAuthenticated.value) {
			await loadUserInteractions();
		}

		// Check if user has purchased this recipe
		if (isAuthenticated.value) {
			hasPurchased.value = await checkRecipePurchase(route.params.id);
		}

		// Load comments
		await loadComments();
	} catch (error) {
		console.error("Failed to load recipe:", error);
		throw createError({
			statusCode: 404,
			statusMessage: "Recipe not found",
		});
	} finally {
		loading.value = false;
	}
};

// Load user interactions
const { getUserRecipeInteractions } = useRecipeInteractions();

const loadUserInteractions = async () => {
	try {
		const { result } = getUserRecipeInteractions(user.value.id, route.params.id);
		
		watch(result, (newResult) => {
			if (newResult) {
				isLiked.value = newResult.likes?.length > 0;
				isBookmarked.value = newResult.bookmarks?.length > 0;
				userRating.value = newResult.ratings?.[0]?.rating || 0;
			}
		}, { immediate: true });
	} catch (error) {
		console.error("Failed to load user interactions:", error);
	}
};

// Load comments
const { getRecipeComments, subscribeToRecipeComments } = useRecipeInteractions();

const loadComments = async () => {
	try {
		const { result } = getRecipeComments(route.params.id, 10, 0);
		
		watch(result, (newResult) => {
			if (newResult?.comments) {
				comments.value = newResult.comments;
			}
		}, { immediate: true });

		// Subscribe to real-time comment updates
		const { result: commentsSubscription } = subscribeToRecipeComments(route.params.id);
		watch(commentsSubscription, (newComments) => {
			if (newComments?.comments) {
				comments.value = newComments.comments;
			}
		});
	} catch (error) {
		console.error("Failed to load comments:", error);
	}
};

// Recipe interactions
const {
	likeRecipe,
	unlikeRecipe,
	bookmarkRecipe,
	removeBookmark,
	addComment: addCommentMutation,
	rateRecipe: rateRecipeMutation,
	subscribeToRecipeLikes,
} = useRecipeInteractions();

const toggleLike = async () => {
	if (!isAuthenticated.value) return;

	try {
		const { mutate: like } = likeRecipe();
		const { mutate: unlike } = unlikeRecipe();
		
		if (isLiked.value) {
			await unlike({ recipe_id: recipe.value.id });
			recipe.value.total_likes--;
		} else {
			await like({ recipe_id: recipe.value.id });
			recipe.value.total_likes++;
			
			// Send notification to recipe owner
			await notifyRecipeLiked(recipe.value.id, user.value.id);
		}
		isLiked.value = !isLiked.value;
	} catch (error) {
		console.error("Failed to toggle like:", error);
	}
};

const toggleBookmark = async () => {
	if (!isAuthenticated.value) return;

	try {
		const { mutate: bookmark } = bookmarkRecipe();
		const { mutate: removeBookmarkMutation } = removeBookmark();
		
		if (isBookmarked.value) {
			await removeBookmarkMutation({ recipe_id: recipe.value.id });
		} else {
			await bookmark({ recipe_id: recipe.value.id });
		}
		isBookmarked.value = !isBookmarked.value;
	} catch (error) {
		console.error("Failed to toggle bookmark:", error);
	}
};

const rateRecipe = async (rating) => {
	if (!isAuthenticated.value) return;

	try {
		const { mutate: rate } = rateRecipeMutation();
		await rate({
			recipe_id: recipe.value.id,
			rating,
		});
		userRating.value = rating;
		
		// Send notification to recipe owner
		await notifyRecipeRated(recipe.value.id, user.value.id, rating);
	} catch (error) {
		console.error("Failed to rate recipe:", error);
	}
};

const addComment = async () => {
	if (!isAuthenticated.value || !newComment.value.trim()) return;

	submittingComment.value = true;
	try {
		const { mutate: addCommentMut } = addCommentMutation();
		const { data } = await addCommentMut({
			recipe_id: recipe.value.id,
			content: newComment.value.trim(),
		});

		if (data?.insert_comments_one) {
			comments.value.unshift(data.insert_comments_one);
			newComment.value = "";
			recipe.value.total_comments++;
			
			// Send notification to recipe owner
			await notifyRecipeCommented(recipe.value.id, user.value.id, newComment.value.trim());
		}
	} catch (error) {
		console.error("Failed to add comment:", error);
	} finally {
		submittingComment.value = false;
	}
};

const purchaseRecipe = async () => {
	if (!isAuthenticated.value) return;

	// Implement purchase flow with Chapa
	navigateTo(`/recipes/${recipe.value.id}/purchase`);
};

const formatDate = (dateString) => {
	return new Date(dateString).toLocaleDateString();
};

// Subscribe to real-time likes updates
onMounted(() => {
	if (route.params.id) {
		const { result: likesSubscription } = subscribeToRecipeLikes(route.params.id);
		watch(likesSubscription, (newData) => {
			if (newData?.likes_aggregate?.aggregate?.count !== undefined) {
				recipe.value.total_likes = newData.likes_aggregate.aggregate.count;
			}
		});
	}
});
// Load recipe on mount
onMounted(() => {
	loadRecipe();
});
</script>

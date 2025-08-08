<template>
	<NuxtLink :to="`/recipes/${recipe.id}`" class="recipe-card block">
		<div class="relative">
			<img
				:src="
					recipe.featured_image_url ||
					'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600'
				"
				:alt="recipe.title"
				class="w-full h-48 object-cover"
			/>
			<div class="absolute top-3 right-3">
				<button
					@click.prevent="toggleLike"
					class="w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all duration-200"
					:disabled="likingInProgress"
				>
					<svg
						:class="
							isLiked
								? 'text-red-500 fill-current'
								: 'text-gray-600 hover:text-red-500'
						"
						class="w-4 h-4"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
						></path>
					</svg>
				</button>
			</div>
			<div class="absolute bottom-3 left-3">
				<span
					v-if="recipe.category"
					class="bg-primary-600 text-white text-xs font-medium px-2 py-1 rounded-full"
				>
					{{ recipe.category.name }}
				</span>
				<span
					v-if="recipe.is_premium"
					class="bg-yellow-500 text-white text-xs font-medium px-2 py-1 rounded-full ml-2"
				>
					Premium
				</span>
			</div>
		</div>

		<div class="p-6">
			<div class="flex items-center justify-between mb-2">
				<div class="flex items-center space-x-1">
					<svg
						v-for="i in 5"
						:key="i"
						:class="
							i <= Math.floor(recipe.average_rating || 0)
								? 'text-yellow-400 fill-current'
								: 'text-gray-300'
						"
						class="w-4 h-4"
						fill="currentColor"
						viewBox="0 0 20 20"
					>
						<path
							d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
						></path>
					</svg>
					<span class="text-sm text-gray-600 ml-1">{{
						(recipe.average_rating || 0).toFixed(1)
					}}</span>
				</div>
				<div class="flex items-center text-sm text-gray-500">
					<svg
						class="w-4 h-4 mr-1"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
						></path>
					</svg>
					{{ recipe.prep_time + (recipe.cook_time || 0) }}m
				</div>
			</div>

			<h3 class="text-xl font-semibold text-gray-900 mb-2 font-serif">
				{{ recipe.title }}
			</h3>
			<p class="text-gray-600 mb-4 line-clamp-2">
				{{ recipe.description }}
			</p>

			<div class="flex items-center justify-between">
				<div class="flex items-center space-x-2">
					<img
						v-if="recipe.user?.avatar_url"
						:src="recipe.user.avatar_url"
						:alt="recipe.user.full_name"
						class="w-8 h-8 rounded-full object-cover"
					/>
					<div
						v-else
						class="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center"
					>
						<span class="text-xs font-medium text-gray-600">
							{{ recipe.user?.full_name?.charAt(0) || "U" }}
						</span>
					</div>
					<span class="text-sm text-gray-700">{{
						recipe.user?.full_name || recipe.user?.username
					}}</span>
				</div>
				<div class="flex items-center space-x-4 text-sm text-gray-500">
					<div class="flex items-center space-x-1">
						<svg
							class="w-4 h-4"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
							></path>
						</svg>
						{{ recipe.total_likes || 0 }}
					</div>
					<div class="flex items-center space-x-1">
						<svg
							class="w-4 h-4"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
							></path>
						</svg>
						{{ recipe.total_comments || 0 }}
					</div>
				</div>
			</div>

			<div
				v-if="recipe.is_premium && recipe.price"
				class="mt-4 pt-4 border-t border-gray-200"
			>
				<div class="flex items-center justify-between">
					<span class="text-lg font-semibold text-primary-600">
						${{ recipe.price }}
					</span>
					<button
						@click.prevent="buyRecipe"
						class="btn-primary text-sm px-4 py-2"
					>
						Buy Recipe
					</button>
				</div>
			</div>
		</div>
	</NuxtLink>
</template>

<script setup>
const props = defineProps({
	recipe: {
		type: Object,
		required: true,
	},
});

const likingInProgress = ref(false);
const isLiked = ref(false);

const toggleLike = async () => {
	// For now, just toggle the state
	// TODO: Implement actual like functionality when auth is working
	isLiked.value = !isLiked.value;
};

const buyRecipe = async () => {
	// TODO: Implement payment flow
	console.log("Buy recipe:", props.recipe.id);
};
</script>

<style scoped>
.line-clamp-2 {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}
</style>

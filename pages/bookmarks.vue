<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Header -->
			<div class="mb-8">
				<h1
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					My Bookmarks
				</h1>
				<p class="text-xl text-gray-600">Your saved recipes for later</p>
			</div>

			<!-- Bookmarked Recipes -->
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
			<div v-else-if="bookmarks.length === 0" class="text-center py-12">
				<BookmarkIcon class="w-16 h-16 text-gray-400 mx-auto mb-4" />
				<div class="text-gray-500 text-lg mb-4">No bookmarked recipes yet.</div>
				<p class="text-gray-400 mb-6">
					Start exploring recipes and bookmark your favorites!
				</p>
				<NuxtLink to="/recipes" class="btn-primary"> Explore Recipes </NuxtLink>
			</div>
			<div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
				<div v-for="bookmark in bookmarks" :key="bookmark.id" class="relative">
					<RecipeCard :recipe="bookmark.recipe" />

					<!-- Remove Bookmark Button -->
					<button
						@click="removeBookmark(bookmark.id)"
						class="absolute top-3 right-3 w-8 h-8 bg-white bg-opacity-90 rounded-full flex items-center justify-center hover:bg-opacity-100 transition-all duration-200 text-red-600"
					>
						<XMarkIcon class="w-4 h-4" />
					</button>

					<!-- Bookmark Date -->
					<div class="absolute bottom-3 left-3">
						<span
							class="bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded"
						>
							Saved {{ formatDate(bookmark.created_at) }}
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
					{{ loadingMore ? "Loading..." : "Load More Bookmarks" }}
				</button>
			</div>
		</div>
	</div>
</template>

<script setup>
import { BookmarkIcon, XMarkIcon } from "@heroicons/vue/24/outline";

// Protect this route
definePageMeta({
	middleware: "auth",
});

// Meta tags
useHead({
	title: "My Bookmarks - RecipeHub",
	meta: [{ name: "description", content: "Your saved recipes on RecipeHub." }],
});

const { user } = useAuth();

// Reactive data
const bookmarks = ref([]);
const loading = ref(false);
const loadingMore = ref(false);
const hasMore = ref(true);
const currentOffset = ref(0);
const limit = 12;

// Load bookmarks
const loadBookmarks = async (reset = true) => {
	if (reset) {
		loading.value = true;
		currentOffset.value = 0;
		bookmarks.value = [];
	} else {
		loadingMore.value = true;
	}

	try {
		const { data } = await $fetch("/api/graphql", {
			method: "POST",
			body: {
				query: `
          query GetBookmarks($limit: Int!, $offset: Int!, $user_id: uuid!) {
            bookmarks(
              limit: $limit, 
              offset: $offset, 
              where: { user_id: { _eq: $user_id } },
              order_by: { created_at: desc }
            ) {
              id
              created_at
              recipe {
                id
                title
                description
                prep_time
                cook_time
                difficulty
                featured_image_url
                is_premium
                price
                average_rating
                total_likes
                total_comments
                user {
                  id
                  username
                  full_name
                  avatar_url
                }
                category {
                  id
                  name
                  slug
                }
              }
            }
          }
        `,
				variables: {
					limit,
					offset: currentOffset.value,
					user_id: user.value?.id,
				},
			},
		});

		if (data?.bookmarks) {
			if (reset) {
				bookmarks.value = data.bookmarks;
			} else {
				bookmarks.value.push(...data.bookmarks);
			}

			hasMore.value = data.bookmarks.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load bookmarks:", error);
	} finally {
		loading.value = false;
		loadingMore.value = false;
	}
};

const removeBookmark = async (bookmarkId) => {
	try {
		await $fetch("/api/graphql", {
			method: "POST",
			body: {
				query: `
          mutation RemoveBookmark($id: uuid!) {
            delete_bookmarks_by_pk(id: $id) {
              id
            }
          }
        `,
				variables: {
					id: bookmarkId,
				},
			},
		});

		bookmarks.value = bookmarks.value.filter((b) => b.id !== bookmarkId);
	} catch (error) {
		console.error("Failed to remove bookmark:", error);
	}
};

const loadMore = () => {
	loadBookmarks(false);
};

const formatDate = (dateString) => {
	return new Date(dateString).toLocaleDateString();
};

// Load bookmarks on mount
onMounted(() => {
	if (user.value) {
		loadBookmarks();
	}
});
</script>

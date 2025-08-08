<template>
	<div class="py-8">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<!-- Header -->
			<div class="mb-8">
				<h1
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					Our Chefs
				</h1>
				<p class="text-xl text-gray-600">
					Meet the talented home chefs sharing their amazing recipes
				</p>
			</div>

			<!-- Search and Filter -->
			<div
				class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8"
			>
				<div class="flex flex-col md:flex-row gap-4">
					<div class="flex-1">
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
								placeholder="Search chefs by name..."
								class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>
					</div>
					<select
						v-model="sortBy"
						@change="loadChefs"
						class="border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
					>
						<option value="recipes">Most Recipes</option>
						<option value="popular">Most Popular</option>
						<option value="newest">Newest</option>
					</select>
				</div>
			</div>

			<!-- Chefs Grid -->
			<div
				v-if="loading"
				class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
			>
				<div v-for="i in 12" :key="i" class="animate-pulse">
					<div class="bg-gray-300 h-64 rounded-xl"></div>
				</div>
			</div>
			<div v-else-if="chefs.length === 0" class="text-center py-12">
				<div class="text-gray-500 text-lg">No chefs found.</div>
			</div>
			<div
				v-else
				class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
			>
				<NuxtLink
					v-for="chef in chefs"
					:key="chef.id"
					:to="`/chefs/${chef.id}`"
					class="group cursor-pointer"
				>
					<div
						class="card p-6 text-center group-hover:shadow-lg transition-all duration-300"
					>
						<div
							class="w-20 h-20 mx-auto mb-4 rounded-full overflow-hidden bg-gray-200"
						>
							<img
								v-if="chef.avatar_url"
								:src="chef.avatar_url"
								:alt="chef.full_name"
								class="w-full h-full object-cover"
							/>
							<div
								v-else
								class="w-full h-full flex items-center justify-center bg-primary-100 text-primary-600 text-2xl font-bold"
							>
								{{ chef.full_name?.charAt(0) || "U" }}
							</div>
						</div>
						<h3 class="text-lg font-semibold text-gray-900 mb-1">
							{{ chef.full_name }}
						</h3>
						<p class="text-sm text-gray-600 mb-2">@{{ chef.username }}</p>
						<p v-if="chef.bio" class="text-sm text-gray-500 mb-4 line-clamp-2">
							{{ chef.bio }}
						</p>
						<div class="flex justify-center space-x-4 text-sm text-gray-500">
							<div class="flex items-center">
								<span class="font-medium text-primary-600">{{
									chef.recipe_count || 0
								}}</span>
								<span class="ml-1">recipes</span>
							</div>
						</div>
					</div>
				</NuxtLink>
			</div>

			<!-- Load More -->
			<div v-if="hasMore && !loading" class="text-center mt-12">
				<button
					@click="loadMore"
					:disabled="loadingMore"
					class="btn-secondary px-8 py-3"
				>
					{{ loadingMore ? "Loading..." : "Load More Chefs" }}
				</button>
			</div>
		</div>
	</div>
</template>

<script setup>
import { MagnifyingGlassIcon } from "@heroicons/vue/24/outline";
import { debounce } from "lodash-es";

// Meta tags
useHead({
	title: "Our Chefs - RecipeHub",
	meta: [
		{
			name: "description",
			content:
				"Meet the talented home chefs sharing their amazing recipes on RecipeHub.",
		},
	],
});

// Reactive data
const chefs = ref([]);
const loading = ref(false);
const loadingMore = ref(false);
const hasMore = ref(true);
const currentOffset = ref(0);
const limit = 12;
const searchQuery = ref("");
const sortBy = ref("recipes");

// Load chefs function
const loadChefs = async (reset = true) => {
	if (reset) {
		loading.value = true;
		currentOffset.value = 0;
		chefs.value = [];
	} else {
		loadingMore.value = true;
	}

	try {
		// This would be a GraphQL query to get users with their recipe counts
		const { data } = await $fetch("/api/graphql", {
			method: "POST",
			body: {
				query: `
          query GetChefs($limit: Int!, $offset: Int!, $where: users_bool_exp, $order_by: [users_order_by!]) {
            users(limit: $limit, offset: $offset, where: $where, order_by: $order_by) {
              id
              username
              full_name
              avatar_url
              bio
              recipe_count
            }
          }
        `,
				variables: {
					limit,
					offset: currentOffset.value,
					where: searchQuery.value
						? {
								_or: [
									{ full_name: { _ilike: `%${searchQuery.value}%` } },
									{ username: { _ilike: `%${searchQuery.value}%` } },
								],
						  }
						: {},
					order_by: getOrderBy(),
				},
			},
		});

		if (data?.users) {
			if (reset) {
				chefs.value = data.users;
			} else {
				chefs.value.push(...data.users);
			}

			hasMore.value = data.users.length === limit;
			currentOffset.value += limit;
		}
	} catch (error) {
		console.error("Failed to load chefs:", error);
	} finally {
		loading.value = false;
		loadingMore.value = false;
	}
};

const getOrderBy = () => {
	switch (sortBy.value) {
		case "popular":
			return [{ recipe_count: "desc" }];
		case "newest":
			return [{ created_at: "desc" }];
		default:
			return [{ recipe_count: "desc" }];
	}
};

const loadMore = () => {
	loadChefs(false);
};

// Debounced search
const debouncedSearch = debounce(() => {
	loadChefs(true);
}, 500);

// Load chefs on mount
onMounted(() => {
	loadChefs();
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

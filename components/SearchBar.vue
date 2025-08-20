<template>
	<div class="relative">
		<div class="relative">
			<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
				<MagnifyingGlassIcon class="h-5 w-5 text-gray-400" />
			</div>
			<input
				v-model="searchQuery"
				@input="handleInput"
				@focus="showSuggestions = true"
				@blur="hideSuggestions"
				@keydown="handleKeydown"
				type="text"
				:placeholder="placeholder"
				class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
			/>
			<div v-if="loading" class="absolute inset-y-0 right-0 pr-3 flex items-center">
				<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-primary-600"></div>
			</div>
		</div>

		<!-- Search Suggestions -->
		<div
			v-if="showSuggestions && (suggestions.recipes.length > 0 || suggestions.ingredients.length > 0 || suggestions.categories.length > 0)"
			class="absolute z-50 w-full mt-1 bg-white rounded-md shadow-lg border border-gray-200 max-h-96 overflow-y-auto"
		>
			<!-- Recipe Suggestions -->
			<div v-if="suggestions.recipes.length > 0" class="p-2">
				<div class="text-xs font-medium text-gray-500 uppercase tracking-wide px-2 py-1">
					Recipes
				</div>
				<button
					v-for="recipe in suggestions.recipes"
					:key="recipe.id"
					@click="selectRecipe(recipe)"
					class="w-full flex items-center px-2 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md"
				>
					<img
						:src="recipe.featured_image_url || 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=50'"
						:alt="recipe.title"
						class="w-8 h-8 rounded object-cover mr-3"
					/>
					<span class="truncate">{{ recipe.title }}</span>
				</button>
			</div>

			<!-- Ingredient Suggestions -->
			<div v-if="suggestions.ingredients.length > 0" class="p-2 border-t border-gray-100">
				<div class="text-xs font-medium text-gray-500 uppercase tracking-wide px-2 py-1">
					Ingredients
				</div>
				<button
					v-for="ingredient in suggestions.ingredients"
					:key="ingredient"
					@click="selectIngredient(ingredient)"
					class="w-full text-left px-2 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md"
				>
					<span class="flex items-center">
						<span class="w-2 h-2 bg-green-400 rounded-full mr-3"></span>
						{{ ingredient }}
					</span>
				</button>
			</div>

			<!-- Category Suggestions -->
			<div v-if="suggestions.categories.length > 0" class="p-2 border-t border-gray-100">
				<div class="text-xs font-medium text-gray-500 uppercase tracking-wide px-2 py-1">
					Categories
				</div>
				<button
					v-for="category in suggestions.categories"
					:key="category.id"
					@click="selectCategory(category)"
					class="w-full text-left px-2 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md"
				>
					<span class="flex items-center">
						<span class="text-lg mr-3">🍽️</span>
						{{ category.name }}
					</span>
				</button>
			</div>

			<!-- Popular Searches -->
			<div v-if="popularSearches.length > 0 && !searchQuery" class="p-2 border-t border-gray-100">
				<div class="text-xs font-medium text-gray-500 uppercase tracking-wide px-2 py-1">
					Popular Searches
				</div>
				<button
					v-for="term in popularSearches"
					:key="term"
					@click="selectSearchTerm(term)"
					class="w-full text-left px-2 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md"
				>
					<span class="flex items-center">
						<TrendingUpIcon class="w-4 h-4 text-gray-400 mr-3" />
						{{ term }}
					</span>
				</button>
			</div>
		</div>
	</div>
</template>

<script setup>
import { MagnifyingGlassIcon, TrendingUpIcon } from "@heroicons/vue/24/outline";
import { useSearch } from "~/composables/useSearch";

const props = defineProps({
	placeholder: {
		type: String,
		default: "Search recipes, ingredients, or categories...",
	},
	modelValue: {
		type: String,
		default: "",
	},
});

const emit = defineEmits(["update:modelValue", "search", "select"]);

const { getSearchSuggestions, getPopularSearchTerms } = useSearch();

const searchQuery = ref(props.modelValue);
const loading = ref(false);
const showSuggestions = ref(false);
const selectedIndex = ref(-1);

const suggestions = ref({
	recipes: [],
	ingredients: [],
	categories: [],
});

const popularSearches = ref([]);

// Watch for prop changes
watch(() => props.modelValue, (newValue) => {
	searchQuery.value = newValue;
});

// Watch for search query changes
watch(searchQuery, (newValue) => {
	emit("update:modelValue", newValue);
});

let searchTimeout;

const handleInput = () => {
	clearTimeout(searchTimeout);
	searchTimeout = setTimeout(async () => {
		if (searchQuery.value.length >= 2) {
			loading.value = true;
			try {
				suggestions.value = await getSearchSuggestions(searchQuery.value);
			} catch (error) {
				console.error("Failed to get suggestions:", error);
			} finally {
				loading.value = false;
			}
		} else {
			suggestions.value = { recipes: [], ingredients: [], categories: [] };
		}
	}, 300);
};

const handleKeydown = (event) => {
	const totalSuggestions = suggestions.value.recipes.length + 
		suggestions.value.ingredients.length + 
		suggestions.value.categories.length;

	if (event.key === "ArrowDown") {
		event.preventDefault();
		selectedIndex.value = Math.min(selectedIndex.value + 1, totalSuggestions - 1);
	} else if (event.key === "ArrowUp") {
		event.preventDefault();
		selectedIndex.value = Math.max(selectedIndex.value - 1, -1);
	} else if (event.key === "Enter") {
		event.preventDefault();
		if (selectedIndex.value >= 0) {
			// Select the highlighted suggestion
			selectSuggestionByIndex(selectedIndex.value);
		} else {
			// Perform search
			performSearch();
		}
	} else if (event.key === "Escape") {
		showSuggestions.value = false;
		selectedIndex.value = -1;
	}
};

const selectSuggestionByIndex = (index) => {
	let currentIndex = 0;
	
	// Check recipes
	if (index < suggestions.value.recipes.length) {
		selectRecipe(suggestions.value.recipes[index]);
		return;
	}
	currentIndex += suggestions.value.recipes.length;
	
	// Check ingredients
	if (index < currentIndex + suggestions.value.ingredients.length) {
		selectIngredient(suggestions.value.ingredients[index - currentIndex]);
		return;
	}
	currentIndex += suggestions.value.ingredients.length;
	
	// Check categories
	if (index < currentIndex + suggestions.value.categories.length) {
		selectCategory(suggestions.value.categories[index - currentIndex]);
		return;
	}
};

const selectRecipe = (recipe) => {
	emit("select", { type: "recipe", data: recipe });
	navigateTo(`/recipes/${recipe.id}`);
	hideSuggestions();
};

const selectIngredient = (ingredient) => {
	searchQuery.value = ingredient;
	emit("select", { type: "ingredient", data: ingredient });
	performSearch();
	hideSuggestions();
};

const selectCategory = (category) => {
	emit("select", { type: "category", data: category });
	navigateTo(`/categories/${category.slug}`);
	hideSuggestions();
};

const selectSearchTerm = (term) => {
	searchQuery.value = term;
	performSearch();
	hideSuggestions();
};

const performSearch = () => {
	if (searchQuery.value.trim()) {
		emit("search", searchQuery.value.trim());
		navigateTo(`/recipes?search=${encodeURIComponent(searchQuery.value.trim())}`);
	}
	hideSuggestions();
};

const hideSuggestions = () => {
	setTimeout(() => {
		showSuggestions.value = false;
		selectedIndex.value = -1;
	}, 200);
};

// Load popular searches on mount
onMounted(async () => {
	try {
		popularSearches.value = await getPopularSearchTerms();
	} catch (error) {
		console.error("Failed to load popular searches:", error);
	}
});
</script>
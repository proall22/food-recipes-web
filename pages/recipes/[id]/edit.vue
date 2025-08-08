<template>
	<div class="py-8">
		<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="mb-8">
				<nav class="flex mb-4" aria-label="Breadcrumb">
					<ol class="flex items-center space-x-4">
						<li>
							<NuxtLink to="/" class="text-gray-500 hover:text-gray-700"
								>Home</NuxtLink
							>
						</li>
						<li>
							<ChevronRightIcon class="w-4 h-4 text-gray-400" />
						</li>
						<li>
							<NuxtLink to="/recipes" class="text-gray-500 hover:text-gray-700"
								>Recipes</NuxtLink
							>
						</li>
						<li>
							<ChevronRightIcon class="w-4 h-4 text-gray-400" />
						</li>
						<li>
							<NuxtLink
								:to="`/recipes/${recipeId}`"
								class="text-gray-500 hover:text-gray-700"
								>{{ recipe?.title }}</NuxtLink
							>
						</li>
						<li>
							<ChevronRightIcon class="w-4 h-4 text-gray-400" />
						</li>
						<li class="text-gray-900 font-medium">Edit</li>
					</ol>
				</nav>

				<h1
					class="text-3xl md:text-4xl font-bold font-serif text-gray-900 mb-4"
				>
					Edit Recipe
				</h1>
				<p class="text-xl text-gray-600">Update your recipe details</p>
			</div>

			<div v-if="loading" class="animate-pulse">
				<div class="h-8 bg-gray-300 rounded mb-4"></div>
				<div class="h-32 bg-gray-300 rounded mb-4"></div>
				<div class="h-64 bg-gray-300 rounded"></div>
			</div>

			<form v-else-if="recipe" @submit.prevent="handleSubmit" class="space-y-8">
				<!-- Basic Information -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-6">
						Basic Information
					</h2>

					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div class="md:col-span-2">
							<label
								for="title"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Recipe Title</label
							>
							<input
								id="title"
								v-model="recipe.title"
								type="text"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Enter recipe title"
							/>
						</div>

						<div class="md:col-span-2">
							<label
								for="description"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Description</label
							>
							<textarea
								id="description"
								v-model="recipe.description"
								rows="3"
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="Briefly describe your recipe"
							></textarea>
						</div>

						<div>
							<label
								for="category"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Category</label
							>
							<select
								id="category"
								v-model="recipe.category_id"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							>
								<option value="">Select Category</option>
								<option
									v-for="category in categories"
									:key="category.id"
									:value="category.id"
								>
									{{ category.name }}
								</option>
							</select>
						</div>

						<div>
							<label
								for="difficulty"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Difficulty</label
							>
							<select
								id="difficulty"
								v-model="recipe.difficulty"
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							>
								<option value="Easy">Easy</option>
								<option value="Medium">Medium</option>
								<option value="Hard">Hard</option>
							</select>
						</div>

						<div>
							<label
								for="prepTime"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Prep Time (minutes)</label
							>
							<input
								id="prepTime"
								v-model.number="recipe.prep_time"
								type="number"
								min="1"
								required
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="30"
							/>
						</div>

						<div>
							<label
								for="cookTime"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Cook Time (minutes)</label
							>
							<input
								id="cookTime"
								v-model.number="recipe.cook_time"
								type="number"
								min="0"
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="45"
							/>
						</div>

						<div>
							<label
								for="servings"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Servings</label
							>
							<input
								id="servings"
								v-model.number="recipe.servings"
								type="number"
								min="1"
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="4"
							/>
						</div>

						<div>
							<label class="flex items-center">
								<input
									v-model="recipe.is_premium"
									type="checkbox"
									class="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50"
								/>
								<span class="ml-2 text-sm text-gray-700">Premium Recipe</span>
							</label>
						</div>

						<div v-if="recipe.is_premium">
							<label
								for="price"
								class="block text-sm font-medium text-gray-700 mb-2"
								>Price ($)</label
							>
							<input
								id="price"
								v-model.number="recipe.price"
								type="number"
								min="0"
								step="0.01"
								class="w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
								placeholder="9.99"
							/>
						</div>
					</div>
				</div>

				<!-- Images -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-6">
						Recipe Images
					</h2>

					<div
						class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center"
					>
						<input
							ref="fileInput"
							type="file"
							multiple
							accept="image/*"
							@change="handleFileUpload"
							class="hidden"
						/>
						<CloudArrowUpIcon class="mx-auto h-12 w-12 text-gray-400" />
						<p class="mt-2 text-sm text-gray-600">
							<button
								type="button"
								@click="$refs.fileInput.click()"
								class="font-medium text-primary-600 hover:text-primary-500"
							>
								Upload images
							</button>
							or drag and drop
						</p>
						<p class="text-xs text-gray-500">PNG, JPG, GIF up to 10MB each</p>
					</div>

					<!-- Current Images -->
					<div
						v-if="recipe.images && recipe.images.length > 0"
						class="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4"
					>
						<div
							v-for="(image, index) in recipe.images"
							:key="image.id || index"
							class="relative"
						>
							<img
								:src="image.image_url"
								:alt="`Recipe image ${index + 1}`"
								class="w-full h-24 object-cover rounded-lg"
							/>
							<button
								type="button"
								@click="removeImage(index)"
								class="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600"
							>
								×
							</button>
							<button
								type="button"
								@click="setFeaturedImage(index)"
								:class="
									image.is_featured
										? 'bg-primary-600 text-white'
										: 'bg-gray-200 text-gray-700'
								"
								class="absolute bottom-1 left-1 px-2 py-1 text-xs rounded"
							>
								{{ image.is_featured ? "Featured" : "Set Featured" }}
							</button>
						</div>
					</div>
				</div>

				<!-- Ingredients -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex justify-between items-center mb-6">
						<h2 class="text-xl font-semibold text-gray-900">Ingredients</h2>
						<button type="button" @click="addIngredient" class="btn-secondary">
							<PlusIcon class="w-4 h-4 mr-2" />
							Add Ingredient
						</button>
					</div>

					<div class="space-y-4">
						<div
							v-for="(ingredient, index) in recipe.ingredients"
							:key="ingredient.id || index"
							class="flex gap-4"
						>
							<input
								v-model="ingredient.amount"
								type="text"
								placeholder="Amount"
								required
								class="w-24 border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
							<input
								v-model="ingredient.unit"
								type="text"
								placeholder="Unit"
								class="w-24 border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
							<input
								v-model="ingredient.name"
								type="text"
								placeholder="Ingredient name"
								required
								class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
							<input
								v-model="ingredient.notes"
								type="text"
								placeholder="Notes (optional)"
								class="w-32 border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							/>
							<button
								type="button"
								@click="removeIngredient(index)"
								class="text-red-500 hover:text-red-700"
							>
								<TrashIcon class="w-5 h-5" />
							</button>
						</div>
					</div>
				</div>

				<!-- Instructions -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
					<div class="flex justify-between items-center mb-6">
						<h2 class="text-xl font-semibold text-gray-900">Instructions</h2>
						<button type="button" @click="addStep" class="btn-secondary">
							<PlusIcon class="w-4 h-4 mr-2" />
							Add Step
						</button>
					</div>

					<div class="space-y-4">
						<div
							v-for="(step, index) in recipe.steps"
							:key="step.id || index"
							class="flex gap-4"
						>
							<div
								class="flex-shrink-0 w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium"
							>
								{{ index + 1 }}
							</div>
							<textarea
								v-model="step.instruction"
								rows="2"
								placeholder="Describe this step..."
								required
								class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500"
							></textarea>
							<button
								type="button"
								@click="removeStep(index)"
								class="text-red-500 hover:text-red-700"
							>
								<TrashIcon class="w-5 h-5" />
							</button>
						</div>
					</div>
				</div>

				<!-- Submit -->
				<div class="flex justify-end space-x-4">
					<NuxtLink :to="`/recipes/${recipeId}`" class="btn-secondary">
						Cancel
					</NuxtLink>
					<button type="submit" class="btn-primary" :disabled="submitting">
						{{ submitting ? "Updating..." : "Update Recipe" }}
					</button>
				</div>
			</form>
		</div>
	</div>
</template>

<script setup>
import {
	ChevronRightIcon,
	CloudArrowUpIcon,
	PlusIcon,
	TrashIcon,
} from "@heroicons/vue/24/outline";

// Protect this route - only authenticated users can access
definePageMeta({
	middleware: "auth",
});

const route = useRoute();
const router = useRouter();
const recipeId = route.params.id;

const { user } = useAuth();
const { useFileUpload } = useFileUpload();

const recipe = ref(null);
const categories = ref([]);
const loading = ref(true);
const submitting = ref(false);

// Load recipe data
onMounted(async () => {
	try {
		// TODO: Replace with actual GraphQL query
		await new Promise((resolve) => setTimeout(resolve, 1000));

		// Simulate loading recipe data
		recipe.value = {
			id: recipeId,
			title: "Classic Spaghetti Carbonara",
			description:
				"A traditional Italian pasta dish with eggs, cheese, and pancetta",
			prep_time: 15,
			cook_time: 20,
			servings: 4,
			difficulty: "Medium",
			category_id: "3",
			is_premium: false,
			price: 0,
			ingredients: [
				{ id: "1", amount: "400g", unit: "", name: "spaghetti", notes: "" },
				{
					id: "2",
					amount: "200g",
					unit: "",
					name: "pancetta or guanciale",
					notes: "diced",
				},
			],
			steps: [
				{
					id: "1",
					step_number: 1,
					instruction:
						"Bring a large pot of salted water to boil. Cook spaghetti according to package directions until al dente.",
				},
				{
					id: "2",
					step_number: 2,
					instruction:
						"While pasta cooks, heat a large skillet over medium heat. Add pancetta and cook until crispy, about 5-7 minutes.",
				},
			],
			images: [
				{
					id: "1",
					image_url:
						"https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400",
					is_featured: true,
				},
			],
		};

		// Load categories
		categories.value = [
			{ id: "1", name: "Breakfast" },
			{ id: "2", name: "Lunch" },
			{ id: "3", name: "Dinner" },
			{ id: "4", name: "Desserts" },
		];
	} catch (error) {
		console.error("Failed to load recipe:", error);
	} finally {
		loading.value = false;
	}
});

const addIngredient = () => {
	recipe.value.ingredients.push({ amount: "", unit: "", name: "", notes: "" });
};

const removeIngredient = (index) => {
	if (recipe.value.ingredients.length > 1) {
		recipe.value.ingredients.splice(index, 1);
	}
};

const addStep = () => {
	recipe.value.steps.push({
		instruction: "",
		step_number: recipe.value.steps.length + 1,
	});
};

const removeStep = (index) => {
	if (recipe.value.steps.length > 1) {
		recipe.value.steps.splice(index, 1);
		// Renumber steps
		recipe.value.steps.forEach((step, i) => {
			step.step_number = i + 1;
		});
	}
};

const handleFileUpload = async (event) => {
	const files = Array.from(event.target.files);

	for (const file of files) {
		try {
			// TODO: Implement file upload
			const result = {
				url: URL.createObjectURL(file),
				key: `temp-${Date.now()}`,
			};

			recipe.value.images = recipe.value.images || [];
			recipe.value.images.push({
				image_url: result.url,
				key: result.key,
				is_featured: recipe.value.images.length === 0,
			});
		} catch (error) {
			console.error("Upload failed:", error);
		}
	}
};

const removeImage = (index) => {
	recipe.value.images.splice(index, 1);
	// If removed image was featured, make first image featured
	if (
		recipe.value.images.length > 0 &&
		!recipe.value.images.some((img) => img.is_featured)
	) {
		recipe.value.images[0].is_featured = true;
	}
};

const setFeaturedImage = (index) => {
	recipe.value.images.forEach((img, i) => {
		img.is_featured = i === index;
	});
};

const handleSubmit = async () => {
	submitting.value = true;
	try {
		// TODO: Implement recipe update
		console.log("Updating recipe:", recipe.value);
		await new Promise((resolve) => setTimeout(resolve, 1000));
		await router.push(`/recipes/${recipeId}`);
	} catch (error) {
		console.error("Failed to update recipe:", error);
	} finally {
		submitting.value = false;
	}
};

// Meta tags
useHead({
	title: `Edit Recipe - RecipeHub`,
	meta: [{ name: "description", content: "Edit your recipe details" }],
});
</script>

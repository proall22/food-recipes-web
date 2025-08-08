<template>
	<div class="min-h-screen bg-gray-50">
		<!-- Navigation -->
		<nav class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="flex justify-between h-16">
					<div class="flex items-center">
						<NuxtLink to="/" class="flex items-center space-x-2">
							<div
								class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center"
							>
								<svg
									class="w-5 h-5 text-white"
									fill="none"
									stroke="currentColor"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
									></path>
								</svg>
							</div>
							<span class="text-xl font-bold font-serif text-gray-900"
								>RecipeHub</span
							>
						</NuxtLink>

						<!-- Desktop Navigation -->
						<div class="hidden md:ml-10 md:flex md:space-x-8">
							<NuxtLink
								to="/"
								class="text-gray-700 hover:text-primary-600 px-3 py-2 text-sm font-medium transition-colors"
							>
								Home
							</NuxtLink>
							<NuxtLink
								to="/recipes"
								class="text-gray-700 hover:text-primary-600 px-3 py-2 text-sm font-medium transition-colors"
							>
								Recipes
							</NuxtLink>
							<NuxtLink
								to="/categories"
								class="text-gray-700 hover:text-primary-600 px-3 py-2 text-sm font-medium transition-colors"
							>
								Categories
							</NuxtLink>
							<NuxtLink
								to="/chefs"
								class="text-gray-700 hover:text-primary-600 px-3 py-2 text-sm font-medium transition-colors"
							>
								Chefs
							</NuxtLink>
						</div>
					</div>

					<!-- Search Bar -->
					<div class="flex-1 max-w-lg mx-8 hidden lg:block">
						<div class="relative">
							<div
								class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
							>
								<MagnifyingGlassIcon class="h-5 w-5 text-gray-400" />
							</div>
							<input
								type="text"
								placeholder="Search recipes..."
								class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
							/>
						</div>
					</div>

					<!-- User Actions -->
					<div class="flex items-center space-x-4">
						<button
							v-if="!isAuthenticated"
							@click="showAuthModal = true"
							class="btn-secondary"
						>
							Sign In
						</button>
						<button
							v-if="!isAuthenticated"
							@click="showAuthModal = true"
							class="btn-primary"
						>
							Sign Up
						</button>

						<!-- Authenticated User Menu -->
						<div v-if="isAuthenticated" class="flex items-center space-x-3">
							<NuxtLink to="/create-recipe" class="btn-primary">
								<PlusIcon class="w-4 h-4 mr-2" />
								Create Recipe
							</NuxtLink>
							<div class="relative">
								<button
									@click="showUserMenu = !showUserMenu"
									class="flex items-center space-x-2 text-gray-700 hover:text-primary-600"
								>
									<div class="w-8 h-8 bg-gray-300 rounded-full"></div>
									<ChevronDownIcon class="w-4 h-4" />
								</button>
								<!-- User dropdown menu -->
								<div
									v-if="showUserMenu"
									class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50"
								>
									<NuxtLink
										to="/profile"
										class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>
										Profile
									</NuxtLink>
									<NuxtLink
										to="/my-recipes"
										class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>
										My Recipes
									</NuxtLink>
									<NuxtLink
										to="/bookmarks"
										class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>
										Bookmarks
									</NuxtLink>
									<button
										@click="handleLogout"
										class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
									>
										Sign Out
									</button>
								</div>
							</div>
						</div>

						<!-- Mobile menu button -->
						<button @click="showMobileMenu = !showMobileMenu" class="md:hidden">
							<Bars3Icon class="w-6 h-6 text-gray-700" />
						</button>
					</div>
				</div>
			</div>

			<!-- Mobile Menu -->
			<div v-if="showMobileMenu" class="md:hidden">
				<div
					class="px-2 pt-2 pb-3 space-y-1 sm:px-3 bg-white border-t border-gray-200"
				>
					<NuxtLink
						to="/"
						class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-primary-600"
					>
						Home
					</NuxtLink>
					<NuxtLink
						to="/recipes"
						class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-primary-600"
					>
						Recipes
					</NuxtLink>
					<NuxtLink
						to="/categories"
						class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-primary-600"
					>
						Categories
					</NuxtLink>
					<NuxtLink
						to="/chefs"
						class="block px-3 py-2 text-base font-medium text-gray-700 hover:text-primary-600"
					>
						Chefs
					</NuxtLink>
				</div>
			</div>
		</nav>

		<!-- Main Content -->
		<main>
			<slot />
		</main>

		<!-- Footer -->
		<footer class="bg-gray-900 text-white mt-20">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
				<div class="grid grid-cols-1 md:grid-cols-4 gap-8">
					<div class="col-span-1 md:col-span-2">
						<div class="flex items-center space-x-2 mb-4">
							<div
								class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center"
							>
								<svg
									class="w-5 h-5 text-white"
									fill="none"
									stroke="currentColor"
									viewBox="0 0 24 24"
								>
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
									></path>
								</svg>
							</div>
							<span class="text-xl font-bold font-serif">RecipeHub</span>
						</div>
						<p class="text-gray-400 mb-4">
							Discover, share, and create amazing recipes with our community of
							food lovers.
						</p>
						<div class="flex space-x-4">
							<!-- Social icons would go here -->
						</div>
					</div>

					<div>
						<h3 class="text-sm font-semibold uppercase tracking-wider mb-4">
							Explore
						</h3>
						<ul class="space-y-2">
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Popular Recipes</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>New Recipes</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Categories</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Top Chefs</a
								>
							</li>
						</ul>
					</div>

					<div>
						<h3 class="text-sm font-semibold uppercase tracking-wider mb-4">
							Support
						</h3>
						<ul class="space-y-2">
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Help Center</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Contact Us</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Privacy Policy</a
								>
							</li>
							<li>
								<a
									href="#"
									class="text-gray-400 hover:text-white transition-colors"
									>Terms of Service</a
								>
							</li>
						</ul>
					</div>
				</div>

				<div class="border-t border-gray-800 mt-12 pt-8">
					<p class="text-center text-gray-400">
						© 2025 RecipeHub. All rights reserved.
					</p>
				</div>
			</div>
		</footer>

		<!-- Auth Modal -->
		<AuthModal v-if="showAuthModal" @close="showAuthModal = false" />
	</div>
</template>

<script setup>
import {
	MagnifyingGlassIcon,
	PlusIcon,
	ChevronDownIcon,
	Bars3Icon,
} from "@heroicons/vue/24/outline";

// Initialize auth composable with error handling
let authComposable;
try {
	authComposable = useAuth();
} catch (error) {
	console.warn("Auth composable not available:", error);
	authComposable = {
		isAuthenticated: ref(false),
		user: ref(null),
		logout: () => {},
	};
}

const { isAuthenticated, user, logout } = authComposable;

const showMobileMenu = ref(false);
const showUserMenu = ref(false);
const showAuthModal = ref(false);

const handleLogout = () => {
	logout();
	showUserMenu.value = false;
};
</script>
